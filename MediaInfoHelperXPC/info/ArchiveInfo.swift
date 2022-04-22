//
//  ArchiveInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 03/06/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import UniformTypeIdentifiers

class ArchivedFile: BaseFileItemInfo {
    public enum ArchiveSortEnum: String {
        case name = "name"
        case size = "size"
        case description = "description"
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
    
    enum CodingKeys: String, CodingKey {
        case originalPath
        case type
        case typeLabel
        case isEncrypted
        case isAbsolute
        case format
    }
    
    //MARK: - Properties
    let originalPath: String
    
    /// Check if has an absolute path.
    var isAbsolute: Bool {
        return self.originalPath.hasPrefix("/")
    }
    
    /// Check if the file is a macOS Application Bundle.
    override var isApplication: Bool {
        return self.isDirectory && self.url.pathExtension == "app" && isPackage
    }
    /// Check if the file is a macOS Bundle.
    override var isPackage: Bool {
        return self.isDirectory && self["Contents"]?["Info.plist"] != nil
    }
    
    override var isHidden: Bool {
        return url.lastPathComponent.hasPrefix(".")
    }
    
    let type: ArchivedFileTypeEnum
    let format: String
    let isEncrypted: Bool
    
    // MARK: - Init    
    init(fullpath: String, type: ArchivedFileTypeEnum, size: Int?, encrypted: Bool = false, format: String = "") {
        var path = fullpath
        
        if path.hasPrefix("./") {
            path = String(path.dropFirst(2))
        }
        
        self.originalPath = fullpath
        
        self.type = type
        self.isEncrypted = encrypted
        self.format = format
        
        let url = URL(fileURLWithPath: path, isDirectory: type == .directory, relativeTo: URL(fileURLWithPath: "/"))
        super.init(
            url: url,
            fileSize: size,
            fileIcon: nil,
            isHidden: url.lastPathComponent.hasPrefix("."),
            isDirectory: type == .directory,
            isPackage: false,
            isAlias: type == .symblink,
            isApplication: false,
            files: [],
            isPartial: false)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.originalPath = try container.decode(String.self, forKey: .originalPath)
        self.type = ArchivedFileTypeEnum(rawValue: try container.decode(Int.self, forKey: .type))!
        self.isEncrypted = try container.decode(Bool.self, forKey: .isEncrypted)
        self.format = try container.decode(String.self, forKey: .format)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.originalPath, forKey: .originalPath)
        try container.encode(self.type.rawValue, forKey: .type)
        try container.encode(self.isEncrypted, forKey: .isEncrypted)
        try container.encode(self.format, forKey: .format)
        try super.encode(to: encoder)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.type.label, forKey: .typeLabel)
            try container.encode(self.isAbsolute, forKey: .isAbsolute)
        }
    }
    
    func sort(by criteria: ArchiveSortEnum, ascending: Bool) {
        self.files.sort { (a, b) -> Bool in
            guard let a = a as? ArchivedFile, let b = b as? ArchivedFile else {
                return false
            }
            let r: Bool
            switch criteria {
            case .name:
                r = a.name < b.name
            case .size:
                r = a.fileSize ?? 0 < b.fileSize ?? 0
            case .description:
                r = a.localizedTypeName ?? "" < b.localizedTypeName ?? ""
            case .encrypted:
                r = (a.isEncrypted ? 1 : 0) < (b.isEncrypted ? 1 : 0)
            }
            return ascending ? r : !r
        }
        for file in self.files {
            (file as? ArchivedFile)?.sort(by: criteria, ascending: ascending)
        }
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
                file.files = reorganize(files: file.files as! [ArchivedFile])
            }
        }
        return organized_files
    }
}

// MARK: -
class ArchiveInfo: FileInfo, FilesContainer {
    static let percentFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.allowsFloats = true
        numberFormatter.numberStyle = .percent
        numberFormatter.maximumFractionDigits = 1
        
        return numberFormatter
    }()
    
    enum CodingKeys: String, CodingKey {
        case compressionName
        case archive
        
        case unlimitedFileCount
        case unlimitedFileSize
        case partialTotalSize
        case partialTotalFile
        case partial
    }
     
    let compressionName: String
    let mainFile: BaseFileItemInfo
    
    let unlimitedFileCount: Int
    let unlimitedFileSize: Int
    let isTotalSizePartial: Bool
    let isTotalFilePartial: Bool
    let isPartial: Bool
    
    override class var infoType: Settings.SupportedFile { return .archive }
    override var standardMainItem: MenuItemInfo {
        let template = "[[file-size]] ([[uncompressed-size]]), [[n-files]]"
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "zip", template: template))
    }
    
    
    init(file: URL, compressionName: String, archive: ArchivedFile, unlimitedFileCount: Int?, unlimitedFileSize: Int?, isTotalSizePartial: Bool, isTotalFilePartial: Bool, isPartial: Bool) {
        self.compressionName = compressionName
        self.mainFile = archive
        self.unlimitedFileCount = unlimitedFileCount ?? archive.totalFilesCount
        self.unlimitedFileSize = unlimitedFileSize ?? archive.totalFilesSize
        self.isTotalSizePartial = isTotalSizePartial
        self.isTotalFilePartial = isTotalFilePartial
        self.isPartial = isPartial
        super.init(file: file)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.compressionName = try container.decode(String.self, forKey: .compressionName)
        self.unlimitedFileCount = try container.decode(Int.self, forKey: .unlimitedFileCount)
        self.unlimitedFileSize = try container.decode(Int.self, forKey: .unlimitedFileSize)
        self.isTotalSizePartial = try container.decode(Bool.self, forKey: .partialTotalSize)
        self.isTotalFilePartial = try container.decode(Bool.self, forKey: .partialTotalFile)
        self.mainFile = try container.decode(ArchivedFile.self, forKey: .archive)
        self.isPartial = try container.decode(Bool.self, forKey: .partial)
        try super.init(from: decoder)
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.compressionName, forKey: .compressionName)
        try container.encode(self.unlimitedFileCount, forKey: .unlimitedFileCount)
        try container.encode(self.unlimitedFileSize, forKey: .unlimitedFileSize)
        try container.encode(self.isTotalSizePartial, forKey: .partialTotalSize)
        try container.encode(self.isTotalFilePartial, forKey: .partialTotalFile)
        try container.encode(self.mainFile, forKey: .archive)
        try container.encode(self.isPartial, forKey: .partial)
    }

    // MARK: -
    override internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        if let s = self.processFilesPlaceholder(placeholder, isFilled: &isFilled, forItem: item) {
            return s
        } else {
            let useEmptyData = !(self.globalSettings?.isEmptyItemsSkipped ?? true)
            switch placeholder {
            case "[[compression-format]]":
                isFilled = !self.compressionName.isEmpty && self.compressionName != "none"
                return self.compressionName
            case "[[uncompressed-size]]":
                isFilled = self.unlimitedFileSize > 0
                if self.unlimitedFileSize < 0 {
                    return NSLocalizedString("unknown uncompressed size", tableName: "LocalizableExt", comment: "")
                } else if self.isTotalSizePartial {
                    Self.byteCountFormatter.countStyle = (self.globalSettings?.bytesFormat ?? .standard).countStyle
                    return String(format: NSLocalizedString("more than %@ uncompressed", tableName: "LocalizableExt", comment: ""), Self.byteCountFormatter.string(fromByteCount: Int64(self.unlimitedFileSize)))
                } else {
                    Self.byteCountFormatter.countStyle = (self.globalSettings?.bytesFormat ?? .standard).countStyle
                    return String(format: NSLocalizedString("%@ uncompressed", tableName: "LocalizableExt", comment: ""), Self.byteCountFormatter.string(fromByteCount: Int64(self.unlimitedFileSize)))
                }
            case "[[compression-ratio]]":
                if self.unlimitedFileSize <= 0 || self.isTotalSizePartial {
                    isFilled = false
                    return self.formatND(useEmptyData: useEmptyData)
                } else {
                    let ratio = Double(self.unlimitedFileSize) / Double(self.fileSize)
                    if let p = Self.percentFormatter.string(from: ratio as NSNumber) {
                        isFilled = true
                        return p
                    } else {
                        isFilled = false
                        return self.formatERR(useEmptyData: useEmptyData)
                    }
                }
            case "[[compression-summary]]":
                var s = self.processPlaceholder("[[file-size]]", isFilled: &isFilled, forItem: item)
                s += " = "
                s += self.processPlaceholder("[[uncompressed-size]]", isFilled: &isFilled, forItem: item)
                let ratio = self.processPlaceholder("[[compression-ratio]]", isFilled: &isFilled, forItem: item)
                if isFilled {
                    s += " (\(ratio))"
                }
                isFilled = true
                return s
            default:
                return super.processPlaceholder(placeholder, isFilled: &isFilled, forItem: item)
            }
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        switch item.menuItem.template {
        case "[[files]]", "[[files-with-icon]]", "[[files-plain]]", "[[files-plain-with-icon]]":
            guard !self.mainFile.files.isEmpty else {
                return true
            }
            
            let show_icons = item.menuItem.template == "[[files-with-icon]]" || item.menuItem.template == "[[files-plain-with-icon]]"
            let plain = item.menuItem.template == "[[files-plain]]" || item.menuItem.template == "[[files-plain-with-icon]]"
            
            let title = self.formatFilesTitle()
            
            let submenu = format_files(
                title: title,
                files: mainFile.files,
                isPartial: mainFile.isPartial,
                icons: show_icons,
                plain: plain,
                depth: 0,
                maxDepth: 0,
                maxFilesInDepth: 0,
                allowBundle: false,
                sortFoldersFirst: (self.currentSettings as? Settings.ArchiveSettings)?.sortFoldersFirst ?? false,
                item: item,
                fileAction: .standard
            )
            if self.mainFile.files.count == 1 && !plain {
                let mnu = submenu.items.first!.copy(with: .none) as! NSMenuItem
                destination_sub_menu.addItem(mnu)
            } else {
                let mnu = self.createMenuItem(title: title, image: self.standardMainItem.menuItem.image, representedObject: item)
                destination_sub_menu.addItem(mnu)
                destination_sub_menu.setSubmenu(submenu, for: mnu)
            }
            
            return true
        default:
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu)
        }
    }
}
