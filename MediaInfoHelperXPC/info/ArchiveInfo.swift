//
//  ArchiveInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 03/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import UniformTypeIdentifiers

class ArchivedFile: Codable {
    public enum ArchiveSortEnum: String {
        case name = "name"
        case creationDate = "cDate"
        case updateDate = "mDate"
        case accessDate = "aDate"
        case size = "size"
        case mode = "mode"
        case description = "description"
        case format = "format"
        case uid = "uid"
        case gid = "gid"
        case uidName = "uidName"
        case gidName = "gidName"
        case encrypted = "encrypted"
    }
    
    enum ArchivedFileTypeEnum: Int {
        case regular
        case symblink
        case socket
        case characterDevice
        case blockDevice
        case directory
        case namedPipe
        case unknown
        
        var label: String {
            switch self {
            case .regular:
                return "regular"
            case .symblink:
                return "symbolic link"
            case .socket:
                return "socket"
            case .characterDevice:
                return "character device"
            case .blockDevice:
                return "block device"
            case .directory:
                return "directory"
            case .namedPipe:
                return "named pipe"
            case .unknown:
                return "unknown"
            }
        }
    }
    
    static var genericIcons: [String: NSImage?] = [:]
    
    enum CodingKeys: String, CodingKey {
        case originalPath
        case url
        case link
        case mode
        case type
        case typeLabel
        case size
        case format
        case isEncrypted
        case creationDate
        case modificationDate
        case accessDate
        case uid
        case uidName
        case gid
        case gidName
        case acl
        case flags
        case files
        case isAbsolute
        case isApp
        case isBundle
        case isHidden
    }
    
    //MARK: - Properties
    let originalPath: String
    var url: URL
    
    /// Filename.
    var name: String {
        return url.lastPathComponent
    }
    /// Full path.
    var fullPath: String {
        return url.path
    }
    /// Check if is a hidden file.
    var isHidden: Bool {
        return url.lastPathComponent.hasPrefix(".")
    }
    /// Check if has an absolute path.
    var isAbsolute: Bool {
        return self.originalPath.hasPrefix("/")
    }
    /// Check if the file is a macOS Application Bundle.
    var isApp: Bool {
        return self.type == .directory && self.url.pathExtension == "app" && isBundle
    }
    /// Check if the file is a macOS Bundle.
    var isBundle: Bool {
        return self.type == .directory && self["Contents"]?["Info.plist"] != nil
    }
    
    let link: String?
    
    let mode: String
    
    let type: ArchivedFileTypeEnum
    
    /// Uncompressed file size.
    let size: Int64
    /// Recursive uncompressed file size.
    var totalSize: Int64 {
        var size = self.size
        for file in self.files {
            size += file.totalSize
        }
        return size
    }
    
    let format: String
    let isEncrypted: Bool
    
    /// Creation time.
    let cDate: time_t
    /// Creation time.
    private(set) lazy var creationDate: Date? = {
        return cDate > 0 ? Date(timeIntervalSince1970: TimeInterval(self.cDate)) : nil
    }()
    /// Modification time.
    let mDate: time_t
    /// Modification time.
    private(set) lazy var modificationDate: Date? = {
        return mDate > 0 ? Date(timeIntervalSince1970: TimeInterval(self.mDate)) : nil
    }()
    /// Access time.
    let aDate: time_t
    /// Access time.
    private(set) lazy var accessDate: Date? = {
        return aDate > 0 ? Date(timeIntervalSince1970: TimeInterval(self.aDate)) : nil
    }()
    
    /// User ID
    let uid: Int64
    /// User name
    let uidName: String?
    /// Group ID
    let gid: Int64
    /// Group name
    let gidName: String?
    /// ACL
    let acl: String?
    
    let flags: String
    
    /// Children files.
    var files: [ArchivedFile]
    /// Owner
    var parent: ArchivedFile?
    
    /// Recursive total number of files.
    /// For bundle file the children are no counted.
    var totalFilesCount: Int {
        var n = 1
        if !self.isBundle {
            for file in files {
                n += file.totalFilesCount
            }
        }
        return n
    }
    
    @available(macOS 11.0, *)
    private(set) lazy var uti: UTType = {
        switch self.type {
        case .directory:
            if self.isApp {
                return UTType.application
            } else if self.isBundle {
                return UTType.bundle
            } else {
                return UTType.folder
            }
        case .regular:
            let file_ext = self.url.pathExtension
            if file_ext.isEmpty {
                return UTType.item
            } else {
                return UTType(filenameExtension: file_ext) ?? UTType.item
            }
        case .symblink:
            return UTType.symbolicLink
        default:
            return UTType.data
        }
    }()
    
    @available(macOS, deprecated: 12.0, message: "Use uti instead.")
    private(set) lazy var uti_identifier: String = {
        switch self.type {
        case .directory:
            if self.isApp {
                return kUTTypeApplication as String
            } else if self.isApp {
                return kUTTypeBundle as String
            } else {
                return kUTTypeFolder as String
            }
        case .regular:
            let fileExtension = self.url.pathExtension
            guard !fileExtension.isEmpty else {
                return kUTTypeItem as String
            }
            let unmanagedString = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension as CFString,
                                                                        fileExtension as CFString,
                                                                        nil)

            let typeIdentifier = unmanagedString?.takeRetainedValue() as String?

            return typeIdentifier ?? kUTTypeItem as String
        case .symblink:
            return kUTTypeSymLink as String
        default:
            return kUTTypeData as String
        }
    }()
    
    private(set) lazy var localizedTypeName: String? = {
        if #available(macOS 11.0, *) {
            return self.uti.localizedDescription
        } else {
            let unmanagedDescription = UTTypeCopyDescription(self.uti_identifier as CFString)

            guard let description = unmanagedDescription?.takeRetainedValue() as String? else {
                return nil
            }
            return description
        }
    }()
    
    /// Generic icon associated to the file type.
    private(set) lazy var genericIcon: NSImage? = {
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
    }()
    
    // MARK: - Init    
    public init(fullpath: String, mode: String, cDate: time_t, mDate: time_t, aDate: time_t, type: ArchivedFileTypeEnum, size: Int64, format: String, uid: Int64, uidName: String?, gid: Int64, gidName: String?, acl: String? = "", flags: String = "", link: String? = nil, encrypted: Bool = false) {
        var path = fullpath
        
        if path.hasPrefix("./") {
            path = String(path.dropFirst(2))
        }
        
        self.originalPath = fullpath
        self.url = URL(fileURLWithPath: path, isDirectory: type == .directory, relativeTo: URL(fileURLWithPath: "/"))
        
        self.cDate = cDate
        self.mDate = mDate
        self.aDate = aDate
        
        self.type = type
        self.size = size
        self.format = format
        
        self.uid = uid
        self.uidName = uidName
        self.gid = gid
        self.gidName = gidName
        
        self.mode = mode
        self.acl = acl
        
        self.flags = flags
        self.link = link
        
        self.isEncrypted = encrypted
        
        self.files = []
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
        self.originalPath = try container.decode(String.self, forKey: .originalPath)
        self.type = ArchivedFileTypeEnum(rawValue: try container.decode(Int.self, forKey: .type))!
        self.cDate = try container.decode(time_t.self, forKey: .creationDate)
        self.mDate = try container.decode(time_t.self, forKey: .modificationDate)
        self.aDate = try container.decode(time_t.self, forKey: .accessDate)
        self.size = try container.decode(Int64.self, forKey: .size)
        self.format = try container.decode(String.self, forKey: .format)
        self.uid = try container.decode(Int64.self, forKey: .uid)
        self.uidName = try container.decode(String?.self, forKey: .uidName)
        self.gid = try container.decode(Int64.self, forKey: .gid)
        self.gidName = try container.decode(String?.self, forKey: .gidName)
        self.mode = try container.decode(String.self, forKey: .mode)
        self.acl = try container.decode(String?.self, forKey: .acl)
        self.flags = try container.decode(String.self, forKey: .flags)
        self.link = try container.decode(String?.self, forKey: .link)
        self.isEncrypted = try container.decode(Bool.self, forKey: .isEncrypted)
        self.files = try container.decode([ArchivedFile].self, forKey: .files)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.originalPath, forKey: .originalPath)
        try container.encode(self.type.rawValue, forKey: .type)
        try container.encode(self.cDate, forKey: .creationDate)
        try container.encode(self.mDate, forKey: .modificationDate)
        try container.encode(self.aDate, forKey: .accessDate)
        try container.encode(self.size, forKey: .size)
        try container.encode(self.format, forKey: .format)
        try container.encode(self.uid, forKey: .uid)
        try container.encode(self.uidName, forKey: .uidName)
        try container.encode(self.gid, forKey: .gid)
        try container.encode(self.gidName, forKey: .gidName)
        try container.encode(self.mode, forKey: .mode)
        try container.encode(self.acl, forKey: .acl)
        try container.encode(self.flags, forKey: .flags)
        try container.encode(self.link, forKey: .link)
        try container.encode(self.isEncrypted, forKey: .isEncrypted)
        try container.encode(self.files, forKey: .files)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.type.label, forKey: .typeLabel)
            try container.encode(self.isApp, forKey: .isApp)
            try container.encode(self.isBundle, forKey: .isBundle)
            try container.encode(self.isAbsolute, forKey: .isAbsolute)
            try container.encode(self.isHidden, forKey: .isHidden)
        }
    }
    
    // MARK: -
    /// Get the file icon. Will be overlay a badge for symblink or encrypted file.
    /// - parameters:
    ///   - size: Size of the returned image.
    func getIcon(size: NSSize) -> NSImage? {
        guard let icon = self.genericIcon else {
            return nil
        }
        let badge: NSImage?
        if isEncrypted {
            badge = NSImage(contentsOfFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/LockedBadgeIcon.icns")
        } else if type == .symblink {
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
    
    func sort(by criteria: ArchiveSortEnum, ascending: Bool) {
        self.files.sort { (a, b) -> Bool in
            let r: Bool
            switch criteria {
            case .name:
                r = a.name < b.name
            case .creationDate:
                r = a.cDate < b.cDate
            case .updateDate:
                r = a.mDate < b.mDate
            case .accessDate:
                r = a.aDate < b.aDate
            case .size:
                r = a.size < b.size
            case .mode:
                r = a.mode < b.mode
            case .description:
                r = a.localizedTypeName ?? "" < b.localizedTypeName ?? ""
            case .format:
                r = a.format < b.format
            case .uid:
                r = a.uid < b.uid
            case .gid:
                r = a.gid < b.gid
            case .uidName:
                if let a_uidName = a.uidName {
                    if let b_uidName = b.uidName {
                        r = a_uidName < b_uidName
                    } else {
                        r = false
                    }
                } else {
                    r = true
                }
            case .gidName:
                if let a_gidName = a.gidName {
                    if let b_gidName = b.gidName {
                        r = a_gidName < b_gidName
                    } else {
                        r = false
                    }
                } else {
                    r = true
                }
            case .encrypted:
                r = (a.isEncrypted ? 1 : 0) < (b.isEncrypted ? 1 : 0)
            }
            return ascending ? r : !r
        }
        for file in self.files {
            file.sort(by: criteria, ascending: ascending)
        }
    }
    
    /// Get a child file.
    subscript(_ name: String) -> ArchivedFile? {
        return self.files.first(where: { $0.name == name })
    }
    
    subscript(fullPath path: String) -> ArchivedFile? {
        for file in files {
            if file.fullPath == path {
                return file
            } else if let f = file[fullPath: path] {
                return f
            }
        }
        return nil
    }
    
    func append(_ file: ArchivedFile) {
        self.files.append(file)
        file.parent = self
    }
    func remove(at index: Int) -> ArchivedFile {
        let f = self.files.remove(at: index)
        f.parent = nil
        return f
    }
    
    // MARK: -
    class func reorganize(files: [ArchivedFile], prefix: String = "") -> [ArchivedFile] {
        var processing_files = files
        var organized_files: [ArchivedFile] = []
        
        while !processing_files.isEmpty {
            let file = processing_files.removeFirst()
            organized_files.append(file)
            
            
            guard file.type == .directory else {
                continue
            }
            
            let base = file.url.path
            
            var n = 0
            while n < processing_files.count {
                let file2 = processing_files[n]
                if file2.url.path.hasPrefix(base) {
                    let u = file2.url.path.dropFirst(base.count)
                    file2.url = URL(fileURLWithPath: String(u), isDirectory: file2.type == .directory, relativeTo: file.url)
                    file.append(file2)
                    processing_files.remove(at: n)
                } else {
                    n += 1
                }
            }
        }
        for file in organized_files {
            if !file.files.isEmpty {
                file.files = reorganize(files: file.files)
            }
        }
        return organized_files
    }
}

// MARK: -
class ArchiveInfo: FileInfo {
    enum CodingKeys: String, CodingKey {
        case compressionName
        case files
        case unlimitedFileCount
        case unlimitedFileSize
    }
     
    let compressionName: String
    let files: [ArchivedFile]
    
    /// Total uncompressed size.
    var totalSize: Int64 {
        var size: Int64 = 0
        for file in files {
            size += file.totalSize
        }
        return size
    }
    /// Total file count.
    var totalFilesCount: Int {
        var n = 0
        for file in files {
            n += file.totalFilesCount
        }
        return n
    }
    
    let unlimitedFileCount: Int
    let unlimitedFileSize: Int64
    
    override var infoType: Settings.SupportedFile { return .archive }
    override var standardMainItem: MenuItemInfo {
        let template = "[[filesize]] = [[uncompressed-size]] uncompressed, [[n-files]]"
        return MenuItemInfo(fileType: self.infoType, index: -1, item: Settings.MenuItem(image: "zip", template: template))
    }
    
    init(file: URL, compressionName: String, files: [ArchivedFile], unlimitedFileCount: Int?, unlimitedFileSize: Int64?) {
        self.compressionName = compressionName
        self.files = files
        self.unlimitedFileCount = unlimitedFileCount ?? files.count
        if let unlimitedFileSize = unlimitedFileSize {
            self.unlimitedFileSize = unlimitedFileSize
        } else {
            var s: Int64 = 0
            self.files.forEach({ s += $0.totalSize })
            self.unlimitedFileSize = s
        }
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.compressionName = try container.decode(String.self, forKey: .compressionName)
        self.unlimitedFileCount = try container.decode(Int.self, forKey: .unlimitedFileCount)
        self.unlimitedFileSize = try container.decode(Int64.self, forKey: .unlimitedFileSize)
        self.files = try container.decode([ArchivedFile].self, forKey: .files)
        
        try super.init(from: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.compressionName, forKey: .compressionName)
        try container.encode(self.unlimitedFileCount, forKey: .unlimitedFileCount)
        try container.encode(self.unlimitedFileSize, forKey: .unlimitedFileSize)
        try container.encode(self.files, forKey: .files)
    }
    
    public func fileAtPath(_ path: String) -> ArchivedFile? {
        for file in files {
            if file.fullPath == path {
                return file
            } else if let f = file[fullPath: path] {
                return f
            }
        }
        return nil
    }

    // MARK: -
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        switch placeholder {
        case "[[compression-method]]":
            isFilled = !self.compressionName.isEmpty
            return self.compressionName
        case "[[n-files]]":
            isFilled = self.unlimitedFileCount > 0
            return self.formatCount(self.unlimitedFileCount, noneLabel: "No file", singleLabel: "1 File", manyLabel: "%@ Files", isFilled: &isFilled, useEmptyData: !settings.isEmptyItemsSkipped, formatAsString: true)
            
        case "[[uncompressed-size]]":
            isFilled = self.unlimitedFileSize > 0
            return Self.byteCountFormatter.string(fromByteCount: self.unlimitedFileSize)
            
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: item)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        var format_files: ((_ title: String, _ files: [ArchivedFile], _ show_icons: Bool, _ plain: Bool, _ depth: Int, _ settings: Settings) -> NSMenu)! = nil
        format_files = { (title, files, show_icons, plain, depth, settings) in
            let submenu = NSMenu(title: title)
            var n = 0
            for file in files {
                if settings.maxFilesInDepth > 0 && n >= settings.maxFilesInDepth {
                    let mnu = self.createMenuItem(title: "…", image: nil, settings: settings, representedObject: item)
                    mnu.isEnabled = false
                    mnu.action = nil
                    mnu.target = nil
                    if plain {
                        mnu.indentationLevel = depth
                    }
                    submenu.addItem(mnu)
                    break
                }
                var info = item
                info.userInfo["file"] = file.fullPath
                let m = self.createMenuItem(title: file.name, image: nil, settings: settings, representedObject: info)
                if show_icons {
                    m.image = file.getIcon(size: NSSize(width: 16, height: 16))
                }
                if plain {
                    m.indentationLevel = depth
                }
                submenu.addItem(m)
                
                if !file.files.isEmpty && !file.isBundle && (depth + 1 < settings.maxDepthArchive || settings.maxDepthArchive == 0) {
                    // Show subfiles.
                    let files_menu = format_files(file.name, file.files, show_icons, plain, depth + 1, settings)
                    if plain {
                        for item in files_menu.items {
                            submenu.addItem(item.copy() as! NSMenuItem)
                        }
                    } else {
                        submenu.setSubmenu(files_menu, for: m)
                    }
                }
                
                n += 1
            }
            return submenu
        }
        
        switch item.menuItem.template {
        case "[[files]]", "[[files-with-icon]]", "[[files-plain]]", "[[files-plain-with-icon]]":
            guard !self.files.isEmpty else {
                return true
            }
            
            let show_icons = item.menuItem.template == "[[files-with-icon]]" || item.menuItem.template == "[[files-plain-with-icon]]"
            let plain = item.menuItem.template == "[[files-plain]]" || item.menuItem.template == "[[files-plain-with-icon]]"
            
            let n = self.unlimitedFileCount
            let title = self.formatCount(n, noneLabel: "No File", singleLabel: "1 File", manyLabel: "%@ Files", useEmptyData: !settings.isEmptyItemsSkipped, formatAsString: true)
            
            let submenu = format_files(title, files, show_icons, plain, 0, settings)
            if self.files.count == 1 && !plain {
                let mnu = submenu.items.first!.copy(with: .none) as! NSMenuItem
                destination_sub_menu.addItem(mnu)
            } else {
                let mnu = self.createMenuItem(title: title, image: "zip", settings: settings, representedObject: item)
                destination_sub_menu.addItem(mnu)
                destination_sub_menu.setSubmenu(submenu, for: mnu)
            }
            
            return true
        default:
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}
