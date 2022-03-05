//
//  FileInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 24/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Cocoa

// MARK: -
class FileInfo: BaseInfo {
    enum FileCodingKeys: String, CodingKey {
        case fileUrl
        case fileSize
        case filePath
        case fileName
        case fileExtension
        case fileCreationDate
        case fileModificationDate
        case fileAccessDate
    }
    
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        
        return formatter
    }
    
    static func getFileInfo(_ file: URL) -> (Int64, Date, Date, Date)? {
        var output: stat = stat()
        guard stat(file.path, &output) == 0 else {
            return nil
        }
        let fileSize: Int64 = output.st_size
        let c = Date(timeIntervalSince1970: TimeInterval(output.st_ctimespec.tv_sec))
        let m = Date(timeIntervalSince1970: TimeInterval(output.st_mtimespec.tv_sec))
        let a = Date(timeIntervalSince1970: TimeInterval(output.st_atimespec.tv_sec))
        return (fileSize, c, m, a)
    }
    
    var file: URL
    var fileSize: Int64
    var fileCreationDate: Date?
    var fileModificationDate: Date?
    var fileAccessDate: Date?
    
    init(file: URL) {
        self.file = file
        let info = Self.getFileInfo(file)
        self.fileSize = info?.0 ?? -1
        self.fileCreationDate = info?.1
        self.fileModificationDate = info?.2
        self.fileAccessDate = info?.3
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FileCodingKeys.self)
        self.file = try container.decode(URL.self, forKey: .fileUrl)
        self.fileSize = try container.decode(Int64.self, forKey: .fileSize)
        self.fileCreationDate = try container.decode(Date.self, forKey: .fileCreationDate)
        self.fileModificationDate = try container.decode(Date.self, forKey: .fileModificationDate)
        self.fileAccessDate = try container.decode(Date.self, forKey: .fileAccessDate)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FileCodingKeys.self)
        try container.encode(self.file, forKey: .fileUrl)
        try container.encode(self.fileSize, forKey: .fileSize)
        
        try container.encode(self.fileCreationDate, forKey: .fileCreationDate)
        try container.encode(self.fileModificationDate, forKey: .fileModificationDate)
        try container.encode(self.fileAccessDate, forKey: .fileAccessDate)
        
        if let b = encoder.userInfo[.exportStoredValues] as? Bool, b {
            try container.encode(self.file.path, forKey: .filePath)
            try container.encode(self.file.lastPathComponent, forKey: .fileName)
            try container.encode(self.file.pathExtension, forKey: .fileExtension)
        }
        
        try super.encode(to: encoder)
    }
    
    override func getImage(for name: String) -> NSImage? {
        if name == "target-icon" {
            return NSWorkspace.shared.icon(forFile: self.file.path).resized(to: NSSize(width: 16, height: 16))
        } else {
            return super.getImage(for: name)
        }
    }
    
    override internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        let useEmptyData = !settings.isEmptyItemsSkipped
        
        switch placeholder {
        case "[[filesize]]":
            isFilled = self.fileSize > 0
            return self.fileSize >= 0 ? Self.byteCountFormatter.string(fromByteCount: fileSize) : self.formatND(useEmptyData: useEmptyData)
        case "[[file-name]]":
            isFilled = true
            return self.file.lastPathComponent
        case "[[file-ext]]":
            isFilled = true
            return self.file.pathExtension
        case "[[file-cdate]]":
            isFilled = self.fileCreationDate != nil
            return self.fileCreationDate == nil ? self.formatND(useEmptyData: useEmptyData) : Self.dateFormatter.string(from: self.fileCreationDate!)
        case "[[file-mdate]]":
            isFilled = self.fileModificationDate != nil
            return self.fileModificationDate == nil ? self.formatND(useEmptyData: useEmptyData) : Self.dateFormatter.string(from: self.fileModificationDate!)
        case "[[file-adate]]":
            isFilled = self.fileAccessDate != nil
            return self.fileAccessDate == nil ? self.formatND(useEmptyData: useEmptyData) : Self.dateFormatter.string(from: self.fileAccessDate!)
        default:
            return super.processPlaceholder(placeholder, settings: settings, isFilled: &isFilled, forItem: item)
        }
    }
    
    override internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.menuItem.template.hasPrefix("[[open-with:") {
            guard let path = String(item.menuItem.template.dropFirst(12).dropLast(2)).fromBase64(), !path.isEmpty else {
                return true
            }
            let title = String(format: NSLocalizedString("Open with %@…", tableName: "LocalizableExt", comment: ""), FileManager.default.displayName(atPath: path))
            let mnu = self.createMenuItem(title: title, image: item.menuItem.image, settings: settings, representedObject: item)
            if let info = mnu.representedObject as? MenuItemInfo {
                var info2 = info
                info2.action = .openWith
                info2.userInfo["application"] = path
                mnu.representedObject = info2
            }
            if !settings.isIconHidden && item.menuItem.image.isEmpty {
                let img = NSWorkspace.shared.icon(forFile: path).resized(to: NSSize(width: 16, height: 16))
                mnu.image = img
            }
            mnu.toolTip = path
            destination_sub_menu.addItem(mnu)
            return true
        } else if item.menuItem.template.hasPrefix("[[open-with-default]]") {
            let title: String
            let path: String
            if let url = NSWorkspace.shared.urlForApplication(toOpen: self.file) {
                path = url.path
                title = String(format: NSLocalizedString("Open with %@…", tableName: "LocalizableExt", comment: ""), FileManager.default.displayName(atPath: path))
            } else {
                title = NSLocalizedString("Open…", tableName: "LocalizableExt", comment: "")
                path = ""
            }
            let mnu = self.createMenuItem(title: title, image: item.menuItem.image, settings: settings, representedObject: item)
            if let info = mnu.representedObject as? MenuItemInfo {
                var info2 = info
                info2.action = .open
                mnu.representedObject = info2
            }
            if !settings.isIconHidden && item.menuItem.image.isEmpty && !path.isEmpty {
                let img = NSWorkspace.shared.icon(forFile: path).resized(to: NSSize(width: 16, height: 16))
                mnu.image = img
            }
            mnu.toolTip = path
            destination_sub_menu.addItem(mnu)
            return true
        } else if item.menuItem.template == "[[clipboard]]" {
            let mnu = self.createMenuItem(title: NSLocalizedString("Copy path to the clipboard", tableName: "LocalizableExt", comment: ""), image: item.menuItem.image, settings: settings, representedObject: item)
            if let info = mnu.representedObject as? MenuItemInfo {
                var info2 = info
                info2.action = .clipboard
                mnu.representedObject = info2
            }
            destination_sub_menu.addItem(mnu)
            return true
        } else {
            return super.processSpecialMenuItem(item, inMenu: destination_sub_menu, withSettings: settings)
        }
    }
}
