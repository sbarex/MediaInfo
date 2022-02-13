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
    
    @objc internal func fakeMenuAction(_ sender: NSMenuItem) {
        if settings.menuWillOpenFile, let file = currentFile {
            HelperWrapper.openFile(url: file)
        }
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems else {
            return nil
        }
        guard let items = FIFinderSyncController.default().selectedItemURLs(), items.count == 1, let item = items.first, let uti = try? item.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            currentFile = nil
            return nil
        }
            
        // Specific menu item properties are used: title, action, image, and enabled. Starting in 10.11: tag, state, and indentationLevel also work, and submenus are allowed.
        
        currentFile = item
        if settings.isPDFHandled && (UTTypeConformsTo(uti as CFString, kUTTypePDF) || UTTypeConformsTo(uti as CFString, "com.adobe.illustrator.ai-image" as CFString)), let menu = getMenuForPDF(atURL: item) {
            return menu
        } else if settings.isImagesHandled && UTTypeConformsTo(uti as CFString, kUTTypeImage), let menu = getMenuForImage(atURL: item) {
            return menu
        } else if settings.isVideoHandled && UTTypeConformsTo(uti as CFString, kUTTypeMovie), let menu = getMenuForVideo(atURL: item) {
            return menu
        } else if settings.isAudioHandled && UTTypeConformsTo(uti as CFString, kUTTypeAudio), let menu = getMenuForAudio(atURL: item) {
            return menu
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.openxmlformats.wordprocessingml.document" as CFString), let menu = getMenuForWordDocument(atURL: item) {
            return menu
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.openxmlformats.spreadsheetml.sheet" as CFString), let menu = getMenuForExcelDocument(atURL: item) {
            return menu
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.openxmlformats.presentationml.presentation" as CFString), let menu = getMenuForPowerpointDocument(atURL: item) {
            return menu
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.oasis-open.opendocument.text" as CFString), let menu = getMenuForOpenDocument(atURL: item) {
            return menu
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.oasis-open.opendocument.spreadsheet" as CFString), let menu = getMenuForOpenSpreadsheet(atURL: item) {
            return menu
        } else if settings.isOfficeHandled && UTTypeConformsTo(uti as CFString, "org.oasis-open.opendocument.presentation" as CFString), let menu = getMenuForOpenPresentation(atURL: item) {
            return menu
        } else if settings.isModelsHandled && UTTypeConformsTo(uti as CFString, "public.3d-content" as CFString), let menu = getMenuForModel(atURL: item) {
            return menu
        } else if settings.isArchiveHandled && (UTTypeConformsTo(uti as CFString, "public.zip-archive" as CFString) || UTTypeConformsTo(uti as CFString, "com.rarlab.rar-archive" as CFString)), let menu = getMenuForArchive(atURL: item) {
            return menu
        } else {
            currentFile = nil
            return nil
        }
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
    }
    
    func getMenuForImage(atURL item: URL) -> NSMenu? {
        let image_info = HelperWrapper.getImageInfo(for: item)
        let menu = image_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForVideo(atURL item: URL) -> NSMenu? {
        let video = HelperWrapper.getVideoInfo(for: item)
        let menu = video?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForAudio(atURL item: URL) -> NSMenu? {
        let audio = HelperWrapper.getAudioInfo(for: item)
        let menu = audio?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForPDF(atURL item: URL) -> NSMenu? {
        let pdf_info = HelperWrapper.getPDFInfo(for: item)
        let menu = pdf_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForWordDocument(atURL item: URL) -> NSMenu? {
        let doc_info = HelperWrapper.getWordInfo(for: item)
        let menu = doc_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForExcelDocument(atURL item: URL) -> NSMenu? {
        let xls_info = HelperWrapper.getExcelInfo(for: item)
        let menu = xls_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForPowerpointDocument(atURL item: URL) -> NSMenu? {
        let ppt_info = HelperWrapper.getPowerpointInfo(for: item)
        let menu = ppt_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForOpenDocument(atURL item: URL) -> NSMenu? {
        let ppt_info = HelperWrapper.getOpenDocumentInfo(for: item)
        let menu = ppt_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForOpenSpreadsheet(atURL item: URL) -> NSMenu? {
        let ppt_info = HelperWrapper.getOpenSpreadsheetInfo(for: item)
        let menu = ppt_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForOpenPresentation(atURL item: URL) -> NSMenu? {
        let xls_info = HelperWrapper.getOpenPresentationInfo(for: item)
        let menu = xls_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }

    func getMenuForModel(atURL item: URL) -> NSMenu? {
        let model_info = HelperWrapper.getModelInfo(for: item)
        let menu = model_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
    
    func getMenuForArchive(atURL item: URL) -> NSMenu? {
        let archive_info = HelperWrapper.getArchiveInfo(for: item)
        let menu = archive_info?.getMenu(withSettings: settings)
        sanitizeMenu(menu)
        return menu
    }
}
