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

enum MediaEngine: Int {
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

class Settings {
    static let Version = 1.5
    static func getStandardSettings() -> Settings {
        let settings = Settings(fromDict: [:])
        settings.imageMenuItems = [
            MenuItem(image: "image", template: "[[size]], [[color-depth]] [[is-animated]]"),
            MenuItem(image: "ratio", template: "[[ratio]], [[resolution]]"),
            MenuItem(image: "color", template: "[[color-depth]]"),
            MenuItem(image: "printer", template: "[[dpi]]"),
            MenuItem(image: "printer", template: "[[print:cm]]"),
            MenuItem(image: "printer", template: "[[print:cm:300]]"),
            MenuItem(image: "printer", template: "[[paper]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[filesize]]"),
        ]
        settings.videoMenuItems = [
            MenuItem(image: "video", template: "[[size]], [[duration]], [[fps]] ([[languages-flag]])"),
            MenuItem(image: "ratio", template: "[[ratio]], [[resolution]]"),
            MenuItem(image: "video", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "", template: "[[frames]]"),
            MenuItem(image: "tag", template: "[[title]]"),
            MenuItem(image: "", template: "[[frames]]"),
            MenuItem(image: "video", template: "[[video]]"),
            MenuItem(image: "audio", template: "[[audio]]"),
            MenuItem(image: "txt", template: "[[subtitles]]"),
            MenuItem(image: "chapters", template: "[[chapters]]"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[filesize]]"),
        ]
        settings.audioMenuItems = [
            MenuItem(image: "audio", template: "[[duration]] ([[seconds]]) [[channels-name]] [[language-flag]]"),
            MenuItem(image: "audio", template: "[[bitrate]], [[codec]]"),
            MenuItem(image: "tag", template: "[[title]]"),
            MenuItem(image: "", template: "([[engine]])"),
            MenuItem(image: "", template: "-"),
            MenuItem(image: "size", template: "[[filesize]]"),
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
        ]
        
        return settings
    }
    
    struct MenuItem {
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
    
    var menuWillOpenFile = true
    
    var isUsingFirstItemAsMain: Bool {
        return isInfoOnSubMenu && isInfoOnMainItem && useFirstItemAsMain
    }
    
    var isImagesHandled = true
    var imageMenuItems: [MenuItem] = []
    
    var isVideoHandled = true
    var videoMenuItems: [MenuItem] = []
    
    var isAudioHandled = true
    var audioMenuItems: [MenuItem] = []
    
    var isPDFHandled = true
    var pdfMenuItems: [MenuItem] = []
    
    var isOfficeHandled = true
    var isOfficeDeepScan = true
    var officeMenuItems: [MenuItem] = []
    
    var folders: [URL] = []
    
    var engines: [MediaEngine] = [.ffmpeg, .coremedia, .metadata]
    
    static let SharedDomainName: String = "org.sbarex.MediaInfo"
    
    init(fromDict dict: [String: AnyHashable]) {
        self.version = 0
        refresh(fromDict: dict)
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
        self.imageMenuItems = processItems(defaultsDomain["image_items"])
        
        self.isVideoHandled = defaultsDomain["video_handled"] as? Bool ?? true
        self.isTracksGrouped = defaultsDomain["group_tracks"] as? Bool ?? true
        self.videoMenuItems = processItems(defaultsDomain["video_items"])
        
        self.isAudioHandled = defaultsDomain["audio_handled"] as? Bool ?? true
        self.audioMenuItems = processItems(defaultsDomain["audio_items"])
        
        self.isPDFHandled = defaultsDomain["pdf_handled"] as? Bool ?? true
        self.pdfMenuItems   = processItems(defaultsDomain["pdf_items"])
        
        self.isOfficeHandled = defaultsDomain["office_handled"] as? Bool ?? true
        self.isOfficeDeepScan = defaultsDomain["office_deep_scan"] as? Bool ?? true
        self.officeMenuItems   = processItems(defaultsDomain["office_items"])
        
        self.menuWillOpenFile = defaultsDomain["menu-open"] as? Bool ?? true
        
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
    }
    
    func toDictionary() -> [String: AnyHashable] {
        var dict: [String: AnyHashable] = [:]
        let folders = Array(Set(self.folders.map({ $0.path })))
        dict["folders"] = folders
        
        dict["version"] = Settings.Version
        
        dict["icons"] = !self.isIconHidden
        dict["sub_menu"] = self.isInfoOnSubMenu
        dict["main_info"] = self.isInfoOnMainItem
        dict["use-first-item"] = self.useFirstItemAsMain
        dict["ratio-precise"] = self.isRatioPrecise
        dict["skip-empty"] = self.isEmptyItemsSkipped
        
        dict["image_handled"] = self.isImagesHandled
        dict["image_items"] = self.imageMenuItems.map({ return [$0.image, $0.template]})
        
        dict["video_handled"] = self.isVideoHandled
        dict["group_tracks"] = self.isTracksGrouped
        dict["video_items"] = self.videoMenuItems.map({ return [$0.image, $0.template]})
        
        dict["audio_handled"] = self.isAudioHandled
        dict["audio_items"] = self.audioMenuItems.map({ return [$0.image, $0.template]})
        
        dict["pdf_handled"] = self.isPDFHandled
        dict["pdf_items"]   = self.pdfMenuItems.map({ return [$0.image, $0.template]})
        
        dict["office_handled"] = self.isOfficeHandled
        dict["office_deep_scan"] = self.isOfficeDeepScan
        dict["office_items"]   = self.officeMenuItems.map({ return [$0.image, $0.template]})
        
        dict["menu-open"]   = self.menuWillOpenFile
        
        dict["engines"] = self.engines.map({ $0.rawValue })
        return dict
    }
}
