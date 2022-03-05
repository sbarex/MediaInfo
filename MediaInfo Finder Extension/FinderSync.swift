//
//  FinderSync.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
// import Sparkle
import FinderSync

class FinderSync: FIFinderSync {/*
    var userDriver: SPUStandardUserDriver?
    var updater: SPUUpdater?*/
    
    var settings: Settings = Settings(fromDict: [:])
    
    override init() {
        super.init()
        
        NSLog("MediaInfo FinderSync launched from %@", Bundle.main.bundlePath as NSString)
        
        refreshSettings()
        
        // Set up images for our badge identifiers. For demonstration purposes, this uses off-the-shelf images.
        // FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.colorPanelName)!, label: "Status One" , forBadgeIdentifier: "One")
        // FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.cautionName)!, label: "Status Two", forBadgeIdentifier: "Two")
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.handleSettingsChanged(_:)), name: .MediaInfoSettingsChanged, object: nil)
        
        // Monitor the mounted volumes.
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(self, selector: #selector(self.handleMount(_:)), name: NSWorkspace.didMountNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.handleUnmount(_:)), name: NSWorkspace.didMountNotification, object: nil)
        
        /*
        let hostBundle = Bundle.main
        let url = hostBundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        let applicationBundle = Bundle(url: url)
        self.userDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: nil)
        self.updater = SPUUpdater(hostBundle: hostBundle, applicationBundle: applicationBundle, userDriver: self.userDriver!, delegate: nil)
        do {
            try self.updater!.start()
        } catch {
            print("Failed to start updater with error: \(error)")
        }*/
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self, name: .MediaInfoSettingsChanged, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didMountNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didUnmountNotification, object: nil)
    }
    
    @objc func handleMount(_ notification: NSNotification) {
        guard self.settings.handleExternalDisk, let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL else {
            return
        }
        let finderSync = FIFinderSyncController.default()
        finderSync.directoryURLs.insert(volumeURL)
    }
    
    @objc func handleUnmount(_ notification: NSNotification) {
        guard self.settings.handleExternalDisk else {
            return
        }
        let finderSync = FIFinderSyncController.default()
        if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL, finderSync.directoryURLs.contains(volumeURL) {
            finderSync.directoryURLs.remove(volumeURL)
        }
    }
    
    func convertNetworkSharedUrl(_ url: URL) -> URL? {
        var mountPath: URL?
        var testUrl = url.standardizedFileURL
        var path: String = ""
        let isDir = testUrl.hasDirectoryPath
        while testUrl.path != "/" {
            var v: AnyObject?
            do {
                try (testUrl as NSURL).getResourceValue(&v, forKey: URLResourceKey.volumeURLForRemountingKey)
                if let volumePath = v as? NSURL {
                    mountPath = volumePath as URL
                    break
                }
            } catch {
                return nil
            }
            path = testUrl.lastPathComponent + ((isDir || !path.isEmpty) ? "/" + path : "")
            testUrl.deleteLastPathComponent()
        }

        guard var mountPath = mountPath else {
            return nil;
        }

        if !path.isEmpty {
            mountPath.appendPathComponent(path, isDirectory: isDir)
        }
        return mountPath
    }
    
    func refreshSettings() {
        HelperWrapper.getSettings() { settings in
            self.settings = settings
            
            // Set up the directory we are syncing.
            
            // let folders = Set(settings.folders.map({ self.convertNetworkSharedUrl($0) ?? $0 }))
            var folders = Set(settings.folders)
            NSLog("MediaInfo FinderSync watching folders:\n %@", folders.map({ $0.path }).joined(separator: "\n"))
            
            if settings.handleExternalDisk {
                let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
                if let paths = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) {
                    for url in paths {
                        let components = url.pathComponents
                        if components.count > 1 && components[1] == "Volumes" {
                            folders.insert(url)
                        }
                    }
                }
            }
            
            FIFinderSyncController.default().directoryURLs = folders
            /*
            for folder in folders {
                // Force the request of read access.
                if let dir = opendir(folder.path) {
                    closedir(dir)
                } else {
                    NSLog("No access to %@", folder.path)
                }
            }
            */
        }
    }
    
    @objc func handleSettingsChanged(_ notification: Notification) {
        refreshSettings()
    }
    
    // MARK: - Primary Finder Sync protocol methods
    
    override func beginObservingDirectory(at url: URL) {
        // The user is now seeing the container's contents.
        // If they see it in more than one view at a time, we're only told once.
        // NSLog("beginObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    
    override func endObservingDirectory(at url: URL) {
        // The user is no longer seeing the container's contents.
        // NSLog("endObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    /*
    override func requestBadgeIdentifier(for url: URL) {
        NSLog("requestBadgeIdentifierForURL: %@", url.path as NSString)
        
        // For demonstration purposes, this picks one of our two badges, or no badge at all, based on the filename.
        let whichBadge = abs(url.path.hash) % 3
        let badgeIdentifier = ["", "One", "Two"][whichBadge]
        FIFinderSyncController.default().setBadgeIdentifier(badgeIdentifier, for: url)
    }
    */
    
    // MARK: - Menu and toolbar item support
    
    var currentFile: URL?
    var currentFileType: Settings.SupportedFile?
    var currentInfo: BaseInfo? {
        didSet {
            oldValue?.jsDelegate = nil
            currentInfo?.jsDelegate = self
        }
    }
    
    @objc internal func fakeMenuAction(_ sender: NSMenuItem) {
        guard let file = self.currentFile, let currentFileType = self.currentFileType else {
            return
        }
        
        let item = BaseInfo.postprocessMenuItem(sender, from: self.representedObjects) as? MenuItemInfo
        if let item = item {
            switch item.action {
            case .none:
                // No action
                return
            case .standard:
                // Standard action
                break
            case .openSettings:
                var url = Bundle.main.bundleURL
                if url.pathExtension == "appex" {
                    url = url.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                }
                
                HelperWrapper.openApplication(at: url) { _,_ in }
                return
            case .about:
                HelperWrapper.openFile(url: URL(string: "https://github.com/sbarex/MediaInfo")!) {_ in }
                return
            case .open:
                HelperWrapper.openFile(url: file) {_ in }
                return
            case .openWith:
                if let path = item.userInfo["application"] as? String, !path.isEmpty {
                    HelperWrapper.openFile(url: file, withApp: path) {_,_ in }
                    return
                }
            case .custom:
                if let info = currentInfo, let code = item.userInfo["code"] as? String, !code.isEmpty {
                    info.initAction(context: info.getJSContext(with: self.settings), selectedItem: item, settings: self.settings)
                    _ = try? info.evaluateScript(code: "globalThis['\(code)'](selectedMenuItem);", forItem: item, settings: self.settings)
                    return
                }
            case .clipboard:
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                        
                pasteboard.setString(file.path, forType: NSPasteboard.PasteboardType.string)
                return
            }
        }
        
        switch settings.menuAction {
        case .none:
            return
        case .open:
            HelperWrapper.openFile(url: file) {_ in }
        case .script:
            guard let info = currentInfo, let code = settings.getActionCode(for: currentFileType) else {
                return
            }
            info.initAction(context: info.getJSContext(with: self.settings), selectedItem: item, settings: self.settings)
            _ = try? info.evaluateScript(code: code, forItem: nil, settings: self.settings)
        }
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems else {
            return nil
        }
        guard let items = FIFinderSyncController.default().selectedItemURLs(), items.count == 1, let item = items.first, let uti = try? item.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            currentFile = nil
            currentFileType = nil
            return nil
        }
            
        // Specific menu item properties are used: title, action, image, and enabled. Starting in 10.11: tag, state, and indentationLevel also work, and submenus are allowed.
        
        currentFile = item
        if settings.isPDFHandled && (UTTypeConformsTo(uti as CFString, kUTTypePDF) || UTTypeConformsTo(uti as CFString, "com.adobe.illustrator.ai-image" as CFString)) {
            currentFileType = .pdf
            self.currentInfo = getInfoForPDF(atURL: item)
        } else if settings.isImagesHandled && UTTypeConformsTo(uti as CFString, kUTTypeImage) {
            currentFileType = .image
            currentInfo = getInfoForImage(atURL: item)
        } else if settings.isVideoHandled && UTTypeConformsTo(uti as CFString, kUTTypeMovie) {
            currentFileType = .video
            currentInfo = getInfoForVideo(atURL: item)
        } else if settings.isAudioHandled && UTTypeConformsTo(uti as CFString, kUTTypeAudio) {
            currentFileType = .audio
            currentInfo = getInfoForAudio(atURL: item)
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.openxmlformats.wordprocessingml.document" as CFString) {
            currentFileType = .office
            currentInfo = getInfoForWordDocument(atURL: item)
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.openxmlformats.spreadsheetml.sheet" as CFString) {
            currentFileType = .office
            currentInfo = getInfoForExcelDocument(atURL: item)
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.openxmlformats.presentationml.presentation" as CFString) {
            currentFileType = .office
            currentInfo = getInfoForPowerpointDocument(atURL: item)
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.oasis-open.opendocument.text" as CFString) {
            currentFileType = .office
            currentInfo = getInfoForOpenDocument(atURL: item)
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.oasis-open.opendocument.spreadsheet" as CFString) {
            currentFileType = .office
            currentInfo = getInfoForOpenSpreadsheet(atURL: item)
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.oasis-open.opendocument.presentation" as CFString) {
            currentFileType = .office
            currentInfo = getInfoForOpenPresentation(atURL: item)
        } else if settings.isModelsHandled && UTTypeConformsTo(uti as CFString, "public.3d-content" as CFString) {
            currentFileType = .model
            currentInfo = getInfoForModel(atURL: item)
        } else if settings.isArchiveHandled && (UTTypeConformsTo(uti as CFString, "public.zip-archive" as CFString) || UTTypeConformsTo(uti as CFString, "com.rarlab.rar-archive" as CFString) || UTTypeConformsTo(uti as CFString, "public.archive" as CFString) || UTTypeConformsTo(uti as CFString, "org.gnu.gnu-zip-archive" as CFString)) {
            currentFileType = .archive
            currentInfo = getInfoForArchive(atURL: item)
        } else {
            currentFile = nil
            currentInfo = nil
            currentFileType = nil
            return nil
        }
        
        guard let info = self.currentInfo else {
            currentFile = nil
            currentInfo = nil
            currentFileType = nil
            return nil
        }
        
        return getMenu(for: info)
    }
    
    /**
     Sanitize the menu.
     FinderSync transform NSMenuItem.separator to a normal NSMenuItem with empty title and disabled.
     */
    func sanitizeMenu(_ menu: NSMenu?) {
        guard let menu = menu else { return }
        
        var n = -1
        var remove: [Int] = []
        for (i, item) in menu.items.enumerated() {
            if let m = item.submenu {
                sanitizeMenu(m)
                if m.items.isEmpty {
                    item.submenu = nil
                }
            } else {
                if item.title.isEmpty && !item.isEnabled {
                    if n + 1 == i {
                        // Remove consecutive empty items.
                        remove.append(i)
                    }
                    n = i
                }
            }
        }
        for i in remove.reversed() {
            menu.removeItem(at: i)
        }
        
        while let item = menu.items.last, item.title.isEmpty && !item.isEnabled {
            // Remove last empty item
            menu.removeItem(item)
        }
        
        let attributes: [NSAttributedString.Key : Any] = [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
        let dash = "─"
        let dash_size = (dash as NSString).size(withAttributes:attributes).width
        
        var fakeSeparator: ((NSMenu)->Void)? = nil
        fakeSeparator = { menu in
            let max_width = menu.items.reduce(0 as CGFloat, { tot, item in
                var width = (item.title as NSString).size(withAttributes: attributes).width
                if let image = item.image {
                    width += image.size.width + 8
                }
                if item.submenu != nil {
                    width += 24
                }
                return max(tot, width)
            })
            let length = min(100, Int(floor(max_width / dash_size)))
            for item in menu.items {
                if let m = item.submenu {
                    fakeSeparator!(m)
                } else {
                    if item.title.isEmpty && !item.isEnabled {
                        item.title = String(repeating: dash, count: length)
                    }
                }
            }
        }
        fakeSeparator!(menu)
    }
    
    var representedObjects: [Int: Any] = [:]
    
    internal func postprocessMenuItem(_ item: NSMenuItem) {
        var hasher = Hasher()
        hasher.combine(item.tag)
        hasher.combine(item.title)
        let key = hasher.finalize()
        
        item.representedObject = representedObjects[key]
        
        if item.tag != 0, let representedObject = self.representedObjects[item.tag] {
            item.representedObject = representedObject
        }
    }
    
    internal func postprocessMenu(_ menu: NSMenu?) {
        guard let menu = menu else {
            return
        }
        for item in menu.items {
            if item.tag != 0, let representedObject = self.representedObjects[item.tag] {
                item.representedObject = representedObject
            }
        }
    }
    
    func getMenu(for info: BaseInfo) -> NSMenu? {
        let menu = info.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        self.representedObjects = BaseInfo.preprocessMenu(menu)
        return menu
    }
    
    func getInfoForImage(atURL item: URL) -> ImageInfo? {
        return HelperWrapper.getImageInfo(for: item)
    }
    
    func getInfoForVideo(atURL item: URL) -> VideoInfo? {
        return HelperWrapper.getVideoInfo(for: item)
    }
    
    func getInfoForAudio(atURL item: URL) -> AudioInfo? {
        return HelperWrapper.getAudioInfo(for: item)
    }
    
    func getInfoForPDF(atURL item: URL) -> PDFInfo? {
        return HelperWrapper.getPDFInfo(for: item)
    }
    
    func getInfoForWordDocument(atURL item: URL) -> WordInfo? {
        return HelperWrapper.getWordInfo(for: item)
    }
    
    func getInfoForExcelDocument(atURL item: URL) -> ExcelInfo? {
        return HelperWrapper.getExcelInfo(for: item)
    }
    
    func getInfoForPowerpointDocument(atURL item: URL) -> PowerpointInfo? {
        return HelperWrapper.getPowerpointInfo(for: item)
    }
    
    func getInfoForOpenDocument(atURL item: URL) -> WordInfo? {
        return HelperWrapper.getOpenDocumentInfo(for: item)
    }
    
    func getInfoForOpenSpreadsheet(atURL item: URL) -> ExcelInfo? {
        return HelperWrapper.getOpenSpreadsheetInfo(for: item)
    }
    
    func getInfoForOpenPresentation(atURL item: URL) -> PowerpointInfo? {
        return HelperWrapper.getOpenPresentationInfo(for: item)
    }

    func getInfoForModel(atURL item: URL) -> ModelInfo? {
        return HelperWrapper.getModelInfo(for: item)
    }
    
    func getInfoForArchive(atURL item: URL) -> ArchiveInfo? {
        return HelperWrapper.getArchiveInfo(for: item)
    }
}

// MARK: - JSDelegate
extension FinderSync: JSDelegate {
    func jsOpen(path: String, reply: @escaping (Bool)->Void) {
        HelperWrapper.openFile(url: URL(fileURLWithPath: path), reply: reply)
    }
    func jsOpen(path: String, with app: String, reply: @escaping (Bool, String?)->Void) {
        HelperWrapper.openFile(url: URL(fileURLWithPath: path), withApp: app, reply: reply)
    }
    func jsExec(command: String, arguments: [String], reply: @escaping (Int32, String) -> Void) {
        HelperWrapper.systemExec(command: command, arguments: arguments, reply: reply)
    }
        
    func jsRunApp(at path: String, reply: @escaping (Bool, String?)->Void) {
        HelperWrapper.openApplication(at: URL(fileURLWithPath: path), reply: reply)
    }
    
    func jsCopyToClipboard(text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                
        let r = pasteboard.setString(text, forType: NSPasteboard.PasteboardType.string)
        return r
    }
}
