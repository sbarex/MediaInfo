//
//  FinderSync.swift
//  MediaInfo Finder Extension
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import FinderSync
import os.log

class FinderSync: FIFinderSync {/*
    var userDriver: SPUStandardUserDriver?
    var updater: SPUUpdater?*/
    
    var settings: Settings = Settings(fromDict: [:])
    
    override init() {
        super.init()
        
        if #available(macOSApplicationExtension 11.0, *) {
            Logger.finderExtension.debug("MediaInfo FinderSync - Launched from \(Bundle.main.bundlePath, privacy: .public)")
        } else {
            os_log("MediaInfo FinderSync - Launched from %{public}@", log: OSLog.finderExtension, type: .info, Bundle.main.bundlePath)
        }
        
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
            
            if #available(macOSApplicationExtension 11.0, *) {
                Logger.finderExtension.info("MediaInfo FinderSync - Watching folders:\n \(folders.map({ $0.path }).joined(separator: "\n"), privacy: .private)")
            } else {
                os_log("MediaInfo FinderSync - Watching folders:\n %{private}@", log: OSLog.finderExtension, type: .info, folders.map({ $0.path }).joined(separator: "\n"))
            }
            
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
        os_log("MediaInfo FinderSync - Refreshing settings…", log: .finderExtension, type: .debug)
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
                let f: URL
                if let p = item.userInfo["file"] as? String {
                    f = URL(fileURLWithPath: p)
                } else {
                    f = file
                }
                HelperWrapper.openFile(url: f) {_ in }
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
            case .reveal:
                let f: URL
                if let p = item.userInfo["file"] as? String {
                    f = URL(fileURLWithPath: p)
                } else {
                    f = file
                }
                NSWorkspace.shared.activateFileViewerSelecting([f])
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
        
        let time = CFAbsoluteTimeGetCurrent()
        
        if #available(macOSApplicationExtension 11.0, *) {
            Logger.finderExtension.debug("MediaInfo FinderSync - Start info extraction for \(item.path, privacy: .private)…")
        } else {
            os_log("MediaInfo FinderSync - Start info extraction for %{private}@…", log: OSLog.finderExtension, type: .debug, item.path)
        }
        
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
        } else if settings.isArchiveHandled && ((UTTypeConformsTo(uti as CFString, kUTTypeZipArchive) || UTTypeConformsTo(uti as CFString, "com.rarlab.rar-archive" as CFString) || UTTypeConformsTo(uti as CFString, kUTTypeArchive) || UTTypeConformsTo(uti as CFString, kUTTypeGNUZipArchive) || UTTypeConformsTo(uti as CFString, kUTTypeBzip2Archive) || UTTypeConformsTo(uti as CFString, kUTTypeBzip2Archive) || UTTypeConformsTo(uti as CFString, "org.tukaani.xz-archive" as CFString))) && !(UTTypeConformsTo(uti as CFString, kUTTypeDiskImage)) {
            currentFileType = .archive
            currentInfo = getInfoForArchive(atURL: item)
        } else if settings.isFolderHandled && UTTypeConformsTo(uti as CFString,
                                                               kUTTypeFolder) {
            currentFileType = .folder
            currentInfo = getInfoForFolder(atURL: item)
        } else if settings.isFolderHandled && settings.isBundleHandled && (UTTypeConformsTo(uti as CFString, kUTTypePackage) || UTTypeConformsTo(uti as CFString, kUTTypeBundle) || UTTypeConformsTo(uti as CFString, kUTTypeApplication) || UTTypeConformsTo(uti as CFString, kUTTypeApplicationBundle)) {
           currentFileType = .folder
           currentInfo = getInfoForFolder(atURL: item)
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
        
        if #available(macOSApplicationExtension 11.0, *) {
            Logger.finderExtension.info("MediaInfo FinderSync - Info extracted in \(CFAbsoluteTimeGetCurrent() - time, privacy: .public) seconds.")
        } else {
            os_log("MediaInfo FinderSync - Info extracted in %{public}lf seconds.", log: OSLog.finderExtension, type: .info, CFAbsoluteTimeGetCurrent() - time)
        }
        
        return getMenu(for: info)
    }
    
    /// Sanitize the menu.
    ///
    /// When the Finder display the menu, NSMenuItem.separators are transformed into a normal NSMenuItem with empty title and disabled.
    ///
    /// This function replace the menu separators with a sequence of dash characters.
    func sanitizeMenu(_ menu: NSMenu?) {
        guard let menu = menu else { return }
        
        var n = -1
        var remove: [Int] = []
        var separatorCount = 0
        for (i, item) in menu.items.enumerated() {
            if let m = item.submenu {
                sanitizeMenu(m)
                if m.items.isEmpty {
                    item.submenu = nil
                }
            } else {
                if item.isSeparatorItem {
                    separatorCount += 1
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
            separatorCount -= 1
        }
        
        while let item = menu.items.last, item.isSeparatorItem {
            // Remove last separator line
            menu.removeItem(item)
            separatorCount -= 1
        }
        
        guard separatorCount > 0 else {
            return
        }
        
        // Replace the separators with a dashed line.
        
        let attributes: [NSAttributedString.Key : Any] = [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)]
        let dash = "─"
        let dash_size = (dash as NSString).size(withAttributes:attributes).width
        let max_separator_length = 130
        
        /// Max  width of the menu items.
        let max_width = menu.items.reduce(0 as CGFloat, { tot, item in
            guard !item.isSeparatorItem else {
                return tot
            }
            var width = item.title.isEmpty ? 0 : (item.title as NSString).size(withAttributes: attributes).width
            if let image = item.image {
                width += image.size.width + 8
            }
            if item.submenu != nil {
                width += 24
            }
            return max(tot, width)
        })
        /// Number of dash char required to fill the max menu item width.
        let length = min(max_separator_length, Int(floor(max_width / dash_size)))
            
        for item in menu.items {
            if item.isSeparatorItem {
                item.title = String(repeating: dash, count: length)
            }
        }
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
        let time = CFAbsoluteTimeGetCurrent()
        if #available(macOSApplicationExtension 11.0, *) {
            Logger.finderExtension.debug("MediaInfo FinderSync - Generating the menu…")
        } else {
            os_log("MediaInfo FinderSync - Generating the menu…", log: OSLog.finderExtension, type: .debug)
        }
        defer {
            if #available(macOSApplicationExtension 11.0, *) {
                Logger.finderExtension.info("MediaInfo FinderSync - Menu generated in \(CFAbsoluteTimeGetCurrent() - time, privacy: .public) seconds.")
            } else {
                os_log("MediaInfo FinderSync - Menu generated in %{public}lf seconds.", log: OSLog.finderExtension, type: .info, CFAbsoluteTimeGetCurrent() - time)
            }
        }
        
        let menu = info.getMenu(withSettings: settings)
        
        var time2 = CFAbsoluteTimeGetCurrent()
        sanitizeMenu(menu)
        os_log("MediaInfo FinderSync - Menu sanitization took %{public}lf seconds", log: OSLog.finderExtension, type: .info, CFAbsoluteTimeGetCurrent()-time2)
        
        time2 = CFAbsoluteTimeGetCurrent()
        self.representedObjects = BaseInfo.preprocessMenu(menu)
        os_log("MediaInfo FinderSync - Menu preprocessing took %{public}lf seconds", log: OSLog.finderExtension, type: .info, CFAbsoluteTimeGetCurrent()-time2)
        
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
    
    func getInfoForFolder(atURL item: URL) -> FolderInfo? {
        return HelperWrapper.getFolderInfo(for: item)
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
    
    func jsExecSync(command: String, arguments: [String])->(status: Int32, output: String) {
        let inflightSemaphore = DispatchSemaphore(value: 0)

        var status: Int32 = 0
        var output: String = ""
        var completed = false
        HelperWrapper.systemExec(command: command, arguments: arguments) { status1, output1 in
            defer {
                inflightSemaphore.signal()
            }
            
            status = status1
            output = output1
            completed = true
        }
        
        let timeoutLimit: DispatchTime = .now() + Settings.execSyncTimeout
        
        if !Thread.isMainThread {
            let r = inflightSemaphore.wait(timeout: timeoutLimit)
            if r == .timedOut && !completed {
                status = -1
                output = "Timeout"
                os_log("Timeout executing the sync command %{private}@", log: OSLog.finderExtension, type: .error, command)
            }
            // print(r)
        } else {
            while inflightSemaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
                if DispatchTime.now() >= timeoutLimit {
                    if !completed {
                        status = -1
                        output = "Timeout"
                        os_log("Timeout executing the sync command %{private}@", log: OSLog.finderExtension, type: .error, command)
                    }
                    break
                }
            }
        }
        
        return (status: status, output: output)
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
