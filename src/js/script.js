import { Directory, Filesystem } from '@capacitor/filesystem';
import { FileOpener } from '@capawesome-team/capacitor-file-opener';
import { ShareTarget } from '@capawesome-team/capacitor-share-target';
import { FilePicker } from '@capawesome/capacitor-file-picker';

async function copyAndOpenFile(path) {
  const { uri: targetUri } = await Filesystem.getUri({
    directory: Directory.Cache,
    path: Date.now() + '.' + path.split('.').pop(), // Use the original file extension
  });
  await FilePicker.copyFile({
    from: path,
    to: targetUri,
  });
  await FileOpener.openFile({ path: targetUri });
}

async function openFile(path) {
  if (path.startsWith('data:')) {
    // Handle data URLs for web platform
    const link = document.createElement('a');
    link.href = path;
    link.download = 'shared-file';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } else {
    await FileOpener.openFile({ path });
  }
}

window.openFile = openFile;

document.addEventListener('DOMContentLoaded', () => {
  // Register service worker for web platform
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker
      .register('./sw.js')
      .then(() => {
        console.log('Service Worker registered successfully');
      })
      .catch(error => {
        console.error('Service Worker registration failed:', error);
      });
  }

  // Event listeners
  ShareTarget.addListener('shareReceived', event => {
    // if (event.files && event.files.length > 0) {
    //   var firstFile = event.files[0];
    //   copyAndOpenFile(firstFile);
    // }
    console.log('Share received', { event });
    document.querySelector('#title').value = event.title || '';
    document.querySelector('#text').value = event.texts
      ? event.texts.join(', ')
      : '';
    if (event.files && event.files.length > 0) {
      const filesContainer = document.querySelector('#files-container');
      filesContainer.innerHTML = ''; // Clear previous files
      event.files.forEach(file => {
        const fileSrc = file.startsWith('http')
          ? file
          : Capacitor.convertFileSrc(file);
        const fileItem = document.createElement('ion-item');
        fileItem.innerHTML = `
          <ion-item>
            <ion-input type="text" value="${file}" readonly>
                <ion-img src="${fileSrc}" alt="Preview" />
            </ion-input>
          </ion-item>
        `;
        filesContainer.appendChild(fileItem);
      });
    } else {
      document.querySelector('#files-container').innerHTML = '';
    }
  });
});
