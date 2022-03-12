//
//  BaseFileItemInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 05/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Cocoa
import UniformTypeIdentifiers

class BaseFileItemInfo: Codable {
    static var genericIcons: [String: NSImage?] = [:]
    
    enum CodingKeys: String, CodingKey {
        case url
        case icon
        case size
        case localizedName
        
        case isHidden
        case isAlias
        case isApplication
        case isDirectory
        case isPackage
        
        case files
        case isPartial
    }
    
    //MARK: - Properties
    var url: URL
    /// File size.
    let fileSize: Int?
    let fileIcon: NSImage?
    
    /// Generic icon associated to the file type.
    var genericIcon: NSImage? {
        let img: NSImage?
        if #available(macOS 11.0, *) {
            let uti = self.uti
            if let i = Self.genericIcons[uti.identifier] {
                img = i
            } else {
                img = NSWorkspace.shared.icon(for: uti)
                Self.genericIcons[uti.identifier] = img
            }
        } else {
            let uti_identifier = self.uti_identifier
            if let i = Self.genericIcons[uti_identifier] {
                img = i
            } else {
                img = NSWorkspace.shared.icon(forFileType: uti_identifier)
                Self.genericIcons[uti_identifier] = img
            }
        }
        return img
    }
    
    var displayIcon: NSImage? {
        if let icon = self.fileIcon {
            return icon
        } else if let icon = self.genericIcon {
            return icon
        } else {
            return nil
        }
    }
    
    /// Filename.
    var name: String {
        return url.lastPathComponent
    }
    var localizedName: String?
    
    var displayName: String {
        return localizedName ?? name
    }
    
    /// Full path.
    var fullPath: String {
        return url.path
    }
    
    fileprivate(set) var isHidden: Bool
    let isAlias: Bool
    fileprivate(set) var isApplication: Bool
    let isDirectory: Bool
    fileprivate(set) var isPackage: Bool
    
    /// Children files.
    var files: [BaseFileItemInfo] {
        didSet {
            oldValue.forEach({ $0.parent = nil })
            files.forEach({ $0.parent = self })
        }
    }
    var isPartial: Bool
    /// Owner
    var parent: BaseFileItemInfo?
    
    /// Recursive uncompressed file size.
    var totalFilesSize: Int {
        var size = self.fileSize ?? 0
        for file in self.files {
            size += file.totalFilesSize
        }
        return size
    }
    
    /// Recursive total number of files.
    /// For bundle file the children are no counted.
    var totalFilesCount: Int {
        var n = 1
        for file in files {
            n += file.totalFilesCount
        }
        return n
    }
    
    var localizedTypeName: String? {
        if #available(macOS 11.0, *) {
            return self.uti.localizedDescription
        } else {
            let unmanagedDescription = UTTypeCopyDescription(self.uti_identifier as CFString)

            guard let description = unmanagedDescription?.takeRetainedValue() as String? else {
                return nil
            }
            return description
        }
    }
    
    
    
    // MARK: -
    /// Get the file icon. Will be overlay a badge for symblink or encrypted file.
    /// - parameters:
    ///   - size: Size of the returned image.
    func getIcon(size: NSSize) -> NSImage? {
        guard let icon: NSImage = self.displayIcon else {
            return nil
        }
        let badge: NSImage?
        if isAlias {
            badge = NSImage(contentsOfFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AliasBadgeIcon.icns")
        } else {
            badge = nil
        }
        
        if (badge == nil && !isHidden && icon.size == size) {
            return icon
        }

        let badgedFileIcon = NSImage(size: size, flipped: false) { dstRect in
            icon.draw(in: dstRect, from: NSRect(origin: .zero, size: icon.size), operation: .sourceOver, fraction: self.isHidden ? 0.5 : 1, respectFlipped: true, hints: nil)
            if let badge = badge {
                badge.draw(in: dstRect, from: NSRect(x: 0, y: 0, width: badge.size.width, height: badge.size.height), operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            }
            return true
        }
        
        return badgedFileIcon
    }
    
    @available(macOS 11.0, *)
    private(set) lazy var uti: UTType = {
        if self.isApplication {
            return UTType.application
        } else if self.isPackage {
            return UTType.package
        } else if self.isDirectory {
            return UTType.folder
        } else if self.isAlias {
            return UTType.aliasFile // UTType.symbolicLink
        } else {
            let file_ext = self.url.pathExtension
            if file_ext.isEmpty {
                return UTType.item
            } else {
                return UTType(filenameExtension: file_ext) ?? UTType.item
            }
        }
    }()
    
    @available(macOS, deprecated: 12.0, message: "Use uti instead.")
    private(set) lazy var uti_identifier: String = {
        if self.isApplication {
            return kUTTypeApplication as String
        } else if self.isPackage {
            return kUTTypePackage as String
        } else if self.isDirectory {
            return kUTTypeFolder as String
        } else if self.isAlias {
            return kUTTypeAliasFile as String // kUTTypeSymLink as String
        } else {
            let fileExtension = self.url.pathExtension
            guard !fileExtension.isEmpty else {
                return kUTTypeItem as String
            }
            let unmanagedString = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension as CFString, fileExtension as CFString, nil)

            let typeIdentifier = unmanagedString?.takeRetainedValue() as String?

            return typeIdentifier ?? kUTTypeItem as String
        }
    }()
    
    // MARK: - Init
    
    init(url: URL, fileSize: Int?, fileIcon: NSImage?, localizedName: String? = nil, isHidden: Bool = false, isDirectory: Bool, isPackage: Bool = false, isAlias: Bool = false, isApplication: Bool = false, files: [BaseFileItemInfo], isPartial: Bool) {
        self.url = url
        self.fileSize = fileSize
        self.fileIcon = fileIcon?.resized(to: NSSize(width: 16, height: 16))
        
        self.localizedName = localizedName
        
        self.isHidden = isHidden
        self.isAlias = isAlias
        self.isApplication = isApplication
        self.isDirectory = isDirectory
        self.isPackage = isPackage
        
        self.files = files
        self.isPartial = isPartial
    }
    
    convenience init?(from info: URLResourceValues) {
        guard let path = info.path else {
            return nil
        }
        
        self.init(
            url: URL(fileURLWithPath: path),
            fileSize: info.totalFileSize ?? info.fileAllocatedSize ?? info.fileSize,
            fileIcon: (info.effectiveIcon as? NSImage)?.resized(to: NSSize(width: 16, height: 16)),
            localizedName: info.localizedName,
            isHidden: info.isHidden ?? false,
            isDirectory: info.isDirectory ?? false,
            isPackage: info.isPackage ?? false,
            isAlias: info.isAliasFile ?? false || info.isSymbolicLink ?? false,
            isApplication: info.isApplication ?? false,
            files: [],
            isPartial: false
        )
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
        
        if let data = try container.decode(Data?.self, forKey: .icon) {
            if let img = NSImage(data: data) {
                self.fileIcon = img
            } else {
                self.fileIcon = nil
            }
        } else {
            self.fileIcon = nil
        }
        self.fileSize = try container.decode(Int?.self, forKey: .size)
        self.localizedName = try container.decode(String?.self, forKey: .localizedName)
        
        self.isHidden = try container.decode(Bool.self, forKey: .isHidden)
        self.isAlias = try container.decode(Bool.self, forKey: .isAlias)
        self.isApplication = try container.decode(Bool.self, forKey: .isApplication)
        self.isDirectory = try container.decode(Bool.self, forKey: .isDirectory)
        self.isPackage = try container.decode(Bool.self, forKey: .isPackage)
        
        self.files = try container.decode([FolderFile]?.self, forKey: .files) ?? []
        self.isPartial = try container.decode(Bool.self, forKey: .isPartial)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.fileIcon?.tiffRepresentation, forKey: .icon)
        try container.encode(self.fileSize, forKey: .size)
        try container.encode(self.localizedName, forKey: .localizedName)
        try container.encode(self.isHidden, forKey: .isHidden)
        try container.encode(self.isAlias, forKey: .isAlias)
        try container.encode(self.isApplication, forKey: .isApplication)
        try container.encode(self.isDirectory, forKey: .isDirectory)
        try container.encode(self.isPackage, forKey: .isPackage)
        try container.encode(self.files as? [Self], forKey: .files)
        try container.encode(self.isPartial, forKey: .isPartial)
    }

    /// Get a child file.
    subscript(_ name: String) -> BaseFileItemInfo? {
        return self.files.first(where: { $0.name == name })
    }
    
    subscript(fullPath path: String) -> BaseFileItemInfo? {
        for file in files {
            if file.fullPath == path {
                return file
            } else if let f = file[fullPath: path] {
                return f
            }
        }
        return nil
    }
    
    func append(_ file: BaseFileItemInfo) {
        self.files.append(file)
        file.parent = self
    }
    func remove(at index: Int) -> BaseFileItemInfo {
        let f = self.files.remove(at: index)
        f.parent = nil
        return f
    }
    
    func getSortedFiles(foldersFirst sortFoldersFirst: Bool) -> [BaseFileItemInfo] {
        let files = self.files.sorted { a, b in
            if sortFoldersFirst {
                if a.isDirectory {
                    if b.isDirectory {
                        return a.displayName.lowercased() < b.displayName.lowercased()
                    } else {
                        return true
                    }
                } else {
                    if b.isDirectory {
                        return false
                    } else {
                        return a.displayName.lowercased() < b.displayName.lowercased()
                    }
                }
            } else {
                return a.displayName.lowercased() < b.displayName.lowercased()
            }
        }
        return files
    }
}


protocol FilesContainer: FileInfo {
    var mainFile: BaseFileItemInfo { get }
    var totalSize: Int { get }
    var totalFilesCount: Int { get }
    var unlimitedFileCount: Int { get }
    var unlimitedFileSize: Int { get }
    var isPartial: Bool { get }
    var isTotalSizePartial: Bool { get }
    var isTotalFilePartial: Bool { get }

    func processFilesPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String? 
    func fileAtPath(_ path: String) -> BaseFileItemInfo?
    
    func formatFilesTitle(settings: Settings) -> String
    func customizeFileMenuItem(item: MenuItemInfo, file: BaseFileItemInfo, settings: Settings) -> MenuItemInfo
}

extension FilesContainer {
    /// Total uncompressed size.
    var totalSize: Int {
        var size: Int = 0
        for file in mainFile.files {
            size += file.totalFilesSize
        }
        return size
    }
    /// Total file count.
    var totalFilesCount: Int {
        var n = 0
        for file in mainFile.files {
            n += file.totalFilesCount
        }
        return n
    }
    
    internal func format_partial_menu(depth: Int, settings: Settings, item: MenuItemInfo) -> NSMenuItem {
        let mnu = self.createMenuItem(title: "…", image: "no-space", settings: settings, representedObject: item)
        mnu.isEnabled = false
        mnu.action = nil
        mnu.target = nil
        mnu.indentationLevel = depth
        return mnu
    }
    
    internal func format_files(title: String, files: [BaseFileItemInfo], isPartial: Bool, icons show_icons: Bool, plain: Bool, depth: Int, maxDepth: Int, maxFilesInDepth: Int, allowBundle: Bool, sortFoldersFirst: Bool, settings: Settings, item: MenuItemInfo) -> NSMenu {
        let submenu = NSMenu(title: title)
        var n = 0
        for file in files {
            let info = customizeFileMenuItem(item: item, file: file, settings: settings)
            let m = self.createMenuItem(title: file.name, image: nil, settings: settings, representedObject: info)
            if show_icons {
                m.image = file.getIcon(size: NSSize(width: 16, height: 16))
            }
            if plain {
                m.indentationLevel = depth
            }
            submenu.addItem(m)
            
            if file.isDirectory {
                let files_menu = format_files(title: file.name, files: file.getSortedFiles(foldersFirst: sortFoldersFirst), isPartial: file.isPartial, icons: show_icons, plain: plain, depth: depth + 1, maxDepth: maxDepth, maxFilesInDepth: maxFilesInDepth, allowBundle: allowBundle, sortFoldersFirst: sortFoldersFirst, settings: settings, item: item)
                if file.isPartial {
                    files_menu.addItem(format_partial_menu(depth: plain ? depth : 0, settings: settings, item: item))
                }
                if plain {
                    for item in files_menu.items {
                        submenu.addItem(item.copy() as! NSMenuItem)
                    }
                } else if !files_menu.items.isEmpty {
                    submenu.setSubmenu(files_menu, for: m)
                }
            }
            n += 1
        }
        return submenu
    }
    
    func customizeFileMenuItem(item: MenuItemInfo, file: BaseFileItemInfo, settings: Settings) -> MenuItemInfo {
        var info = item
        info.userInfo["file"] = file.fullPath
        return info
    }
    
    func formatFilesTitle(settings: Settings) -> String {
        let n = self.unlimitedFileCount
        let title = self.formatCount(n, noneLabel: "no file", singleLabel: self.isPartial ? "more than 1 file" : "1 file", manyLabel: self.isTotalFilePartial ? "more than %@ files" : "%@ files", useEmptyData: !settings.isEmptyItemsSkipped, formatAsString: true)
        return title
    }
    
    func processFilesPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String? {
        switch placeholder {
        case "[[n-files]]":
            isFilled = self.unlimitedFileCount > 0
            if isTotalFilePartial {
                return self.formatCount(self.unlimitedFileCount, noneLabel: "no file", singleLabel: "more than 1 file", manyLabel: "more than %@ files", isFilled: &isFilled, useEmptyData: !settings.isEmptyItemsSkipped, formatAsString: true)
            } else {
                return self.formatCount(self.unlimitedFileCount, noneLabel: "no file", singleLabel: "1 file", manyLabel: "%@ files", isFilled: &isFilled, useEmptyData: !settings.isEmptyItemsSkipped, formatAsString: true)
            }
        case "[[n-files-processed]]":
            let n = self.totalFilesCount
            isFilled = n > 0
            return self.formatCount(n, noneLabel: "no processed file", singleLabel: "1 processed file", manyLabel: "%@ processed files", isFilled: &isFilled, useEmptyData: !settings.isEmptyItemsSkipped, formatAsString: true)
        case "[[n-files-all]]":
            var s = self.processFilesPlaceholder("[[n-files]]", settings: settings, isFilled: &isFilled, forItem: item)!
            let n = self.totalFilesCount
            if self.unlimitedFileCount == n {
                return s
            }
            s += " ("
            s += self.formatCount(n, noneLabel: "no processed file", singleLabel: "1 processed file", manyLabel: "%@ processed files", isFilled: &isFilled, useEmptyData: !settings.isEmptyItemsSkipped, formatAsString: true)
            s += ")"
            isFilled = self.unlimitedFileCount > 0 || self.totalFilesCount > 0
            return s
        default:
            return nil
        }
    }
    
    func fileAtPath(_ path: String) -> BaseFileItemInfo? {
        for file in mainFile.files {
            if file.fullPath == path {
                return file
            } else if let f = file[fullPath: path] {
                return f
            }
        }
        return nil
    }
}

