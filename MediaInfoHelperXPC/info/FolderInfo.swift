//
//  FolderInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 05/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Cocoa
import OSLog
import os.signpost

class FolderFile: BaseFileItemInfo {
    
}

// MARK: -
class FolderInfo: FileInfo, FilesContainer {
    enum CodingKeys: String, CodingKey {
        case folder
        case unlimitedFileCount
        case unlimitedFileSize
        case unlimitedFullFileSize
        case totalPartial
    }
    
    override class func updateSettings(_ settings: Settings, forItems items: [Settings.MenuItem]) {
        super.updateSettings(settings, forItems: items)
        
        var has_file_size = false
        var has_file_count = false
        for item in items {
            if item.template.contains("[[filesize-full]]") {
                settings.folderSizeMethod = .full
                return
            } else if item.template.contains("[[filesize]]") {
                has_file_size = true
            } else if item.template.contains("[[n-files]]") {
                has_file_count = true
            } else if item.template.contains("[[script") {
                let r = BaseInfo.splitTokens(in: item.template)
                for result in r {
                    let placeholder = String(item.template[Range(result.range, in: item.template)!])
                    guard placeholder.hasPrefix("[[script-") else {
                        continue
                    }
                    guard let code = String(placeholder.dropFirst(16).dropLast(2)).fromBase64() else {
                        continue
                    }
                    if code.hasPrefix("/* require-full-scan */ ") {
                        settings.folderSizeMethod = .full
                        return
                    } else if code.hasPrefix("/* require-fast-scan */ ") {
                        has_file_size = true
                        has_file_count = true
                    }
                }
            }
        }
        if has_file_size || has_file_count {
            settings.folderSizeMethod = .fast
        } else {
            settings.folderSizeMethod = .none
        }
    }
    
    static func getFolderInfo(_ folder: URL, sizeMode: Settings.FolderSizeMethod, timeoutLimit: CFAbsoluteTime) -> (size: Int, fullSize: Int, count: Int, timeout: Bool) {
        
        var count = 0
        var size = 0
        var fullSize = 0
        var isTimeout = false
        
        os_signpost(.begin, log: OSLog.infoExtraction, name: "Fetch folder size")
        let time = CFAbsoluteTimeGetCurrent()
        os_log("Fetching folder size (%{public}d)…", log: OSLog.infoExtraction, type: .debug, sizeMode.rawValue)
        
        defer {
            os_signpost(.end, log: OSLog.infoExtraction, name: "Fetch folder size")
            
            if isTimeout {
                os_log("Folder size was aborted due to a timeout! Process took %{public}lf seconds.", log: OSLog.infoExtraction, type: .error, CFAbsoluteTimeGetCurrent() - time)
            } else {
                os_log("Folder size fetched in %{public}lf seconds.", log: OSLog.infoExtraction, type: .info, CFAbsoluteTimeGetCurrent() - time)
            }
            os_log("Fetched %{public}d files for %{public}d bytes.", log: OSLog.infoExtraction, type: .info, count, size)
        }
        
        switch sizeMode {
        case .none:
            break
        case .fast:
            let seconds = UInt32(timeoutLimit - time)
            var total: UInt32 = 0
            var n: UInt32 = 0
            
            isTimeout = du(folder.path.cString(using: .utf8), &total, &n, seconds) != 0
            
            size = Int(total)
            fullSize = size
            count = Int(n)

        case .full:
            let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [], options: [])!
            for case let url as URL in enumerator {
                count += 1
                // os_log("%{public}d - Extract file size of %{private}@", log: OSLog.infoExtraction, type: .debug, count, url.path)
                
                guard let res = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey]) else {
                    continue
                }
                size += res.fileSize ?? 0
                fullSize += res.totalFileAllocatedSize ?? res.totalFileSize ?? res.fileSize ?? 0
                
                if CFAbsoluteTimeGetCurrent() >= timeoutLimit {
                    isTimeout = true
                    break
                }
            }
        }
        
        return (size: size, fullSize: fullSize, count: count, timeout: isTimeout)
    }
    
    static func populateDepth(folder: URL, maxFiles: Int, maxDepth: Int, maxFilesInDepth: Int, skipHidden: Bool, skipBundle: Bool, level: Int, count: inout Int, keys: [URLResourceKey], options: FileManager.DirectoryEnumerationOptions, sizeMode: Settings.FolderSizeMethod, timeoutLimit: CFAbsoluteTime, stop: inout Bool) -> (files: [FolderFile], limited: Bool, timeout: Bool) {
        guard maxDepth == 0 || level < maxDepth else {
            os_log("Reached the maximum limit of sub-levels: %{public}d.", log: OSLog.infoExtraction, type: .info, maxDepth)
            
            return (files: [], limited: true, timeout: false)
        }
        var limited = false
        var timeOut = false
        
        var files: [FolderFile] = []
        var n = 0
        
        let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: keys, options: options)!
        
        var folders: [FolderFile] = []
        
        for case let file as URL in enumerator {
            guard let res = try? file.resourceValues(forKeys: Set(keys)) else {
                continue
            }
            guard maxFilesInDepth == 0 || n < maxFilesInDepth else {
                os_log("Maximum number of files per level reached: %{public}d.", log: OSLog.infoExtraction, type: .info, maxFilesInDepth)
                
                limited = true
                stop = true
                break
            }
            guard let f = FolderFile(from: res) else {
                continue
            }
        
            // os_log("%{public}d - Processing %{private}@…", log: OSLog.infoExtraction, type: .debug, count, file.path)
        
            files.append(f)
            n += 1
            count += 1
            guard maxFiles == 0 || count < maxFiles else {
                if #available(macOS 11.0, *) {
                    let tot = count
                    Logger.infoExtraction.info("Maximum file limit reached: \(tot, privacy: .public).")
                } else {
                    os_log("Maximum file limit reached: %{public}d.", log: OSLog.infoExtraction, type: .info, count)
                }
                
                limited = true
                stop = true
                folders = []
                break
            }
        
            // print(file)
            let t = CFAbsoluteTimeGetCurrent()
            guard t < timeoutLimit else {
                os_log("File extraction was aborted due to a timeout!", log: OSLog.infoExtraction, type: .error)
                
                limited = true
                timeOut = true
                stop = true
                folders = []
                break
            }
            
            if f.isDirectory {
                if (f.isPackage || f.isApplication) && skipBundle {
                
                } else {
                    folders.append(f)
                }
            }
        }
        
        // Process the subfolders.
        for f in folders.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() }) {
            if stop {
                f.isPartial = true
            } else {
                let sub_files = populateDepth(folder: f.url, maxFiles: maxFiles, maxDepth: maxDepth, maxFilesInDepth: maxFilesInDepth, skipHidden: skipHidden, skipBundle: skipBundle, level: level + 1, count: &count, keys: keys, options: options, sizeMode: sizeMode, timeoutLimit: timeoutLimit, stop: &stop)
                f.files = sub_files.files.sorted(by: { $0.localizedName ?? $0.name < $1.localizedName ?? $1.name })
                f.isPartial = sub_files.limited
                if sub_files.timeout {
                    timeOut = true
                    stop = true
                }
                if sub_files.limited {
                    stop = true
                }
            }
        }
        
        return (files: files, limited: limited, timeout: timeOut)
    }
    
    static func populate(folder: URL, maxFiles: Int, maxDepth: Int, maxFilesInDepth: Int, skipHidden: Bool, skipBundle: Bool, useGenericIcon: Bool, sizeMode: Settings.FolderSizeMethod) -> (folder: FolderFile, fileCount: Int, totalSize: Int, totalFullSize: Int, isTotalPartial: Bool, timeout: Bool) {
        
        var timeoutLimit: CFAbsoluteTime = CFAbsoluteTimeGetCurrent() + Settings.infoExtractionTimeout / 3
        
        let r1 = getFolderInfo(folder, sizeMode: sizeMode, timeoutLimit: timeoutLimit)
        
        var keys: [URLResourceKey] = [
            .pathKey,
            //.localizedNameKey,
            .isDirectoryKey,
            .isPackageKey,
            .isApplicationKey,
            //.totalFileSizeKey, .fileSizeKey, .totalFileAllocatedSizeKey, // fetch file size slow down the extraction.
            .isAliasFileKey, .isSymbolicLinkKey,
        ]
        if !skipHidden {
            keys.append(.isHiddenKey)
        }
        if !useGenericIcon {
            keys.append(.effectiveIconKey)
        }
        
        var options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants]
        if skipBundle {
            options.insert(.skipsPackageDescendants)
        }
        if skipHidden {
            options.insert(.skipsHiddenFiles)
        }
        
        if Bundle.main.bundlePath.hasSuffix(".xpc") {
            if #available(macOS 11.0, *) {
                Logger.infoExtraction.debug("Starting file extraction {maxFiles: \(maxFiles), maxDepth: \(maxDepth), maxFilesInDepth: \(maxFilesInDepth), skipHidden: \(skipHidden), skipBundle: \(skipBundle), useGenericIcon: \(useGenericIcon)}…")
            } else {
                os_log("Starting file extraction…", log: OSLog.infoExtraction, type: .debug)
            }
            
            timeoutLimit = CFAbsoluteTimeGetCurrent() + Settings.infoExtractionTimeout * 2 / 3
        } else {
            os_log("Starting file extraction with no timeout…", log: OSLog.infoExtraction, type: .debug)
            
            timeoutLimit = CFAbsoluteTimeGetCurrent() + 100000
        }
        
        var count = 0
        var stop = false
        
        let time = CFAbsoluteTimeGetCurrent()
        
        let r2 = self.populateDepth(folder: folder, maxFiles: maxFiles, maxDepth: maxDepth, maxFilesInDepth: maxFilesInDepth, skipHidden: skipHidden, skipBundle: skipBundle, level: 0, count: &count, keys: keys, options: options, sizeMode: sizeMode, timeoutLimit: timeoutLimit, stop: &stop)
        
        keys.append(.effectiveIconKey)
        keys.append(.localizedNameKey)
        let info = try? folder.resourceValues(forKeys: Set(keys))
        
        let main_folder: FolderFile = FolderFile(
            url: folder,
            fileSize: info?.fileSize,
            fileIcon: (info?.effectiveIcon as? NSImage)?.resized(to: NSSize(width: 16, height: 16)),
            localizedName: info?.localizedName,
            isHidden: info?.isHidden ?? false,
            isDirectory: info?.isDirectory ?? true,
            isPackage: info?.isPackage ?? false,
            isAlias: (info?.isAliasFile ?? false) || (info?.isSymbolicLink ?? false),
            isApplication: info?.isApplication ?? false,
            files: r2.files,
            isPartial: r2.timeout || r2.limited
        )
        
        if #available(macOS 11.0, *) {
            Logger.infoExtraction.info("Files extracted in \(CFAbsoluteTimeGetCurrent() - time, privacy: .public) seconds: \(main_folder.totalFilesCount, privacy: .public) files.")
        } else {
            os_log("Files extracted in %{public}d seconds.", log: OSLog.infoExtraction, type: .info, CFAbsoluteTimeGetCurrent() - time)
        }
        
        return (
            folder: main_folder,
            fileCount: r1.count,
            totalSize: r1.size,
            totalFullSize: r1.fullSize,
            isTotalPartial: r1.timeout,
            timeout: r1.timeout || r2.timeout
        )
    }
     
    let mainFile: BaseFileItemInfo
    let isTotalPartial: Bool
    var isTotalFilePartial: Bool {
        return isTotalPartial
    }
    var isTotalSizePartial: Bool {
        return isTotalPartial
    }
    var isPartial: Bool {
        return mainFile.isPartial
    }
    
    let unlimitedFileCount: Int
    let unlimitedFileSize: Int
    let unlimitedFullFileSize: Int
    
    override var infoType: Settings.SupportedFile { return .folder }
    override var standardMainItem: MenuItemInfo {
        let template = "[[file-name]]"
        return MenuItemInfo(fileType: self.infoType, index: -1, item: Settings.MenuItem(image: "target-icon", template: template))
    }
    
    convenience init(
        folder: URL,
        maxFiles: Int,
        maxDepth: Int,
        maxFilesInDepth: Int,
        skipHidden: Bool,
        skipBundle: Bool,
        useGenericIcon: Bool,
        sizeMode: Settings.FolderSizeMethod
    ) {
        let result = Self.populate(folder: folder, maxFiles: maxFiles, maxDepth: maxDepth, maxFilesInDepth: maxFilesInDepth, skipHidden: skipHidden, skipBundle: skipBundle, useGenericIcon: useGenericIcon, sizeMode: sizeMode)
        
        self.init(
            folder: result.folder,
            unlimitedFileCount: result.fileCount,
            unlimitedFileSize: result.totalSize,
            unlimitedFullFileSize: result.totalFullSize,
            isTotalPartial: result.isTotalPartial
        )
    }
    
    init(folder main: FolderFile, unlimitedFileCount: Int, unlimitedFileSize: Int, unlimitedFullFileSize: Int, isTotalPartial: Bool) {
        self.mainFile = main
        self.unlimitedFileCount = unlimitedFileCount
        self.unlimitedFileSize = unlimitedFileSize
        self.unlimitedFullFileSize = unlimitedFullFileSize
        self.isTotalPartial = isTotalPartial
        
        super.init(file: main.url)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.unlimitedFileCount = try container.decode(Int.self, forKey: .unlimitedFileCount)
        self.unlimitedFileSize = try container.decode(Int.self, forKey: .unlimitedFileSize)
        self.unlimitedFullFileSize = try container.decode(Int.self, forKey: .unlimitedFullFileSize)
        
        self.mainFile = try container.decode(FolderFile.self, forKey: .folder)
        self.isTotalPartial = try container.decode(Bool.self, forKey: .totalPartial)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.unlimitedFileCount, forKey: .unlimitedFileCount)
        try container.encode(self.unlimitedFileSize, forKey: .unlimitedFileSize)
        try container.encode(self.unlimitedFullFileSize, forKey: .unlimitedFullFileSize)
        try container.encode(self.isTotalPartial, forKey: .totalPartial)
        try container.encode(self.mainFile, forKey: .folder)
    }
    
    func formatFilesTitle(settings: Settings) -> String {
        return self.file.lastPathComponent
    }

    func customizeFileMenuItem(item: MenuItemInfo, file: BaseFileItemInfo, settings: Settings) -> MenuItemInfo {
        var info = item
        info.userInfo["file"] = file.fullPath
        switch settings.folderAction {
        case .standard:
            break
        case .openFile:
            info.action = .open
        case .revealFile:
            info.action = .reveal
        }
        return info
    }
    
    // MARK: -
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        if let s = self.processFilesPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: item) {
            return s
        } else {
            switch placeholder {
            case "[[file-name]]":
                isFilled = true
                return self.mainFile.localizedName ?? self.file.lastPathComponent
            case "[[filesize]]":
                isFilled = self.unlimitedFileSize > 0
                if unlimitedFileSize >= 0 {
                    let f = Self.byteCountFormatter.string(fromByteCount: Int64(unlimitedFileSize))
                    if self.isTotalPartial {
                        return String(format: NSLocalizedString("more than %@", comment: ""), f)
                    } else {
                        return f
                    }
                } else {
                    return self.formatND(useEmptyData: !settings.isEmptyItemsSkipped)
                }
            case "[[filesize-full]]":
                isFilled = self.unlimitedFullFileSize > 0
                if unlimitedFullFileSize > 0 {
                    let f = Self.byteCountFormatter.string(fromByteCount: Int64(unlimitedFullFileSize))
                    if self.isTotalPartial {
                        return String(format: NSLocalizedString("more than %@", comment: ""), f)
                    } else {
                        return f
                    }
                } else {
                    return self.formatND(useEmptyData: !settings.isEmptyItemsSkipped)
                }
            default:
                return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: item)
            }
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        switch item.menuItem.template {
        case "[[files]]", "[[files-with-icon]]", "[[files-plain]]", "[[files-plain-with-icon]]":
            guard !self.mainFile.files.isEmpty else {
                return true
            }
            
            let show_icons = item.menuItem.template == "[[files-with-icon]]" || item.menuItem.template == "[[files-plain-with-icon]]"
            let plain = item.menuItem.template == "[[files-plain]]" || item.menuItem.template == "[[files-plain-with-icon]]"
            
            let title = self.formatFilesTitle(settings: settings)
            
            let submenu = format_files(title: title, files: mainFile.getSortedFiles(foldersFirst: settings.folderSortFoldersFirst), isPartial: mainFile.isPartial, icons: show_icons, plain: plain, depth: 0, maxDepth: settings.folderMaxDepth, maxFilesInDepth: settings.folderMaxFilesInDepth, allowBundle: settings.isBundleHandled, sortFoldersFirst: settings.folderSortFoldersFirst, settings: settings, item: item)
            let mnu = self.createMenuItem(title: title, image: item.menuItem.image, settings: settings, representedObject: item)
            if (mnu.image == nil || item.menuItem.image.isEmpty || item.menuItem.image == "target-icon") && !settings.isIconHidden {
                mnu.image = self.mainFile.displayIcon?.resized(to: NSSize(width: 16, height: 16))
            }
            destination_sub_menu.addItem(mnu)
            destination_sub_menu.setSubmenu(submenu, for: mnu)
            
            return true
        default:
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}
