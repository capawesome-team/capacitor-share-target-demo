import MobileCoreServices
import Social
import UIKit
import UniformTypeIdentifiers

struct SharedFileData {
    let uri: String
    let name: String?
    let mimeType: String?
}

class ShareViewController: UIViewController {

    private let appGroupIdentifier = "group.dev.robingenz.example.plugin"
    private let urlScheme = "pluginexample"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            processSharedContent()
        }
    }

    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
    }

    private func copyFileToSharedContainer(_ url: URL) -> String? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return nil
        }

        let fileName = url.lastPathComponent
        let destinationURL = containerURL.appendingPathComponent(fileName)

        do {
            // Remove file if it already exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Copy file to shared container
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return destinationURL.absoluteString
        } catch {
            print("Error copying file to shared container: \(error)")
            return nil
        }
    }

    public func getMimeTypeFromUrl(_ url: URL) -> String {
        let fileExtension = url.pathExtension as CFString
        guard let extUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)?.takeUnretainedValue() else {
            return ""
        }
        guard let mimeUTI = UTTypeCopyPreferredTagWithClass(extUTI, kUTTagClassMIMEType) else {
            return ""
        }
        return mimeUTI.takeRetainedValue() as String
    }

    public func getNameFromUrl(_ url: URL) -> String {
        return url.lastPathComponent
    }

    private func sendData(with textValues: [String], fileValues: [SharedFileData], title: String) {
        var urlComps = URLComponents(string: "\(urlScheme)://?")!
        var queryItems: [URLQueryItem] = []

        if !title.isEmpty {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }

        for text in textValues {
            if !text.isEmpty {
                queryItems.append(URLQueryItem(name: "text", value: text))
            }
        }

        for (index, file) in fileValues.enumerated() {
            queryItems.append(URLQueryItem(name: "fileUri\(index)", value: file.uri))
            if let name = file.name {
                queryItems.append(URLQueryItem(name: "fileName\(index)", value: name))
            }
            if let mimeType = file.mimeType {
                queryItems.append(URLQueryItem(name: "fileMimeType\(index)", value: mimeType))
            }
        }

        urlComps.queryItems = queryItems.isEmpty ? nil : queryItems
        openURL(urlComps.url!)
    }

    private func processSharedContent() {
        guard let extensionContext = extensionContext else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        guard let item = extensionContext.inputItems.first as? NSExtensionItem else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        guard let attachments = item.attachments else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        var textValues: [String] = []
        var fileValues: [SharedFileData] = []
        let title = item.attributedTitle?.string ?? item.attributedContentText?.string ?? ""
        let dispatchGroup = DispatchGroup()

        for attachment in attachments {
            // Handle images
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                dispatchGroup.enter()
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, _) in
                    defer { dispatchGroup.leave() }

                    if let url = item as? URL {
                        if let sharedPath = self?.copyFileToSharedContainer(url) {
                            let fileName = self?.getNameFromUrl(url)
                            let mimeType = self?.getMimeTypeFromUrl(url)
                            let finalMimeType = mimeType?.isEmpty == false ? mimeType : nil
                            fileValues.append(SharedFileData(uri: sharedPath, name: fileName, mimeType: finalMimeType))
                        }
                    } else if let image = item as? UIImage {
                        if let data = image.pngData() {
                            let base64String = data.base64EncodedString()
                            fileValues.append(SharedFileData(uri: "data:image/png;base64,\(base64String)", name: nil, mimeType: "image/png"))
                        }
                    }
                }
            }
            // Handle movies
            if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                dispatchGroup.enter()
                attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { [weak self] (item, _) in
                    defer { dispatchGroup.leave() }

                    if let url = item as? URL {
                        if let sharedPath = self?.copyFileToSharedContainer(url) {
                            let fileName = self?.getNameFromUrl(url)
                            let mimeType = self?.getMimeTypeFromUrl(url)
                            let finalMimeType = mimeType?.isEmpty == false ? mimeType : nil
                            fileValues.append(SharedFileData(uri: sharedPath, name: fileName, mimeType: finalMimeType))
                        }
                    }
                }
            }
            // Handle plain text content
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                dispatchGroup.enter()
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, _) in
                    if let text = item as? String {
                        textValues.append(text)
                    }
                    dispatchGroup.leave()
                }
            }
            // Handle URL content
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                dispatchGroup.enter()
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, _) in
                    if let url = item as? URL {
                        textValues.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.sendData(with: textValues, fileValues: fileValues, title: title)
        }
    }
}
