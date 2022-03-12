//
//  Settings.swift
//  MediaInfo
//
//  Created by Sbarex on 04/09/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Foundation

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
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
        case skipEmpty
        case imageHandled
        case extractImageMetadata
        case imageTemplates
        
        case videoHandled
        case tracksGrouped
        case videoTemplates
        case videoTrackTemplates
        case audioTrackTemplates
        
        case audioHandled
        case audioTemplates
        
        case pdfHandled
        case pdfTemplates
        
        case officeHandled
        case officeDeepScan
        case officeTemplates
        
        case modelsHandled
        case modelsTemplates
        
        case archiveHandled
        case archiveMaxFiles
        case archiveMaxFilesInDepth
        case archiveMaxDepth
        case archiveTemplates
        
        case folderHandled
        case bundleHandled
        case folderMaxFiles
        case folderMaxDepth
        case folderMaxFilesInDepth
        case folderSkipHiddenFiles
        case folderUsesGenericIcon
        case folderAction
        case folderSizeMethod
        case folderTemplates
        
        case menuAction
        case engines
    }
    
    enum Action: Int, Codable {
        case none = 0
        case open
        case script
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
    }
    
    static let Version = 1.9
    /// Maximum time (in seconds) to complete the execution of a synchronous task
    static let execSyncTimeout: Double = 2
    /// Maximum time (in seconds) to complete the analysis of a file
    static let infoExtractionTimeout: Double = 2
    
    static func getStandardSettings() -> Settings {
        let settings = Settings(fromDict: [:])
    
        settings.version = Self.Version
        
        settings.imageMenuItems = [
            MenuItem(image: "image", template: "[[size]], [[color-depth]] [[is-animated]]"),
            MenuItem(image: "ratio", template: "[[ratio]], [[resolution]]"),
            MenuItem(image: "color", template: "[[color-depth]], [[is-alpha]], [[color-table]], [[profile-name]]"),
            MenuItem(image: "printer", template: "[[dpi]]"),
            MenuItem(image: "printer", template: "[[print:cm]]"),
            MenuItem(image: "printer", template: "[[print:cm:300]]"),
            MenuItem(image: "printer", template: "[[paper]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[filesize]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open-with-default]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        settings.videoMenuItems = [
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
            MenuItem(image: "size", template: "[[filesize]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open-with-default]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        settings.videoTracksMenuItems = [
            MenuItem(image: "video", template: "[[size]], [[duration]], [[fps]] ([[language-flag]])"),
            MenuItem(image: "ratio", template: "[[ratio]], [[resolution]]"),
            MenuItem(image: "video", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "", template: "[[frames]]"),
            MenuItem(image: "tag", template: "[[title]]"),
        ]
        settings.audioTracksMenuItems = [
            MenuItem(image: "audio", template: "[[duration]] ([[seconds]]) [[channels-name]] [[language-flag]]"),
            MenuItem(image: "audio", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "tag", template: "[[title]]"),
        ]
        
        settings.audioMenuItems = [
            MenuItem(image: "audio", template: "[[duration]] ([[seconds]]) [[channels-name]] [[language-flag]]"),
            MenuItem(image: "audio", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "tag", template: "[[title]]"),
            MenuItem(image: "", template: "([[engine]])"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[filesize]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open-with-default]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.pdfMenuItems = [
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
            MenuItem(image: "size", template: "[[filesize]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open-with-default]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.officeMenuItems = [
            MenuItem(image: "office", template: "[[size:paper:cm]], [[title]], [[pages]]"),
            MenuItem(image: "tag", template: "subject: [[subject]]"),
            MenuItem(image: "person", template: "[[creation]]"),
            MenuItem(image: "pencil", template: "[[last-modification]]"),
            MenuItem(image: "pages", template: "[[pages]]"),
            MenuItem(image: "abc", template: "[[words]], [[characters-space]]"),
            MenuItem(image: "", template: "[[keywords]]"),
            MenuItem(image: "", template: "([[application]])"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[filesize]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open-with-default]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.modelsMenuItems = [
            MenuItem(image: "3d", template: "[[mesh]], [[vertex]]"),
            MenuItem(image: "3d", template: "[[normal]], [[tangent]]"),
            MenuItem(image: "3d", template: "[[texture-coords]]"),
            MenuItem(image: "3d", template: "[[colors]], [[occlusion]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[filesize]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open-with-default]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.archiveMenuItems = [
            MenuItem(image: "zip", template: "[[filesize]] = [[uncompressed-size]] uncompressed, [[n-files]]"),
            MenuItem(image: "", template: "[[files-plain-with-icon]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[open-with-default]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        
        settings.folderMenuItems = [
            MenuItem(image: "target-icon", template: "[[file-name]]"),
            MenuItem(image: "target-icon", template: "[[files-with-icon]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "pages", template: "[[n-files-all]]"),
            MenuItem(image: "size", template: "[[filesize]] ([[filesize-full]] on disk)"),
            MenuItem(image: "clipboard", template: "[[clipboard]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "", template: "[[about]]"),
        ]
        return settings
    }
    
    struct MenuItem: Codable, Hashable {
        enum CodingKeys: String, CodingKey {
            case image
            case template
        }
        
        var image: String
        var template: String
    }
    
    var version: Double
    
    var isIconHidden = false
    var isInfoOnSubMenu = true
    var isInfoOnMainItem = false
    var useFirstItemAsMain = true
    var isEmptyItemsSkipped = true
    
    var isRatioPrecise = false
    var isTracksGrouped = true
    
    var menuAction: Action = .open
    var menuWillOpenFile: Bool {
        return menuAction == .open
    }
    
    var isUsingFirstItemAsMain: Bool {
        return isInfoOnSubMenu && isInfoOnMainItem && useFirstItemAsMain
    }
    
    var isImagesHandled = true
    var extractImageMetadata = false
    var imageMenuItems: [MenuItem] = []
    
    var isVideoHandled = true
    var videoMenuItems: [MenuItem] = []
    var videoTracksMenuItems: [MenuItem] = []
    var audioTracksMenuItems: [MenuItem] = []
    
    var isAudioHandled = true
    var audioMenuItems: [MenuItem] = []
    
    var isPDFHandled = true
    var pdfMenuItems: [MenuItem] = []
    
    var isOfficeHandled = true
    var isOfficeDeepScan = false
    var officeMenuItems: [MenuItem] = []
    
    var isModelsHandled = false
    var modelsMenuItems: [MenuItem] = []
    
    var isArchiveHandled = true
    var archiveMaxFiles = 100
    var archiveMaxDepth = 10
    var archiveMaxFilesInDepth = 30
    var archiveMenuItems: [MenuItem] = []
    
    var isFolderHandled = true
    var isBundleHandled = true
    var folderMaxFiles = 200
    var folderMaxDepth = 0
    var folderMaxFilesInDepth = 0
    var folderSkipHiddenFiles = true
    var folderUsesGenericIcon = true
    var folderAction: FolderAction = .revealFile
    var folderSizeMethod: FolderSizeMethod = .fast
    var folderMenuItems: [MenuItem] = []
    var folderSortFoldersFirst: Bool {
        let d = UserDefaults(suiteName: "com.apple.finder")
        return d?.bool(forKey: "_FXSortFoldersFirst") ?? false
    }
    var folders: [URL] = []
    var handleExternalDisk = false
    
    var engines: [MediaEngine] = [.ffmpeg, .coremedia, .metadata]
    
    static let SharedDomainName: String = "org.sbarex.MediaInfo"
    
    init(fromDict dict: [String: AnyHashable]) {
        self.version = 0
        refresh(fromDict: dict)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.folders = try container.decode([URL].self, forKey: .folders)
        self.handleExternalDisk = try container.decode(Bool.self, forKey: .handleExternalDisk)
        self.handleExternalDisk = try container.decode(Bool.self, forKey: .handleExternalDisk)
        
        self.version = try container.decode(Double.self, forKey: .version)
        self.isIconHidden = try container.decode(Bool.self, forKey: .iconsHidden)
        self.isInfoOnSubMenu = try container.decode(Bool.self, forKey: .infoOnSubMenu)
        self.isInfoOnMainItem = try container.decode(Bool.self, forKey: .infoOnMainItem)
        self.useFirstItemAsMain = try container.decode(Bool.self, forKey: .useFirstItemAsMain)
        self.isEmptyItemsSkipped = try container.decode(Bool.self, forKey: .skipEmpty)
        
        self.isRatioPrecise = try container.decode(Bool.self, forKey: .isRatioPrecise)
        
        self.isImagesHandled = try container.decode(Bool.self, forKey: .imageHandled)
        self.extractImageMetadata = try container.decode(Bool.self, forKey: .extractImageMetadata)
        self.imageMenuItems = try container.decode([MenuItem].self, forKey: .imageTemplates)
        
        self.isVideoHandled = try container.decode(Bool.self, forKey: .videoHandled)
        self.isTracksGrouped = try container.decode(Bool.self, forKey: .tracksGrouped)
        self.videoMenuItems = try container.decode([MenuItem].self, forKey: .videoTemplates)
        self.videoTracksMenuItems = try container.decode([MenuItem].self, forKey: .videoTrackTemplates)
        self.audioTracksMenuItems = try container.decode([MenuItem].self, forKey: .audioTrackTemplates)
        
        self.isAudioHandled = try container.decode(Bool.self, forKey: .audioHandled)
        self.audioMenuItems = try container.decode([MenuItem].self, forKey: .audioTemplates)
        
        self.isPDFHandled = try container.decode(Bool.self, forKey: .pdfHandled)
        self.pdfMenuItems = try container.decode([MenuItem].self, forKey: .pdfTemplates)
        
        self.isOfficeHandled = try container.decode(Bool.self, forKey: .officeHandled)
        self.isOfficeDeepScan = try container.decode(Bool.self, forKey: .officeDeepScan)
        self.officeMenuItems = try container.decode([MenuItem].self, forKey: .officeTemplates)
        
        self.isModelsHandled = try container.decode(Bool.self, forKey: .modelsHandled)
        self.modelsMenuItems = try container.decode([MenuItem].self, forKey: .modelsTemplates)
        
        self.isArchiveHandled = try container.decode(Bool.self, forKey: .archiveHandled)
        self.archiveMaxFiles = try container.decode(Int.self, forKey: .archiveMaxFiles)
        self.archiveMaxDepth = try container.decode(Int.self, forKey: .archiveMaxDepth)
        self.archiveMaxFilesInDepth = try container.decode(Int.self, forKey: .archiveMaxFilesInDepth)
        self.archiveMenuItems = try container.decode([MenuItem].self, forKey: .archiveTemplates)
        
        self.isFolderHandled = try container.decode(Bool.self, forKey: .folderHandled)
        self.isBundleHandled = try container.decode(Bool.self, forKey: .bundleHandled)
        self.folderMaxFiles = try container.decode(Int.self, forKey: .folderMaxFiles)
        self.folderMaxDepth = try container.decode(Int.self, forKey: .folderMaxDepth)
        self.folderMaxFilesInDepth = try container.decode(Int.self, forKey: .folderMaxFilesInDepth)
        self.folderSkipHiddenFiles = try container.decode(Bool.self, forKey: .folderSkipHiddenFiles)
        self.folderUsesGenericIcon = try container.decode(Bool.self, forKey: .folderUsesGenericIcon)
        self.folderAction = try container.decode(FolderAction.self, forKey: .folderAction)
        self.folderSizeMethod = try container.decode(FolderSizeMethod.self, forKey: .folderSizeMethod)
        self.folderMenuItems = try container.decode([MenuItem].self, forKey: .folderTemplates)
        
        self.menuAction = try container.decode(Action.self, forKey: .menuAction)
        self.engines = try container.decode([MediaEngine].self, forKey: .engines)
        
        migrate()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.folders, forKey: .folders)
        try container.encode(self.handleExternalDisk, forKey: .handleExternalDisk)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.isIconHidden, forKey: .iconsHidden)
        try container.encode(self.isInfoOnSubMenu, forKey: .infoOnSubMenu)
        try container.encode(self.isInfoOnMainItem, forKey: .infoOnMainItem)
        try container.encode(self.useFirstItemAsMain, forKey: .useFirstItemAsMain)
        try container.encode(self.isEmptyItemsSkipped, forKey: .skipEmpty)
        
        try container.encode(self.isRatioPrecise, forKey: .isRatioPrecise)
        
        try container.encode(self.isImagesHandled, forKey: .imageHandled)
        try container.encode(self.extractImageMetadata, forKey: .extractImageMetadata)
        try container.encode(self.imageMenuItems, forKey: .imageTemplates)
        
        try container.encode(self.isVideoHandled, forKey: .videoHandled)
        try container.encode(self.isTracksGrouped, forKey: .tracksGrouped)
        try container.encode(self.videoMenuItems, forKey: .videoTemplates)
        try container.encode(self.videoTracksMenuItems, forKey: .videoTrackTemplates)
        try container.encode(self.audioTracksMenuItems, forKey: .audioTrackTemplates)
        
        try container.encode(self.isAudioHandled, forKey: .audioHandled)
        try container.encode(self.audioMenuItems, forKey: .audioTemplates)
        
        try container.encode(self.isPDFHandled, forKey: .pdfHandled)
        try container.encode(self.pdfMenuItems, forKey: .pdfTemplates)
        
        try container.encode(self.isOfficeHandled, forKey: .officeHandled)
        try container.encode(self.isOfficeDeepScan, forKey: .officeDeepScan)
        try container.encode(self.officeMenuItems, forKey: .officeTemplates)
        
        try container.encode(self.isModelsHandled, forKey: .modelsHandled)
        try container.encode(self.modelsMenuItems, forKey: .modelsTemplates)
        
        try container.encode(self.isArchiveHandled, forKey: .archiveHandled)
        try container.encode(self.archiveMaxFiles, forKey: .archiveMaxFiles)
        try container.encode(self.archiveMaxDepth, forKey: .archiveMaxDepth)
        try container.encode(self.archiveMaxFilesInDepth, forKey: .archiveMaxFilesInDepth)
        try container.encode(self.archiveMenuItems, forKey: .archiveTemplates)
        
        try container.encode(self.isFolderHandled, forKey: .folderHandled)
        try container.encode(self.isBundleHandled, forKey: .bundleHandled)
        try container.encode(self.folderMaxFiles, forKey: .folderMaxFiles)
        try container.encode(self.folderMaxDepth, forKey: .folderMaxDepth)
        try container.encode(self.folderMaxFilesInDepth, forKey: .folderMaxFilesInDepth)
        try container.encode(self.folderSkipHiddenFiles, forKey: .folderSkipHiddenFiles)
        try container.encode(self.folderUsesGenericIcon, forKey: .folderUsesGenericIcon)
        try container.encode(self.folderAction, forKey: .folderAction)
        try container.encode(self.folderSizeMethod, forKey: .folderSizeMethod)
        try container.encode(self.folderMenuItems, forKey: .folderTemplates)
        
        try container.encode(self.menuAction, forKey: .menuAction)
        try container.encode(self.engines, forKey: .engines)
    }
    
    internal func migrate() {
        guard self.version != Self.Version else {
            return
        }
        if self.version < 1.8 {
            let def = Self.getStandardSettings()
            if self.videoTracksMenuItems.isEmpty {
                self.videoTracksMenuItems = def.videoTracksMenuItems
            }
            if self.audioTracksMenuItems.isEmpty {
                self.audioTracksMenuItems = def.audioTracksMenuItems
            }
        }
        self.version = Self.Version
    }
    
    func refresh(fromDict defaultsDomain: [String: AnyHashable]) {
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
        
        self.version = defaultsDomain["version"] as? Double ?? 0
        self.isIconHidden = !(defaultsDomain["icons"] as? Bool ?? true)
        self.isInfoOnSubMenu = defaultsDomain["sub_menu"] as? Bool ?? true
        self.isInfoOnMainItem = defaultsDomain["main_info"] as? Bool ?? true
        self.useFirstItemAsMain = defaultsDomain["use-first-item"] as? Bool ?? true
        self.isRatioPrecise = defaultsDomain["ratio-precise"] as? Bool ?? false
        self.isEmptyItemsSkipped = defaultsDomain["skip-empty"] as? Bool ?? true
        
        self.isImagesHandled = defaultsDomain["image_handled"] as? Bool ?? true
        self.extractImageMetadata = defaultsDomain["image_metadata"] as? Bool ?? false
        self.imageMenuItems = processItems(defaultsDomain["image_items"])
        
        self.isVideoHandled = defaultsDomain["video_handled"] as? Bool ?? true
        self.isTracksGrouped = defaultsDomain["group_tracks"] as? Bool ?? true
        self.videoMenuItems = processItems(defaultsDomain["video_items"])
        self.videoTracksMenuItems = processItems(defaultsDomain["video_tracks_items"])
        self.audioTracksMenuItems = processItems(defaultsDomain["audio_tracks_items"])
        
        self.isAudioHandled = defaultsDomain["audio_handled"] as? Bool ?? true
        self.audioMenuItems = processItems(defaultsDomain["audio_items"])
        
        self.isPDFHandled = defaultsDomain["pdf_handled"] as? Bool ?? true
        self.pdfMenuItems = processItems(defaultsDomain["pdf_items"])
        
        self.isOfficeHandled = defaultsDomain["office_handled"] as? Bool ?? true
        self.isOfficeDeepScan = defaultsDomain["office_deep_scan"] as? Bool ?? true
        self.officeMenuItems = processItems(defaultsDomain["office_items"])
        
        self.isModelsHandled = defaultsDomain["3d_handled"] as? Bool ?? false
        self.modelsMenuItems = processItems(defaultsDomain["3d_items"])
        
        self.isArchiveHandled = defaultsDomain["archive_handled"] as? Bool ?? true
        self.archiveMaxFiles = defaultsDomain["archive_max_files"] as? Int ?? 100
        self.archiveMaxDepth = defaultsDomain["archive_max_depth"] as? Int ?? 10
        self.archiveMaxFilesInDepth = defaultsDomain["archive_max_files_in_depth"] as? Int ?? 30
        self.archiveMenuItems = processItems(defaultsDomain["archive_items"])
        
        self.isFolderHandled = defaultsDomain["folder_handled"] as? Bool ?? true
        self.isBundleHandled = defaultsDomain["bundle_handled"] as? Bool ?? true
        self.folderMaxFiles = defaultsDomain["folder_max_files"] as? Int ?? 200
        self.folderMaxDepth = defaultsDomain["folder_max_depth"] as? Int ?? 10
        self.folderMaxFilesInDepth = defaultsDomain["folder_max_files_in_depth"] as? Int ?? 50
        self.folderSkipHiddenFiles = defaultsDomain["folder_skip_hidden_files"] as? Bool ?? true
        self.folderSizeMethod = FolderSizeMethod(rawValue: defaultsDomain["folder_size_method"] as? Int ?? -1) ?? .fast
        if let i = defaultsDomain["folder_action"] as? Int, let v = FolderAction(rawValue: i) {
            self.folderAction = v
        } else {
            self.folderAction = .revealFile
        }
        self.folderUsesGenericIcon = defaultsDomain["folder_generic_icon"] as? Bool ?? true
        self.folderMenuItems = processItems(defaultsDomain["folder_items"])
        
        if !self.isInfoOnMainItem {
            let standard = Self.getStandardSettings()
            
            if self.imageMenuItems.isEmpty {
                self.imageMenuItems = standard.imageMenuItems
            }
            if self.videoMenuItems.isEmpty {
                self.videoMenuItems = standard.videoMenuItems
            }
            if self.audioMenuItems.isEmpty {
                self.audioMenuItems = standard.audioMenuItems
            }
            if self.pdfMenuItems.isEmpty {
                self.pdfMenuItems = standard.pdfMenuItems
            }
            if self.officeMenuItems.isEmpty {
                self.officeMenuItems = standard.officeMenuItems
            }
            if self.modelsMenuItems.isEmpty {
                self.modelsMenuItems = standard.modelsMenuItems
            }
        }
        
        self.menuAction = Action(rawValue: defaultsDomain["menu-action"] as? Int ?? -1) ?? .open
        
        if let e = defaultsDomain["engines"] as? [Int] {
            self.engines = []
            for f in e {
                if let engine = MediaEngine(rawValue: f) {
                    self.engines.append(engine)
                }
            }
            self.engines = self.engines.unique()
            
            if !self.engines.contains(.ffmpeg) {
                self.engines.append(.ffmpeg)
            }
            if !self.engines.contains(.coremedia) {
                self.engines.append(.coremedia)
            }
            if !self.engines.contains(.metadata) {
                self.engines.append(.metadata)
            }
        }

        if let d = defaultsDomain["folders"] as? [String] {
            self.folders = d.sorted().map({ URL(fileURLWithPath: $0 )})
        }
        self.handleExternalDisk = (defaultsDomain["external-disk"] as? Bool) ?? false
        
        if !defaultsDomain.isEmpty {
            migrate()
        }
    }
    
    func toDictionary() -> [String: AnyHashable] {
        var dict: [String: AnyHashable] = [:]
        let folders = Array(Set(self.folders.map({ $0.path })))
        dict["folders"] = folders
        dict["external-disk"] = self.handleExternalDisk
        
        dict["version"] = Settings.Version
        
        dict["icons"] = !self.isIconHidden
        dict["sub_menu"] = self.isInfoOnSubMenu
        dict["main_info"] = self.isInfoOnMainItem
        dict["use-first-item"] = self.useFirstItemAsMain
        dict["ratio-precise"] = self.isRatioPrecise
        dict["skip-empty"] = self.isEmptyItemsSkipped
        
        dict["image_handled"] = self.isImagesHandled
        dict["image_metadata"] = self.extractImageMetadata
        
        dict["image_items"] = self.imageMenuItems.map({ return [$0.image, $0.template]})
        
        dict["video_handled"] = self.isVideoHandled
        dict["group_tracks"] = self.isTracksGrouped
        dict["video_items"] = self.videoMenuItems.map({ return [$0.image, $0.template]})
        dict["video_tracks_items"] = self.videoTracksMenuItems.map({ return [$0.image, $0.template]})
        dict["audio_tracks_items"] = self.audioTracksMenuItems.map({ return [$0.image, $0.template]})
        
        dict["audio_handled"] = self.isAudioHandled
        dict["audio_items"] = self.audioMenuItems.map({ return [$0.image, $0.template]})
        
        dict["pdf_handled"] = self.isPDFHandled
        dict["pdf_items"] = self.pdfMenuItems.map({ return [$0.image, $0.template]})
        
        dict["office_handled"] = self.isOfficeHandled
        dict["office_deep_scan"] = self.isOfficeDeepScan
        dict["office_items"] = self.officeMenuItems.map({ return [$0.image, $0.template]})
        
        dict["3d_handled"] = self.isModelsHandled
        dict["3d_items"] = self.modelsMenuItems.map({ return [$0.image, $0.template]})
        
        dict["archive_handled"] = self.isArchiveHandled
        dict["archive_max_files"] = self.archiveMaxFiles
        dict["archive_max_depth"] = self.archiveMaxDepth
        dict["archive_max_files_in_depth"] = self.archiveMaxFilesInDepth
        dict["archive_items"] = self.archiveMenuItems.map({ return [$0.image, $0.template]})
        
        dict["folder_handled"] = self.isFolderHandled
        dict["bundle_handled"] = self.isBundleHandled
        dict["folder_max_files"] = self.folderMaxFiles
        dict["folder_max_depth"] = self.folderMaxDepth
        dict["folder_max_files_in_depth"] = self.folderMaxFilesInDepth
        dict["folder_skip_hidden_files"] = self.folderSkipHiddenFiles
        dict["folder_generic_icon"] = self.folderUsesGenericIcon
        dict["folder_action"] = self.folderAction.rawValue
        dict["folder_size_method"] = self.folderSizeMethod.rawValue
        dict["folder_items"] = self.folderMenuItems.map({ return [$0.image, $0.template]})
        
        dict["menu-action"] = self.menuAction.rawValue
        
        dict["engines"] = self.engines.map({ $0.rawValue })
        return dict
    }
    
    func getMenuItems(for type: SupportedFile) -> [MenuItem] {
        switch type {
        case .none:
            return []
        case .image:
            return self.imageMenuItems
        case .video:
            return self.videoMenuItems
        case .videoTrakcs:
            return self.videoTracksMenuItems
        case .audioTraks:
            return self.audioTracksMenuItems
        case .audio:
            return self.audioMenuItems
        case .office:
            return self.officeMenuItems
        case .model:
            return self.modelsMenuItems
        case .pdf:
            return self.pdfMenuItems
        case .archive:
            return self.archiveMenuItems
        case .folder:
            return self.folderMenuItems
        }
    }
    
    func getActionCode(for type: SupportedFile) -> String? {
        let templates = getMenuItems(for: type)
        guard let template = templates.first(where: {$0.template.hasPrefix("[[script-action:")}) else {
            return nil
        }
        guard let code = String(template.template.dropFirst(16).dropLast(2)).fromBase64() else {
            return nil
        }
        
        return code
    }
}
