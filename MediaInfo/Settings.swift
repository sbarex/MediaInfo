//
//  Settings.swift
//  MediaInfo
//
//  Created by Sbarex on 04/09/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import UniformTypeIdentifiers

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

enum PrintUnit: Int, CaseIterable {
    case cm = 1
    case mm
    case inch
    
    init?(placeholder: String) {
        switch placeholder {
        case "cm": self = .cm
        case "mm": self = .mm
        case "in": self = .inch
        default: return nil
        }
    }
    
    var placeholder: String {
        switch self {
        case .cm:
            return "cm"
        case .mm:
            return "mm"
        case .inch:
            return "in"
        }
    }
    
    var scale: Double {
        switch self {
        case .cm:
            return 2.54 // cm
        case .mm:
            return 25.4 // mm
        case .inch:
            return 1
        }
    }
    
    var label: String {
        switch self {
        case .cm:
            return NSLocalizedString("cm", tableName: "LocalizableExt", comment: "")
        case .mm:
            return NSLocalizedString("mm", tableName: "LocalizableExt", comment: "")
        case .inch:
            return NSLocalizedString("inch", tableName: "LocalizableExt", comment: "")
        }
    }
}

class Settings: Codable {
    enum CodingKeys: String, CodingKey {
        case folders
        case handleExternalDisk
        case version
        case iconsHidden
        case infoOnSubMenu
        case infoOnMainItem
        case useFirstItemAsMain
        case isRatioPrecise
        case bytesFormat
        case bitsFormat
        case skipEmpty
        
        case imageSettings
        case videoSettings
        case videoTrackSettings
        case audioTrackSettings
        case audioSettings
        case pdfSettings
        case officeSettings
        case modelSettings
        case archiveSettings
        case folderSettings

        case customFormats
        case otherFormats
        
        case menuAction
        case engines
        
        case metadataExpanded
    }
    
    enum BytesFormat: Int, Codable {
        case decimal = 0
        case binary = 1
        case standard = 2
        
        var countStyle: ByteCountFormatter.CountStyle {
            switch self {
            case .decimal:
                return .decimal
            case .binary:
                return .binary
            case .standard:
                return .file
            }
        }
    }
    
    enum BitsFormat: Int, Codable {
        case decimal = 0
        case binary = 1
    }
    
    enum MediaEngine: Int, Codable {
        case coremedia
        case ffmpeg
        case metadata
        
        var label: String {
            switch self {
            case .coremedia: return "Core Media engine"
            case .ffmpeg: return "FFMpeg engine"
            case .metadata: return "Metadata engine"
            }
        }
    }
    
    struct MenuItem: Codable, Hashable {
        enum CodingKeys: String, CodingKey {
            case image
            case template
        }
        
        var image: String
        var template: String
        
        init(image: String, template: String) {
            self.image = image
            self.template = template
        }
        
        init?(from dict: [String: AnyHashable]) {
            guard let image = dict[CodingKeys.image.rawValue] as? String else {
                return nil
            }
            guard let template = dict[CodingKeys.template.rawValue] as? String else {
                return nil
            }
            self.image = image
            self.template = template
        }
        
        func toDictionary() -> [String: AnyHashable] {
            return [
                CodingKeys.image.rawValue: self.image,
                CodingKeys.template.rawValue: self.template
            ]
        }
    }
    
    class Trigger: Codable {
        enum CodingKeys: String, CodingKey {
            case code
            case enabled
        }
        
        var code: String
        var isEnabled: Bool
        
        var isActive: Bool {
            return isEnabled && !code.isEmpty
        }
        
        convenience init(code: String) {
            self.init(code: code, isEnabled: !code.isEmpty)
        }
        
        init(code: String, isEnabled: Bool) {
            self.code = code
            self.isEnabled = isEnabled
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.code = try container.decode(String.self, forKey: .code)
            self.isEnabled = try container.decode(Bool.self, forKey: .enabled)
        }
        
        init?(from dict: [String: AnyHashable]) {
            guard let code = dict[CodingKeys.code.rawValue] as? String else {
                return nil
            }
            self.code = code
            guard let enabled = dict[CodingKeys.enabled.rawValue] as? Bool else {
                return nil
            }
            self.isEnabled = enabled
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.code, forKey: .code)
            try container.encode(self.isEnabled, forKey: .enabled)
        }
        
        func toDictionary() -> [String: AnyHashable] {
            return [
                CodingKeys.code.rawValue: self.code,
                CodingKeys.enabled.rawValue: self.isEnabled,
            ]
        }
        
        func update(from dict: [String: AnyHashable]) {
            if let code = dict[CodingKeys.code.rawValue] as? String {
                self.code = code
            }
            if let enabled = dict[CodingKeys.enabled.rawValue] as? Bool {
                self.isEnabled = enabled
            }
        }
        
        func copy() -> Trigger {
            return Trigger(code: self.code, isEnabled: self.isEnabled)
        }
    }
    
    enum TriggerName: String, CaseIterable, Codable {
        case validate
        case beforeRender
        case action
        
        var tag: Int {
            switch self {
            case .validate:
                return 1
            case .beforeRender:
                return 2
            case .action:
                return 3
            }
        }
        
        init?(rawValue: Int) {
            switch rawValue {
            case 1: self = .validate
            case 2: self = .beforeRender
            case 3: self = .action
            default: return nil
            }
        }
    }
    
    class FormatSettings: Codable {
        enum CodingKeys: String, CodingKey {
            case enabled
            case templates
            case triggers
        }
        var isEnabled: Bool
        var templates: [MenuItem]
        var triggers: [TriggerName: Trigger]
        
        var allowTriggers: Bool {
            return true
        }
        
        required init?(from dict: [String: AnyHashable]) {
            guard let enabled = dict[CodingKeys.enabled.rawValue] as? Bool else {
                return nil
            }
            self.isEnabled = enabled
            
            self.templates = []
            guard let templates = dict[CodingKeys.templates.rawValue] as? [[String: AnyHashable]] else {
                return nil
            }
            for template in templates {
                if let item = MenuItem(from: template) {
                    self.templates.append(item)
                }
            }
            self.triggers = [:]
            if let triggers = dict["triggers"] as? [String: [String: AnyHashable]] {
                for t in triggers {
                    if let name = TriggerName(rawValue: t.key), let trigger = Trigger(from: t.value) {
                        self.triggers[name] = trigger
                    }
                }
                
            }
        }
        
        init(isEnabled: Bool, templates: [MenuItem], triggers: [TriggerName: Trigger]) {
            self.isEnabled = isEnabled
            self.templates = templates
            self.triggers = triggers
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.isEnabled = try container.decode(Bool.self, forKey: .enabled)
            self.templates = try container.decode([MenuItem].self, forKey: .templates)
            self.triggers = try container.decode([TriggerName: Trigger].self, forKey: .triggers)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.isEnabled, forKey: .enabled)
            try container.encode(self.templates, forKey: .templates)
            if allowTriggers {
                try container.encode(self.triggers.filter({$0.value.isActive}), forKey: .triggers)
            }
        }
        
        func copy() -> Self? {
            return Self.init(from: self.toDictionary())
        }
        
        func toDictionary() -> [String: AnyHashable] {
            var r: [String: AnyHashable] = [
                CodingKeys.enabled.rawValue: self.isEnabled,
                CodingKeys.templates.rawValue: self.templates.map({ $0.toDictionary() })
            ]
            if allowTriggers {
                var triggers: [String: [String: AnyHashable]] = [:]
                for trigger in self.triggers.filter({$0.value.isActive}) {
                    triggers[trigger.key.rawValue] = trigger.value.toDictionary()
                }
                r[CodingKeys.triggers.rawValue] = triggers
            }
            return r
        }
        
        func update(from dict: [String: AnyHashable]) {
            if let enabled = dict[CodingKeys.enabled.rawValue] as? Bool {
                self.isEnabled = enabled
            }
            if let templates = dict[CodingKeys.templates.rawValue] as? [[String: AnyHashable]] {
                self.templates = []
                for template in templates {
                    if let item = MenuItem(from: template) {
                        self.templates.append(item)
                    }
                }
            }
            if let triggers = dict[CodingKeys.triggers.rawValue] as? [String: [String: AnyHashable]] {
                var trigger_names: [TriggerName] = []
                for t in triggers {
                    guard let name = TriggerName(rawValue: t.key) else {
                        continue
                    }
                    if let trigger = self.triggers[name] {
                        trigger.update(from: t.value)
                    } else if let trigger = Trigger(from: t.value) {
                        self.triggers[name] = trigger
                    }
                    trigger_names.append(name)
                }
                var trigger_del_names: [TriggerName] = []
                for name in self.triggers.keys {
                    if !trigger_names.contains(name) {
                        trigger_del_names.append(name)
                    }
                }
                for name in trigger_del_names {
                    self.triggers.removeValue(forKey: name)
                }
            }
        }
        
        func migrateTriggers() {
            if let item = self.templates.first(where: { $0.template.hasPrefix("[[script-action:") }) {
                if let code = String(item.template.dropFirst(16).dropLast(2)).fromBase64() {
                    self.triggers[.action] = Trigger(code: code)
                }
            }
            while let i = self.templates.firstIndex(where: { $0.template.hasPrefix("[[script-action:") }) {
                self.templates.remove(at: i)
            }
        }
        
        func hasActiveTrigger(_ name: TriggerName) -> Bool {
            guard let trigger = self.triggers[name] else {
                return false
            }
            return trigger.isActive
        }
    }
    
    class ImageSettings: FormatSettings {
        enum CodingKeys: String, CodingKey {
            case metadata
        }
        var extractMetadata: Bool
        
        init(isEnabled: Bool, templates: [MenuItem], triggers: [TriggerName: Trigger], extractMetadata: Bool) {
            self.extractMetadata = extractMetadata
            super.init(isEnabled: isEnabled, templates: templates, triggers: triggers)
        }
        
        required init?(from dict: [String: AnyHashable]) {
            guard let metadata = dict[CodingKeys.metadata.rawValue] as? Bool else {
                return nil
            }
            self.extractMetadata = metadata
            super.init(from: dict)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.extractMetadata = try container.decode(Bool.self, forKey: .metadata)
            try super.init(from: decoder)
        }
        
        override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.extractMetadata, forKey: .metadata)
            try super.encode(to: encoder)
        }
        
        override func toDictionary() -> [String : AnyHashable] {
            var r = super.toDictionary()
            r[CodingKeys.metadata.rawValue] = self.extractMetadata
            return r
        }
        
        override func update(from dict: [String: AnyHashable]) {
            super.update(from: dict)
            if let metadata = dict[CodingKeys.metadata.rawValue] as? Bool {
                self.extractMetadata = metadata
            }
        }
    }
    
    class VideoSettings: FormatSettings {
        enum CodingKeys: String, CodingKey {
            case groupTracks
        }
        var groupTracks: Bool
        
        init(isEnabled: Bool, templates: [MenuItem], triggers: [TriggerName: Trigger], groupTracks: Bool) {
            self.groupTracks = groupTracks
            super.init(isEnabled: isEnabled, templates: templates, triggers: triggers)
        }
        
        required init?(from dict: [String: AnyHashable]) {
            guard let groupTracks = dict[CodingKeys.groupTracks.rawValue] as? Bool else {
                return nil
            }
            self.groupTracks = groupTracks
            super.init(from: dict)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.groupTracks = try container.decode(Bool.self, forKey: .groupTracks)
            try super.init(from: decoder)
        }
        
        override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.groupTracks, forKey: .groupTracks)
            try super.encode(to: encoder)
        }
        
        override func toDictionary() -> [String : AnyHashable] {
            var r = super.toDictionary()
            r[CodingKeys.groupTracks.rawValue] = self.groupTracks
            return r
        }
        
        override func update(from dict: [String: AnyHashable]) {
            super.update(from: dict)
            if let groupTracks = dict[CodingKeys.groupTracks.rawValue] as? Bool {
                self.groupTracks = groupTracks
            }
        }
    }
    
    class MediaTrackSettings: FormatSettings {
        override var allowTriggers: Bool {
            return false
        }
    }
    
    class OfficeSettings: FormatSettings {
        enum CodingKeys: String, CodingKey {
            case deepScan
        }
        var deepScan: Bool
        
        init(isEnabled: Bool, templates: [MenuItem], triggers: [TriggerName: Trigger], deepScan: Bool) {
            self.deepScan = deepScan
            super.init(isEnabled: isEnabled, templates: templates, triggers: triggers)
        }
        
        required init?(from dict: [String: AnyHashable]) {
            guard let deepScan = dict[CodingKeys.deepScan.rawValue] as? Bool else {
                return nil
            }
            self.deepScan = deepScan
            super.init(from: dict)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.deepScan = try container.decode(Bool.self, forKey: .deepScan)
            try super.init(from: decoder)
        }
        
        override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.deepScan, forKey: .deepScan)
            try super.encode(to: encoder)
        }
        
        override func toDictionary() -> [String : AnyHashable] {
            var r = super.toDictionary()
            r[CodingKeys.deepScan.rawValue] = self.deepScan
            return r
        }
        
        override func update(from dict: [String: AnyHashable]) {
            super.update(from: dict)
            if let deepScan = dict[CodingKeys.deepScan.rawValue] as? Bool {
                self.deepScan = deepScan
            }
        }
    }
    
    class ArchiveSettings: FormatSettings {
        enum CodingKeys: String, CodingKey {
            case maxFiles
        }
        var maxFiles: Int
        
        var sortFoldersFirst: Bool {
            let d = UserDefaults(suiteName: "com.apple.finder")
            return d?.bool(forKey: "_FXSortFoldersFirst") ?? false
        }
        
        init(isEnabled: Bool, templates: [MenuItem], triggers: [TriggerName: Trigger], maxFiles: Int) {
            self.maxFiles = maxFiles
            super.init(isEnabled: isEnabled, templates: templates, triggers: triggers)
        }
        
        required init?(from dict: [String: AnyHashable]) {
            guard let maxFiles = dict[CodingKeys.maxFiles.rawValue] as? Int else {
                return nil
            }
            self.maxFiles = maxFiles
            super.init(from: dict)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.maxFiles = try container.decode(Int.self, forKey: .maxFiles)
            try super.init(from: decoder)
        }
        
        override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.maxFiles, forKey: .maxFiles)
            try super.encode(to: encoder)
        }
        
        override func toDictionary() -> [String : AnyHashable] {
            var r = super.toDictionary()
            r[CodingKeys.maxFiles.rawValue] = maxFiles
            return r
        }
        
        override func update(from dict: [String: AnyHashable]) {
            super.update(from: dict)
            if let maxFiles = dict[CodingKeys.maxFiles.rawValue] as? Int {
                self.maxFiles = maxFiles
            }
        }
    }
    
    class FolderSettings: FormatSettings {
        enum CodingKeys: String, CodingKey {
            case maxFiles
            case maxDepth
            case maxFilesInDepth
            case bundle
            case skipHidden
            case genericIcon
            case action
            case sizeMethod
        }
        var maxFiles: Int
        var maxDepth: Int
        var maxFilesInDepth: Int
        var isBundleEnabled: Bool
        var skipHiddenFiles: Bool
        var usesGenericIcon: Bool
        var action: FolderAction = .revealFile
        var sizeMethod: FolderSizeMethod = .fast
        
        var sortFoldersFirst: Bool {
            let d = UserDefaults(suiteName: "com.apple.finder")
            return d?.bool(forKey: "_FXSortFoldersFirst") ?? false
        }
        
        init(isEnabled: Bool, isBundleEnabled: Bool, templates: [MenuItem], triggers: [TriggerName: Trigger], maxFiles: Int, maxDepth: Int, maxFilesInDepth: Int, skipHiddenFiles: Bool, usesGenericIcon: Bool, action: FolderAction, sizeMethod: FolderSizeMethod) {
            self.isBundleEnabled = isBundleEnabled
            self.maxFiles = maxFiles
            self.maxDepth = maxDepth
            self.maxFilesInDepth = maxFilesInDepth
            self.skipHiddenFiles = skipHiddenFiles
            self.usesGenericIcon = usesGenericIcon
            self.action = action
            self.sizeMethod = sizeMethod
            super.init(isEnabled: isEnabled, templates: templates, triggers: triggers)
        }
        
        required init?(from dict: [String: AnyHashable]) {
            guard let maxFiles = dict[CodingKeys.maxFiles.rawValue] as? Int else {
                return nil
            }
            guard let maxDepth = dict[CodingKeys.maxDepth.rawValue] as? Int else {
                return nil
            }
            guard let maxFilesInDepth = dict[CodingKeys.maxFilesInDepth.rawValue] as? Int else {
                return nil
            }
            guard let isBundleEnabled = dict[CodingKeys.bundle.rawValue] as? Bool else {
                return nil
            }
            guard let skipHiddenFiles = dict[CodingKeys.skipHidden.rawValue] as? Bool else {
                return nil
            }
            guard let usesGenericIcon = dict[CodingKeys.genericIcon.rawValue] as? Bool else {
                return nil
            }
            guard let a = dict[CodingKeys.action.rawValue] as? Int, let action = FolderAction(rawValue: a) else {
                return nil
            }
            guard let s = dict[CodingKeys.sizeMethod.rawValue] as? Int, let sizeMethod = FolderSizeMethod(rawValue: s) else {
                return nil
            }
            self.maxFiles = maxFiles
            self.maxDepth = maxDepth
            self.maxFilesInDepth = maxFilesInDepth
            self.isBundleEnabled = isBundleEnabled
            self.skipHiddenFiles = skipHiddenFiles
            self.usesGenericIcon = usesGenericIcon
            self.action = action
            self.sizeMethod = sizeMethod
            
            super.init(from: dict)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.maxFiles = try container.decode(Int.self, forKey: .maxFiles)
            self.maxDepth = try container.decode(Int.self, forKey: .maxDepth)
            self.maxFilesInDepth = try container.decode(Int.self, forKey: .maxFilesInDepth)
            self.isBundleEnabled = try container.decode(Bool.self, forKey: .bundle)
            self.skipHiddenFiles = try container.decode(Bool.self, forKey: .skipHidden)
            self.usesGenericIcon = try container.decode(Bool.self, forKey: .genericIcon)
            self.action = try container.decode(FolderAction.self, forKey: .action)
            self.sizeMethod = try container.decode(FolderSizeMethod.self, forKey: .sizeMethod)
            
            try super.init(from: decoder)
        }
        
        override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.maxFiles, forKey: .maxFiles)
            try container.encode(self.maxDepth, forKey: .maxDepth)
            try container.encode(self.maxFilesInDepth, forKey: .maxFilesInDepth)
            try container.encode(self.isBundleEnabled, forKey: .bundle)
            try container.encode(self.skipHiddenFiles, forKey: .skipHidden)
            try container.encode(self.usesGenericIcon, forKey: .genericIcon)
            try container.encode(self.action, forKey: .action)
            try container.encode(self.sizeMethod, forKey: .sizeMethod)
            
            try super.encode(to: encoder)
        }
        
        override func toDictionary() -> [String : AnyHashable] {
            var r = super.toDictionary()
            r[CodingKeys.maxFiles.rawValue] = self.maxFiles
            r[CodingKeys.maxDepth.rawValue] = self.maxDepth
            r[CodingKeys.maxFilesInDepth.rawValue] = self.maxFilesInDepth
            r[CodingKeys.bundle.rawValue] = self.isBundleEnabled
            r[CodingKeys.skipHidden.rawValue] = self.skipHiddenFiles
            r[CodingKeys.genericIcon.rawValue] = self.usesGenericIcon
            r[CodingKeys.action.rawValue] = self.action.rawValue
            r[CodingKeys.sizeMethod.rawValue] = self.sizeMethod.rawValue
            return r
        }
        
        override func update(from dict: [String: AnyHashable]) {
            super.update(from: dict)
            if let maxFiles = dict[CodingKeys.maxFiles.rawValue] as? Int {
                self.maxFiles = maxFiles
            }
            if let maxDepth = dict[CodingKeys.maxDepth.rawValue] as? Int {
                self.maxDepth = maxDepth
            }
            if let maxFilesInDepth = dict[CodingKeys.maxFilesInDepth.rawValue] as? Int {
                self.maxFilesInDepth = maxFilesInDepth
            }
            if let isBundleEnabled = dict[CodingKeys.bundle.rawValue] as? Bool {
                self.isBundleEnabled = isBundleEnabled
            }
            if let skipHiddenFiles = dict[CodingKeys.skipHidden.rawValue] as? Bool {
                self.skipHiddenFiles = skipHiddenFiles
            }
            if let usesGenericIcon = dict[CodingKeys.genericIcon.rawValue] as? Bool {
                self.usesGenericIcon = usesGenericIcon
            }
            if let a = dict[CodingKeys.action.rawValue] as? Int, let action = FolderAction(rawValue: a) {
                self.action = action
            }
            if let s = dict[CodingKeys.sizeMethod.rawValue] as? Int, let sizeMethod = FolderSizeMethod(rawValue: s) {
                self.sizeMethod = sizeMethod
            }
        }
    }
    
    class CustomFormatSettings: FormatSettings {
        enum CodingKeys: String, CodingKey {
            case uti
        }
        
        var uti: String
        var associatedExtension: String? {
            if #available(macOS 11.0, *) {
                if let uti = UTType(uti) {
                    return uti.preferredFilenameExtension
                } else {
                    return nil
                }
            } else {
                let r = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue()
                return r as? String
            }
        }
        var conformsToUTI: [String] {
            if #available(macOS 11.0, *) {
                if let u = UTType(uti) {
                    return u.supertypes.map({ $0.identifier })
                }
            } else {
                if let unmanaged = UTTypeCopyDeclaration(uti as CFString), let dict = (unmanaged.takeRetainedValue() as NSDictionary) as? [String: AnyObject], let types = dict[kUTTypeConformsToKey as String] as? [String] {
                    return types
                }
            }
            return []
        }
        
        var icon: NSImage? {
            if #available(macOS 11.0, *) {
                if let uti_type = UTType(uti) {
                    return NSWorkspace.shared.icon(for: uti_type)
                } else {
                    return nil
                }
            } else {
                return NSWorkspace.shared.icon(forFileType: uti)
            }
        }
        
        init(uti: String, templates: [MenuItem], triggers: [TriggerName: Trigger]) {
            self.uti = uti
            super.init(isEnabled: true, templates: templates, triggers: triggers)
        }
        
        required init?(from dict: [String: AnyHashable]) {
            guard let uti = dict[CodingKeys.uti.rawValue] as? String else {
                return nil
            }
            self.uti = uti
            super.init(from: dict)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.uti = try container.decode(String.self, forKey: .uti)
            try super.init(from: decoder)
        }
        
        override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.uti, forKey: .uti)
            try super.encode(to: encoder)
        }
        
        override func toDictionary() -> [String : AnyHashable] {
            var r = super.toDictionary()
            r[CodingKeys.uti.rawValue] = self.uti
            return r
        }
        
        override func update(from dict: [String: AnyHashable]) {
            super.update(from: dict)
            if let uti = dict[CodingKeys.uti.rawValue] as? String {
                self.uti = uti
            }
        }
    }
    
    enum Action: Int, Codable {
        case none = 0
        case open
    }
    
    enum FolderSizeMethod: Int, Codable {
        case none
        case fast
        case full
    }
    
    enum FolderAction: Int, Codable {
        case standard = 0
        case openFile
        case revealFile
    }
    
    enum SupportedFile: Int, Codable, CaseIterable {
        case none = 0
        case image
        case video
        case audio
        case office
        case pdf
        case archive
        case model
        case folder
        
        case videoTrakcs
        case audioTraks
        
        case others
    }
    
    static let Version: Double = 2.0
    /// Maximum time (in seconds) to complete the execution of a synchronous task
    static let execSyncTimeout: Double = 2
    /// Maximum time (in seconds) to complete the analysis of a file
    static let infoExtractionTimeout: Double = 2
    
    static func getStandardSettings() -> Settings {
        let settings = Settings()
    
        settings.version = Self.Version
        settings.imageSettings.templates = [
            MenuItem(image: "image", template: "[[size]], [[color-depth]] [[is-animated]]"),
            MenuItem(image: "ratio", template: "[[ratio]], [[resolution]]"),
            MenuItem(image: "color", template: "[[color-depth]], [[is-alpha]], [[color-table]], [[profile-name]]"),
            MenuItem(image: "printer", template: "[[dpi]]"),
            MenuItem(image: "printer", template: "[[print:cm]]"),
            MenuItem(image: "printer", template: "[[print:cm:300]]"),
            MenuItem(image: "printer", template: "[[paper]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[file-size]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        settings.videoSettings.templates = [
            MenuItem(image: "video", template: "[[size]], [[duration]], [[fps]] ([[languages-flag]])"),
            MenuItem(image: "ratio", template: "[[ratio]], [[resolution]]"),
            MenuItem(image: "video", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "", template: "[[frames]]"),
            MenuItem(image: "tag", template: "[[title]]"),
            MenuItem(image: "video", template: "[[video]]"),
            MenuItem(image: "audio", template: "[[audio]]"),
            MenuItem(image: "txt", template: "[[subtitles]]"),
            MenuItem(image: "chapters", template: "[[chapters]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[file-size]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        settings.videoTrackSettings.templates = [
            MenuItem(image: "video", template: "[[size]], [[duration]], [[fps]] ([[language-flag]])"),
            MenuItem(image: "ratio", template: "[[ratio]], [[resolution]]"),
            MenuItem(image: "video", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "", template: "[[frames]]"),
            MenuItem(image: "tag", template: "[[title]]"),
        ]
        settings.audioTrackSettings.templates = [
            MenuItem(image: "audio", template: "[[duration]] ([[seconds]]) [[channels-name]] [[language-flag]]"),
            MenuItem(image: "audio", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "tag", template: "[[title]]"),
        ]
        
        settings.audioSettings.templates = [
            MenuItem(image: "audio", template: "[[duration]] ([[seconds]]) [[channels-name]] [[language-flag]]"),
            MenuItem(image: "audio", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "tag", template: "[[title]]"),
            MenuItem(image: "", template: "([[engine]])"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[file-size]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.pdfSettings.templates = [
            MenuItem(image: "pdf", template: "[[mediabox:paper:cm]], [[pages]] [[security]]"),
            MenuItem(image: "pages", template: "[[pages]]"),
            MenuItem(image: "page", template: "Media box: [[mediabox:mm]], [[mediabox:paper]]"),
            MenuItem(image: "crop", template: "Crop box: [[cropbox:mm]], [[cropbox:paper]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "tag", template: "[[title]]"),
            MenuItem(image: "person", template: "Author: [[author]]"),
            MenuItem(image: "", template: "Creathor: [[creathor]]"),
            MenuItem(image: "", template: "Application: [[producer]]"),
            MenuItem(image: "shield", template: "[[version]], [[security]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[file-size]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.officeSettings.templates = [
            MenuItem(image: "office", template: "[[size:paper:cm]], [[title]], [[pages]]"),
            MenuItem(image: "tag", template: "subject: [[subject]]"),
            MenuItem(image: "person", template: "[[creation]]"),
            MenuItem(image: "pencil", template: "[[last-modification]]"),
            MenuItem(image: "pages", template: "[[pages]]"),
            MenuItem(image: "abc", template: "[[words]], [[characters-space]]"),
            MenuItem(image: "", template: "[[keywords]]"),
            MenuItem(image: "", template: "([[application]])"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[file-size]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.modelSettings.templates = [
            MenuItem(image: "3d", template: "[[mesh]], [[vertex]]"),
            MenuItem(image: "3d", template: "[[normal]], [[tangent]]"),
            MenuItem(image: "3d", template: "[[texture-coords]]"),
            MenuItem(image: "3d", template: "[[colors]], [[occlusion]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[file-size]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.archiveSettings.templates = [
            MenuItem(image: "zip", template: "[[compression-summary]], [[n-files]]"),
            MenuItem(image: "", template: "[[files-plain-with-icon]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.folderSettings.templates = [
            MenuItem(image: "target-icon", template: "[[file-name]]"),
            MenuItem(image: "target-icon", template: "[[files-with-icon]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "pages", template: "[[n-files-all]]"),
            MenuItem(image: "size", template: "[[file-size]] ([[filesize-full]] on disk)"),
            MenuItem(image: "clipboard", template: "[[clipboard]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.otherFormatsSettings.isEnabled = false
        settings.otherFormatsSettings.templates = [
            MenuItem(image: "target-icon", template: "[[file-name]]"),
            MenuItem(image: "", template: "[[open]]"),
            MenuItem(image: "clipboard", template: "[[clipboard]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[file-size]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.customFormatsSettings = []
        
        return settings
    }
    
    var version: Double
    
    var isIconHidden = false
    var isInfoOnSubMenu = true
    var isInfoOnMainItem = false
    var useFirstItemAsMain = true
    var isEmptyItemsSkipped = true
    
    var isRatioPrecise = false
    var bytesFormat: BytesFormat = .standard
    var bitsFormat: BitsFormat = .decimal
    var isTracksGrouped = true
    
    var isMetadataExpanded = false
    
    var menuAction: Action = .open
    var menuWillOpenFile: Bool {
        return menuAction == .open
    }
    
    var isUsingFirstItemAsMain: Bool {
        return isInfoOnSubMenu && isInfoOnMainItem && useFirstItemAsMain
    }
    
    var imageSettings: ImageSettings
    var videoSettings: VideoSettings
    var videoTrackSettings: MediaTrackSettings
    var audioTrackSettings: MediaTrackSettings
    var audioSettings: FormatSettings
    var pdfSettings: FormatSettings
    var officeSettings: OfficeSettings
    var modelSettings: FormatSettings
    var archiveSettings: ArchiveSettings
    var folderSettings: FolderSettings
    var customFormatsSettings: [CustomFormatSettings]
    var otherFormatsSettings: FormatSettings
    
    var folders: [URL] = []
    var handleExternalDisk = false
    
    var engines: [MediaEngine] = [.ffmpeg, .coremedia, .metadata]
    
    static let SharedDomainName: String = "org.sbarex.MediaInfo"
    
    static func instance(from dict: [String: AnyHashable]) -> Settings {
        let instance: Settings = Settings()
        
        if let v = dict["version"] as? Double, v < 2.0 {
            instance.version = dict["version"] as? Double ?? 0
            instance.isIconHidden = !(dict["icons"] as? Bool ?? true)
            instance.isInfoOnSubMenu = dict["sub_menu"] as? Bool ?? true
            instance.isInfoOnMainItem = dict["main_info"] as? Bool ?? true
            instance.useFirstItemAsMain = dict["use-first-item"] as? Bool ?? true
            instance.isRatioPrecise = dict["ratio-precise"] as? Bool ?? false
            instance.isEmptyItemsSkipped = dict["skip-empty"] as? Bool ?? true
            
            instance.menuAction = Action(rawValue: dict["menu-action"] as? Int ?? -1) ?? .open
            
            if let e = dict["engines"] as? [Int] {
                instance.engines = []
                for f in e {
                    if let engine = MediaEngine(rawValue: f) {
                        instance.engines.append(engine)
                    }
                }
                instance.engines = instance.engines.unique()
            }

            if let d = dict["folders"] as? [String] {
                instance.folders = d.sorted().map({ URL(fileURLWithPath: $0 )})
            }
            instance.handleExternalDisk = (dict["external-disk"] as? Bool) ?? false
            
            let processItems: (AnyHashable?) -> [MenuItem] = { dict in
                var menu: [MenuItem] = []
                if let items = dict as? [[String]] {
                    for item in items {
                        guard item.count == 2 else {
                            continue
                        }
                        menu.append(MenuItem(image: item[0], template: item[1]))
                    }
                }
                return menu
            }
            
            let triggerFromDict: (Any?)->[TriggerName: Trigger] = { d in
                guard let dict = d as? [String: [String: AnyHashable]] else {
                    return [:]
                }
                var triggers: [TriggerName: Trigger] = [:]
                for t in dict {
                    guard let name = TriggerName(rawValue: t.key), let trigger = Trigger(from: t.value) else {
                        continue
                    }
                    triggers[name] = trigger
                }
                return triggers
            }
            
            instance.imageSettings = ImageSettings(
                isEnabled: dict["image_handled"] as? Bool ?? true,
                templates: processItems(dict["image_items"]),
                triggers: triggerFromDict(dict["triggers"]),
                extractMetadata: dict["image_metadata"] as? Bool ?? false
            )
            instance.imageSettings.migrateTriggers()
            
            instance.videoTrackSettings = MediaTrackSettings(isEnabled: true, templates: processItems(dict["video_tracks_items"]), triggers: [:])
            instance.audioTrackSettings = MediaTrackSettings(isEnabled: true, templates: processItems(dict["audio_tracks_items"]), triggers: [:])
            
            instance.videoSettings = VideoSettings(
                isEnabled: dict["video_handled"] as? Bool ?? true,
                templates: processItems(dict["video_items"]),
                triggers: [:],
                groupTracks: dict["group_tracks"] as? Bool ?? true
            )
            instance.videoSettings.migrateTriggers()
            
            instance.audioSettings = FormatSettings(isEnabled: dict["audio_handled"] as? Bool ?? true, templates: processItems(dict["audio_items"]), triggers: [:])
            instance.audioSettings.migrateTriggers()
            
            instance.pdfSettings = FormatSettings(isEnabled: dict["pdf_handled"] as? Bool ?? true, templates: processItems(dict["pdf_items"]), triggers: [:])
            instance.pdfSettings.migrateTriggers()
            
            instance.officeSettings = OfficeSettings(
                isEnabled: dict["office_handled"] as? Bool ?? true,
                templates: processItems(dict["office_items"]),
                triggers: [:],
                deepScan: dict["office_deep_scan"] as? Bool ?? true
            )
            instance.officeSettings.migrateTriggers()
            
            instance.modelSettings = FormatSettings(isEnabled: dict["3d_handled"] as? Bool ?? true, templates: processItems(dict["3d_items"]), triggers: [:])
            instance.modelSettings.migrateTriggers()
            
            instance.archiveSettings = ArchiveSettings(
                isEnabled: dict["archive_items"] as? Bool ?? true,
                templates: processItems(dict["office_items"]),
                triggers: [:],
                maxFiles: dict["archive_max_files"] as? Int ?? 100
                //, maxDepth = dict["archive_max_depth"] as? Int ?? 10
                //, maxFilesInDepth: dict["archive_max_files_in_depth"] as? Int ?? 30
            )
            instance.archiveSettings.migrateTriggers()
            
            instance.folderSettings = FolderSettings(
                isEnabled: dict["folder_handled"] as? Bool ?? true,
                isBundleEnabled: dict["bundle_handled"] as? Bool ?? true,
                templates: processItems(dict["folder_items"]),
                triggers: [:],
                maxFiles: dict["folder_max_files"] as? Int ?? 200,
                maxDepth: dict["folder_max_depth"] as? Int ?? 0,
                maxFilesInDepth: dict["folder_max_files_in_depth"] as? Int ?? 50,
                skipHiddenFiles: dict["folder_skip_hidden_files"] as? Bool ?? true,
                usesGenericIcon: dict["folder_generic_icon"] as? Bool ?? true,
                action: FolderAction(rawValue: dict["folder_action"] as? Int ?? -1) ?? .revealFile,
                sizeMethod: FolderSizeMethod(rawValue: dict["folder_size_method"] as? Int ?? -1) ?? .fast
            )
            instance.folderSettings.migrateTriggers()
            
            if v < 1.8 {
                let def = Self.getStandardSettings()
                if instance.videoTrackSettings.templates.isEmpty {
                    instance.videoTrackSettings.templates = def.videoTrackSettings.templates
                }
                if instance.audioTrackSettings.templates.isEmpty {
                    instance.audioTrackSettings.templates = def.audioTrackSettings.templates
                }
            }
        } else {
            instance.version = dict[CodingKeys.version.rawValue] as? Double ?? Settings.Version
            instance.folders = (dict[CodingKeys.folders.rawValue] as? [String] ?? []).map({ URL(fileURLWithPath: $0 )})
            instance.handleExternalDisk = dict[CodingKeys.handleExternalDisk.rawValue] as? Bool ?? false
            instance.menuAction = Action(rawValue: dict[CodingKeys.menuAction.rawValue] as? Int ?? -1) ?? .none
            instance.engines = []
            if let ee = dict[CodingKeys.engines.rawValue] as? [Int] {
                for e in ee {
                    if let engine = MediaEngine(rawValue: e) {
                        instance.engines.append(engine)
                    }
                }
            }
            
            instance.isIconHidden = dict[CodingKeys.iconsHidden.rawValue] as? Bool ?? false
            instance.isInfoOnSubMenu = dict[CodingKeys.infoOnSubMenu.rawValue] as? Bool ?? false
            instance.isInfoOnMainItem = dict[CodingKeys.infoOnMainItem.rawValue] as? Bool ?? false
            instance.useFirstItemAsMain = dict[CodingKeys.useFirstItemAsMain.rawValue] as? Bool ?? false
            instance.isRatioPrecise = dict[CodingKeys.isRatioPrecise.rawValue] as? Bool ?? false
            if let i = dict[CodingKeys.bytesFormat.rawValue] as? Int, let f = BytesFormat(rawValue: i) {
                instance.bytesFormat = f
            } else {
                instance.bytesFormat = .standard
            }
            if let i = dict[CodingKeys.bitsFormat.rawValue] as? Int, let f = BitsFormat(rawValue: i) {
                instance.bitsFormat = f
            } else {
                instance.bitsFormat = .decimal
            }
            
            instance.isEmptyItemsSkipped = dict[CodingKeys.skipEmpty.rawValue] as? Bool ?? false
            
            if let d = dict[CodingKeys.imageSettings.rawValue] as? [String: AnyHashable], let settings = ImageSettings(from: d) {
                instance.imageSettings = settings
            }
            if let d = dict[CodingKeys.videoSettings.rawValue] as? [String: AnyHashable], let settings = VideoSettings(from: d) {
                instance.videoSettings = settings
            }
            if let d = dict[CodingKeys.videoTrackSettings.rawValue] as? [String: AnyHashable], let settings = MediaTrackSettings(from: d) {
                instance.videoTrackSettings = settings
            }
            if let d = dict[CodingKeys.audioTrackSettings.rawValue] as? [String: AnyHashable], let settings = MediaTrackSettings(from: d) {
                instance.audioTrackSettings = settings
            }
            if let d = dict[CodingKeys.audioSettings.rawValue] as? [String: AnyHashable], let settings = FormatSettings(from: d) {
                instance.audioSettings = settings
            }
            if let d = dict[CodingKeys.pdfSettings.rawValue] as? [String: AnyHashable], let settings = FormatSettings(from: d) {
                instance.pdfSettings = settings
            }
            if let d = dict[CodingKeys.officeSettings.rawValue] as? [String: AnyHashable], let settings = OfficeSettings(from: d) {
                instance.officeSettings = settings
            }
            if let d = dict[CodingKeys.modelSettings.rawValue] as? [String: AnyHashable], let settings = FormatSettings(from: d) {
                instance.modelSettings = settings
            }
            if let d = dict[CodingKeys.archiveSettings.rawValue] as? [String: AnyHashable], let settings = ArchiveSettings(from: d) {
                instance.archiveSettings = settings
            }
            if let d = dict[CodingKeys.folderSettings.rawValue] as? [String: AnyHashable], let settings = FolderSettings(from: d) {
                instance.folderSettings = settings
            }
            if let d = dict[CodingKeys.customFormats.rawValue] as? [[String: AnyHashable]] {
                for d1 in d {
                    if let settings = CustomFormatSettings(from: d1) {
                        instance.customFormatsSettings.append(settings)
                    }
                }
            }
            if let d = dict[CodingKeys.otherFormats.rawValue] as? [String: AnyHashable], let settings = FormatSettings(from: d) {
                instance.otherFormatsSettings = settings
            }
        }
        
        if !instance.isInfoOnMainItem {
            let standard = Self.getStandardSettings()
            
            if instance.imageSettings.templates.isEmpty {
                instance.imageSettings.templates = standard.imageSettings.templates
            }
            if instance.videoSettings.templates.isEmpty {
                instance.videoSettings.templates = standard.videoSettings.templates
            }
            if instance.audioSettings.templates.isEmpty {
                instance.audioSettings.templates = standard.audioSettings.templates
            }
            if instance.pdfSettings.templates.isEmpty {
                instance.pdfSettings.templates = standard.pdfSettings.templates
            }
            if instance.officeSettings.templates.isEmpty {
                instance.officeSettings.templates = standard.officeSettings.templates
            }
            if instance.modelSettings.templates.isEmpty {
                instance.modelSettings.templates = standard.modelSettings.templates
            }
            if instance.archiveSettings.templates.isEmpty {
                instance.archiveSettings.templates = standard.archiveSettings.templates
            }
            if instance.folderSettings.templates.isEmpty {
                instance.folderSettings.templates = standard.folderSettings.templates
            }
        }
        
        if !instance.engines.contains(.ffmpeg) {
            instance.engines.append(.ffmpeg)
        }
        if !instance.engines.contains(.coremedia) {
            instance.engines.append(.coremedia)
        }
        if !instance.engines.contains(.metadata) {
            instance.engines.append(.metadata)
        }
        
        if let b = dict[CodingKeys.metadataExpanded.rawValue] as? Bool {
            instance.isMetadataExpanded = b
        }
        
        instance.version = Self.Version
        
        return instance
    }
    
    func update(from dict: [String: AnyHashable]) {
        if let folders = dict[CodingKeys.folders.rawValue] as? [String] {
            self.folders = Array(Set(folders.map({URL(fileURLWithPath: $0)}))).sorted(by: {$0.path < $1.path})
        }
        if let external = dict[CodingKeys.handleExternalDisk.rawValue] as? Bool {
            self.handleExternalDisk = external
        }
        if let i = dict[CodingKeys.menuAction.rawValue] as? Int, let action = Action(rawValue:  i) {
            self.menuAction = action
        }
        if let ee = dict[CodingKeys.engines.rawValue] as? [Int] {
            self.engines = []
            for e in ee {
                if let engine = MediaEngine(rawValue: e) {
                    self.engines.append(engine)
                }
            }
        }
        if let b = dict[CodingKeys.iconsHidden.rawValue] as? Bool {
            self.isIconHidden = b
        }
        if let b = dict[CodingKeys.infoOnSubMenu.rawValue] as? Bool {
            self.isInfoOnSubMenu = b
        }
        if let b = dict[CodingKeys.infoOnMainItem.rawValue] as? Bool {
            self.isInfoOnMainItem = b
        }
        if let b = dict[CodingKeys.useFirstItemAsMain.rawValue] as? Bool {
            self.useFirstItemAsMain = b
        }
        if let b = dict[CodingKeys.isRatioPrecise.rawValue] as? Bool {
            self.isRatioPrecise = b
        }
        if let b = dict[CodingKeys.bytesFormat.rawValue] as? Int, let f = BytesFormat(rawValue: b) {
            self.bytesFormat = f
        }
        if let b = dict[CodingKeys.bitsFormat.rawValue] as? Int, let f = BitsFormat(rawValue: b) {
            self.bitsFormat = f
        }
        if let b = dict[CodingKeys.skipEmpty.rawValue] as? Bool {
            self.isEmptyItemsSkipped = b
        }
        if let b = dict[CodingKeys.metadataExpanded.rawValue] as? Bool {
            self.isMetadataExpanded = b
        }
        if let d = dict[CodingKeys.imageSettings.rawValue] as? [String: AnyHashable] {
            self.imageSettings.update(from: d)
        }
        if let d = dict[CodingKeys.videoSettings.rawValue] as? [String: AnyHashable] {
            self.videoSettings.update(from: d)
        }
        if let d = dict[CodingKeys.videoTrackSettings.rawValue] as? [String: AnyHashable] {
            self.videoTrackSettings.update(from: d)
        }
        if let d = dict[CodingKeys.audioTrackSettings.rawValue] as? [String: AnyHashable] {
            self.audioTrackSettings.update(from: d)
        }
        if let d = dict[CodingKeys.audioSettings.rawValue] as? [String: AnyHashable] {
            self.audioSettings.update(from: d)
        }
        if let d = dict[CodingKeys.pdfSettings.rawValue] as? [String: AnyHashable] {
            self.pdfSettings.update(from: d)
        }
        if let d = dict[CodingKeys.officeSettings.rawValue] as? [String: AnyHashable] {
            self.officeSettings.update(from: d)
        }
        if let d = dict[CodingKeys.modelSettings.rawValue] as? [String: AnyHashable] {
            self.modelSettings.update(from: d)
        }
        if let d = dict[CodingKeys.archiveSettings.rawValue] as? [String: AnyHashable] {
            self.archiveSettings.update(from: d)
        }
        if let d = dict[CodingKeys.folderSettings.rawValue] as? [String: AnyHashable] {
            self.folderSettings.update(from: d)
        }
        if let d = dict[CodingKeys.otherFormats.rawValue] as? [String: AnyHashable] {
            self.otherFormatsSettings.update(from: d)
        }
        if let d = dict[CodingKeys.customFormats.rawValue] as? [[String: AnyHashable]] {
            self.customFormatsSettings = []
            for d1 in d {
                if let s = CustomFormatSettings(from: d1) {
                    self.customFormatsSettings.append(s)
                }
            }
        }
    }
    
    fileprivate init() {
        self.version = Self.Version
        
        self.isIconHidden = false
        self.isInfoOnSubMenu = true
        self.isInfoOnMainItem = false
        self.useFirstItemAsMain = true
        self.isEmptyItemsSkipped = true
        
        self.isRatioPrecise = false
        self.bytesFormat = .standard
        self.bitsFormat = .decimal
        self.isTracksGrouped = true
        self.isMetadataExpanded = false
        
        self.menuAction = .open
        
        self.folders = []
        self.handleExternalDisk = false
        
        self.engines = [.ffmpeg, .coremedia, .metadata]
        
        self.imageSettings = ImageSettings(isEnabled: true, templates: [], triggers: [:], extractMetadata: false)
        
        self.videoSettings = VideoSettings(isEnabled: true, templates: [], triggers: [:], groupTracks: true)
        self.videoTrackSettings = MediaTrackSettings(isEnabled: true, templates: [], triggers: [:])
        self.audioTrackSettings = MediaTrackSettings(isEnabled: true, templates: [], triggers: [:])
        
        self.audioSettings = FormatSettings(isEnabled: true, templates: [], triggers: [:])
        self.pdfSettings = FormatSettings(isEnabled: true, templates: [], triggers: [:])
        
        self.officeSettings = OfficeSettings(isEnabled: true, templates: [], triggers: [:], deepScan: false)
        self.modelSettings = OfficeSettings(isEnabled: true, templates: [], triggers: [:], deepScan: false)
        
        self.archiveSettings = ArchiveSettings(isEnabled: true, templates: [], triggers: [:],  maxFiles: 100)
        self.folderSettings = FolderSettings(isEnabled: true, isBundleEnabled: true, templates: [], triggers: [:], maxFiles: 200, maxDepth: 0, maxFilesInDepth: 0, skipHiddenFiles: true, usesGenericIcon: true, action: .revealFile, sizeMethod: .fast)
        self.customFormatsSettings = []
        self.otherFormatsSettings = FormatSettings(isEnabled: false, templates: [], triggers: [:])
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.folders = try container.decode([String].self, forKey: .folders).sorted(by: { $0 < $1 }).map({ URL(fileURLWithPath: $0) })
        self.handleExternalDisk = try container.decode(Bool.self, forKey: .handleExternalDisk)
        self.handleExternalDisk = try container.decode(Bool.self, forKey: .handleExternalDisk)
        
        self.version = try container.decode(Double.self, forKey: .version)
        self.isIconHidden = try container.decode(Bool.self, forKey: .iconsHidden)
        self.isInfoOnSubMenu = try container.decode(Bool.self, forKey: .infoOnSubMenu)
        self.isInfoOnMainItem = try container.decode(Bool.self, forKey: .infoOnMainItem)
        self.useFirstItemAsMain = try container.decode(Bool.self, forKey: .useFirstItemAsMain)
        self.isEmptyItemsSkipped = try container.decode(Bool.self, forKey: .skipEmpty)
        self.isMetadataExpanded = try container.decode(Bool.self, forKey: .metadataExpanded)
        
        self.isRatioPrecise = try container.decode(Bool.self, forKey: .isRatioPrecise)
        self.bytesFormat = try container.decode(BytesFormat.self, forKey: .bytesFormat)
        self.bitsFormat = try container.decode(BitsFormat.self, forKey: .bitsFormat)
        
        self.menuAction = try container.decode(Action.self, forKey: .menuAction)
        self.engines = try container.decode([MediaEngine].self, forKey: .engines)
        
        self.imageSettings = try container.decode(ImageSettings.self, forKey: .imageSettings)
        self.videoSettings = try container.decode(VideoSettings.self, forKey: .videoSettings)
        self.videoTrackSettings = try container.decode(MediaTrackSettings.self, forKey: .videoTrackSettings)
        self.audioTrackSettings = try container.decode(MediaTrackSettings.self, forKey: .audioTrackSettings)
        self.audioSettings = try container.decode(FormatSettings.self, forKey: .audioSettings)
        self.pdfSettings = try container.decode(FormatSettings.self, forKey: .pdfSettings)
        self.officeSettings = try container.decode(OfficeSettings.self, forKey: .officeSettings)
        self.modelSettings = try container.decode(FormatSettings.self, forKey: .modelSettings)
        self.archiveSettings = try container.decode(ArchiveSettings.self, forKey: .archiveSettings)
        self.folderSettings = try container.decode(FolderSettings.self, forKey: .folderSettings)
        self.otherFormatsSettings = try container.decode(FormatSettings.self, forKey: .otherFormats)
        self.customFormatsSettings = try container.decode([CustomFormatSettings].self, forKey: .customFormats)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.folders.map({ $0.path }).sorted(by: { $0 < $1 }), forKey: .folders)
        try container.encode(self.handleExternalDisk, forKey: .handleExternalDisk)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.isIconHidden, forKey: .iconsHidden)
        try container.encode(self.isInfoOnSubMenu, forKey: .infoOnSubMenu)
        try container.encode(self.isInfoOnMainItem, forKey: .infoOnMainItem)
        try container.encode(self.useFirstItemAsMain, forKey: .useFirstItemAsMain)
        try container.encode(self.isEmptyItemsSkipped, forKey: .skipEmpty)
        try container.encode(self.isMetadataExpanded, forKey: .metadataExpanded)
        
        try container.encode(self.isRatioPrecise, forKey: .isRatioPrecise)
        try container.encode(self.bytesFormat, forKey: .bytesFormat)
        try container.encode(self.bitsFormat, forKey: .bitsFormat)
        
        try container.encode(self.menuAction, forKey: .menuAction)
        try container.encode(self.engines, forKey: .engines)
        
        try container.encode(self.imageSettings, forKey: .imageSettings)
        try container.encode(self.videoSettings, forKey: .videoSettings)
        try container.encode(self.videoTrackSettings, forKey: .videoTrackSettings)
        try container.encode(self.audioTrackSettings, forKey: .audioTrackSettings)
        try container.encode(self.audioSettings, forKey: .audioSettings)
        try container.encode(self.pdfSettings, forKey: .pdfSettings)
        try container.encode(self.officeSettings, forKey: .officeSettings)
        try container.encode(self.modelSettings, forKey: .modelSettings)
        try container.encode(self.archiveSettings, forKey: .archiveSettings)
        try container.encode(self.folderSettings, forKey: .folderSettings)
        try container.encode(self.otherFormatsSettings, forKey: .otherFormats)
        try container.encode(self.customFormatsSettings, forKey: .customFormats)
    }
    
    func toDictionary() -> [String: AnyHashable] {
        var dict: [String: AnyHashable] = [:]
        dict[CodingKeys.version.rawValue] = Settings.Version
        
        let folders = Array(Set(self.folders.map({ $0.path }))).sorted(by: { $0 < $1 })
        dict[CodingKeys.folders.rawValue] = folders
        dict[CodingKeys.handleExternalDisk.rawValue] = self.handleExternalDisk
        dict[CodingKeys.menuAction.rawValue] = self.menuAction.rawValue
        dict[CodingKeys.engines.rawValue] = self.engines.map({ $0.rawValue })
        
        dict[CodingKeys.iconsHidden.rawValue] = self.isIconHidden
        dict[CodingKeys.infoOnSubMenu.rawValue] = self.isInfoOnSubMenu
        dict[CodingKeys.infoOnMainItem.rawValue] = self.isInfoOnMainItem
        dict[CodingKeys.useFirstItemAsMain.rawValue] = self.useFirstItemAsMain
        dict[CodingKeys.isRatioPrecise.rawValue] = self.isRatioPrecise
        dict[CodingKeys.bytesFormat.rawValue] = self.bytesFormat.rawValue
        dict[CodingKeys.bitsFormat.rawValue] = self.bitsFormat.rawValue
        dict[CodingKeys.skipEmpty.rawValue] = self.isEmptyItemsSkipped
        
        dict[CodingKeys.imageSettings.rawValue] = self.imageSettings.toDictionary()
        dict[CodingKeys.videoSettings.rawValue] = self.videoSettings.toDictionary()
        dict[CodingKeys.videoTrackSettings.rawValue] = self.videoTrackSettings.toDictionary()
        dict[CodingKeys.audioTrackSettings.rawValue] = self.audioTrackSettings.toDictionary()
        dict[CodingKeys.audioSettings.rawValue] = self.audioSettings.toDictionary()
        dict[CodingKeys.pdfSettings.rawValue] = self.pdfSettings.toDictionary()
        dict[CodingKeys.officeSettings.rawValue] = self.officeSettings.toDictionary()
        dict[CodingKeys.modelSettings.rawValue] = self.modelSettings.toDictionary()
        dict[CodingKeys.archiveSettings.rawValue] = self.archiveSettings.toDictionary()
        dict[CodingKeys.folderSettings.rawValue] = self.folderSettings.toDictionary()
        dict[CodingKeys.otherFormats.rawValue] = self.otherFormatsSettings.toDictionary()
        dict[CodingKeys.customFormats.rawValue] = self.customFormatsSettings.map({ $0.toDictionary() })
        dict[CodingKeys.metadataExpanded.rawValue] = self.isMetadataExpanded
         
        return dict
    }
    
    func getFormatSettings(for type: SupportedFile) -> FormatSettings? {
        switch type {
        case .none:
            return nil
        case .image:
            return self.imageSettings
        case .video:
            return self.videoSettings
        case .videoTrakcs:
            return self.videoTrackSettings
        case .audioTraks:
            return self.audioTrackSettings
        case .audio:
            return self.audioSettings
        case .office:
            return self.officeSettings
        case .model:
            return self.modelSettings
        case .pdf:
            return self.pdfSettings
        case .archive:
            return self.archiveSettings
        case .folder:
            return self.folderSettings
        case .others:
            return self.otherFormatsSettings
        }
    }
}
