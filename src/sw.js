self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  if (event.request.method === 'POST' && url.pathname === '/_share-target') {
    event.respondWith(handleShareTarget(event.request));
  } else if (url.pathname.startsWith('/_share-file/')) {
    event.respondWith(handleFileRequest(event.request));
  }
});

async function handleFileRequest(request) {
  try {
    const url = new URL(request.url);
    const fileId = url.pathname.substring(13); // Remove '/_share-file/' prefix
    const cache = await caches.open('share-target-files');
    const cacheKey = `/${fileId}`;

    const response = await cache.match(cacheKey);
    if (response) {
      return response;
    } else {
      return new Response('File not found', { status: 404 });
    }
  } catch (error) {
    console.error('Error serving file:', error);
    return new Response('Internal error', { status: 500 });
  }
}

async function handleShareTarget(request) {
  try {
    const formData = await request.formData();
    const title = formData.get('title') || '';
    const text = formData.get('text') || '';
    const url = formData.get('url') || '';
    const files = formData.getAll('files');

    const texts = [];
    if (text) texts.push(text);
    if (url) texts.push(url);

    const shareData = {
      title: title,
      texts: texts.length > 0 ? texts : undefined,
      files: undefined,
    };

    if (files.length > 0) {
      const sharedFiles = [];
      const cache = await caches.open('share-target-files');

      for (const file of files) {
        if (file instanceof File && file.size > 0) {
          const fileId = `share-file-${Date.now()}-${Math.random().toString(36).substring(2, 11)}`;
          const cacheKey = `/${fileId}`;

          const response = new Response(file, {
            headers: {
              'Content-Type': file.type,
              'Content-Length': file.size.toString(),
              'X-File-Name': file.name || 'unknown',
            },
          });
          await cache.put(cacheKey, response);

          sharedFiles.push({
            uri: `/_share-file/${fileId}`,
            name: file.name || undefined,
            mimeType: file.type || undefined,
          });
        }
      }

      if (sharedFiles.length > 0) {
        shareData.files = sharedFiles;
      }
    }

    const redirectUrl = new URL('/', self.location.origin);

    if (shareData.title) {
      redirectUrl.searchParams.set('title', shareData.title);
    }

    if (shareData.texts && shareData.texts.length > 0) {
      shareData.texts.forEach((text, index) => {
        redirectUrl.searchParams.set(`text${index}`, text);
      });
    }

    if (shareData.files && shareData.files.length > 0) {
      shareData.files.forEach((file, index) => {
        redirectUrl.searchParams.set(`fileUri${index}`, file.uri);
        if (file.name) {
          redirectUrl.searchParams.set(`fileName${index}`, file.name);
        }
        if (file.mimeType) {
          redirectUrl.searchParams.set(`fileMimeType${index}`, file.mimeType);
        }
      });
    }

    return Response.redirect(redirectUrl.href, 303);
  } catch (error) {
    console.error('Error handling share target:', error);
    return Response.redirect('/', 303);
  }
}
