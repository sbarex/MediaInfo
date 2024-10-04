//
//  ViewController.swift
//  MediaInfo
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import FinderSync
import UniformTypeIdentifiers
import ExtensionKit

class WindowController: NSWindowController, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if self.window?.isDocumentEdited ?? false {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Save the settings before closing?", comment: "")
            alert.addButton(withTitle: NSLocalizedString("Save", comment: "")).keyEquivalent = "\r"
            alert.addButton(withTitle: NSLocalizedString("Don’t Save", comment: "")).keyEquivalent = "d"
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "")).keyEquivalent = "\u{1b}"
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                (self.contentViewController as? ViewController)?.saveDocument(self)
            case .alertThirdButtonReturn:
                return false
            default:
                break
            }
        }
        return true
    }
}

class ViewController: NSViewController {
    // MARK: - Outlets
    @IBOutlet weak var imagePopupButton: NSPopUpButton!
    @IBOutlet weak var imageMenuTableView: MenuTableView!
    
    @IBOutlet weak var videoPopupButton: NSPopUpButton!
    @IBOutlet weak var videoMenuTableView: MenuTableView!
    
    @IBOutlet weak var audioPopupButton: NSPopUpButton!
    @IBOutlet weak var audioMenuTableView: MenuTableView!
    
    @IBOutlet weak var pdfPopupButton: NSPopUpButton!
    @IBOutlet weak var pdfMenuTableView: MenuTableView!
    
    @IBOutlet weak var officePopupButton: NSPopUpButton!
    @IBOutlet weak var officeMenuTableView: MenuTableView!
    
    @IBOutlet weak var modelPopupButton: NSPopUpButton!
    @IBOutlet weak var modelsMenuTableView: MenuTableView!
    
    @IBOutlet weak var archivePopupButton: NSPopUpButton!
    @IBOutlet weak var archiveMenuTableView: MenuTableView!
    
    @IBOutlet weak var folderActionPopupButton: NSPopUpButton!
    @IBOutlet weak var folderMenuTableView: MenuTableView!
    @IBOutlet weak var folderPopupButton: NSPopUpButton!
    
    @IBOutlet weak var otherFormatsTableView: NSTableView!
    @IBOutlet weak var othersSegmentedControl: NSSegmentedControl!
    
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var enginesTableView: NSTableView!
    @IBOutlet weak var engineSegmentedControl: NSSegmentedControl!
    
    @IBOutlet weak var actionPopupButton: NSPopUpButton!
    
    @IBOutlet weak var externalDiskButton: NSButton!
    @IBOutlet weak var foldersTableView: NSTableView!
   
    // MARK: - Properties
    var settings: Settings = Settings.getStandardSettings() {
        willSet {
            self.willChangeValue(forKey: #keyPath(folders))
            self.willChangeValue(forKey: #keyPath(isExternalDiskHandled))
            self.willChangeValue(forKey: #keyPath(isIconHidden))
            self.willChangeValue(forKey: #keyPath(isInfoOnSubmenu))
            self.willChangeValue(forKey: #keyPath(isInfoOnMainItem))
            self.willChangeValue(forKey: #keyPath(useFirstItemAsMain))
            self.willChangeValue(forKey: #keyPath(isEmptyItemsSkipped))
            self.willChangeValue(forKey: #keyPath(isRatioRounded))
            self.willChangeValue(forKey: #keyPath(isTracksGrouped))
            self.willChangeValue(forKey: #keyPath(indexOfBytesFormat))
            self.willChangeValue(forKey: #keyPath(indexOfBitsFormat))
            self.willChangeValue(forKey: #keyPath(isMetadataExpanded))
            
            self.willChangeValue(forKey: #keyPath(isImageHandled))
            self.willChangeValue(forKey: #keyPath(isVideoHandled))
            self.willChangeValue(forKey: #keyPath(isAudioHandled))
            self.willChangeValue(forKey: #keyPath(isPDFHandled))
            self.willChangeValue(forKey: #keyPath(isOfficeHandled))
            self.willChangeValue(forKey: #keyPath(isModelsHandled))
            self.willChangeValue(forKey: #keyPath(isArchiveHandled))
            self.willChangeValue(forKey: #keyPath(maxFilesInArchive))
            self.willChangeValue(forKey: #keyPath(isFolderHandled))
            self.willChangeValue(forKey: #keyPath(isBundleHandled))
            self.willChangeValue(forKey: #keyPath(folderUsesGenericIcon))
            self.willChangeValue(forKey: #keyPath(folderSkippedHiddenFiles))
            self.willChangeValue(forKey: #keyPath(folderMaxFiles))
            self.willChangeValue(forKey: #keyPath(folderMaxFilesInDepth))
            self.willChangeValue(forKey: #keyPath(folderMaxDepth))
            
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(folders))
            self.didChangeValue(forKey: #keyPath(isExternalDiskHandled))
            self.didChangeValue(forKey: #keyPath(isIconHidden))
            self.didChangeValue(forKey: #keyPath(isInfoOnSubmenu))
            self.didChangeValue(forKey: #keyPath(isInfoOnMainItem))
            self.didChangeValue(forKey: #keyPath(useFirstItemAsMain))
            self.didChangeValue(forKey: #keyPath(isEmptyItemsSkipped))
            self.didChangeValue(forKey: #keyPath(isRatioRounded))
            self.didChangeValue(forKey: #keyPath(isTracksGrouped))
            self.didChangeValue(forKey: #keyPath(indexOfBytesFormat))
            self.didChangeValue(forKey: #keyPath(indexOfBitsFormat))
            self.didChangeValue(forKey: #keyPath(isMetadataExpanded))
            
            self.didChangeValue(forKey: #keyPath(isImageHandled))
            self.didChangeValue(forKey: #keyPath(isVideoHandled))
            self.didChangeValue(forKey: #keyPath(isAudioHandled))
            self.didChangeValue(forKey: #keyPath(isPDFHandled))
            self.didChangeValue(forKey: #keyPath(isOfficeHandled))
            self.didChangeValue(forKey: #keyPath(isModelsHandled))
            self.didChangeValue(forKey: #keyPath(isArchiveHandled))
            self.didChangeValue(forKey: #keyPath(maxFilesInArchive))
            self.didChangeValue(forKey: #keyPath(isFolderHandled))
            self.didChangeValue(forKey: #keyPath(isBundleHandled))
            self.didChangeValue(forKey: #keyPath(folderUsesGenericIcon))
            self.didChangeValue(forKey: #keyPath(folderSkippedHiddenFiles))
            self.didChangeValue(forKey: #keyPath(folderMaxFiles))
            self.didChangeValue(forKey: #keyPath(folderMaxFilesInDepth))
            self.didChangeValue(forKey: #keyPath(folderMaxDepth))
            
        }
    }
    
    @objc dynamic var isExternalDiskHandled: Bool {
        get {
            return settings.handleExternalDisk
        }
        set {
            if settings.handleExternalDisk != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isExternalDiskHandled))
            settings.handleExternalDisk = newValue
            self.didChangeValue(forKey: #keyPath(isExternalDiskHandled))
        }
    }
    
    @objc dynamic var isImageHandled: Bool {
        get {
            return settings.imageSettings.isEnabled
        }
        set {
            if settings.imageSettings.isEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isImageHandled))
            settings.imageSettings.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isImageHandled))
        }
    }
    
    @objc dynamic var isVideoHandled: Bool {
        get {
            return settings.videoSettings.isEnabled
        }
        set {
            if settings.videoSettings.isEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isVideoHandled))
            settings.videoSettings.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isVideoHandled))
        }
    }
    
    @objc dynamic var isAudioHandled: Bool {
        get {
            return settings.audioSettings.isEnabled
        }
        set {
            if settings.audioSettings.isEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isAudioHandled))
            settings.audioSettings.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isAudioHandled))
        }
    }
    
    @objc dynamic var isPDFHandled: Bool {
        get {
            return settings.pdfSettings.isEnabled
        }
        set {
            if settings.pdfSettings.isEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isPDFHandled))
            settings.pdfSettings.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isPDFHandled))
        }
    }
    
    @objc dynamic var isOfficeHandled: Bool {
        get {
            return settings.officeSettings.isEnabled
        }
        set {
            if settings.officeSettings.isEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isOfficeHandled))
            settings.officeSettings.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isOfficeHandled))
        }
    }
    
    @objc dynamic var isModelsHandled: Bool {
        get {
            return settings.modelSettings.isEnabled
        }
        set {
            if settings.modelSettings.isEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isModelsHandled))
            settings.modelSettings.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isModelsHandled))
        }
    }
    
    @objc dynamic var isArchiveHandled: Bool {
        get {
            return settings.archiveSettings.isEnabled
        }
        set {
            if settings.archiveSettings.isEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isArchiveHandled))
            settings.archiveSettings.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isArchiveHandled))
        }
    }
    
    @objc dynamic var maxFilesInArchive: Int {
        get {
            return settings.archiveSettings.maxFiles
        }
        set {
            if settings.archiveSettings.maxFiles != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(maxFilesInArchive))
            settings.archiveSettings.maxFiles = newValue
            self.didChangeValue(forKey: #keyPath(maxFilesInArchive))
        }
    }
    
    @objc dynamic var isFolderHandled: Bool {
        get {
            return settings.folderSettings.isEnabled
        }
        set {
            if settings.folderSettings.isEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isFolderHandled))
            settings.folderSettings.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isFolderHandled))
        }
    }
    
    @objc dynamic var isBundleHandled: Bool {
        get {
            return settings.folderSettings.isBundleEnabled
        }
        set {
            if settings.folderSettings.isBundleEnabled != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isBundleHandled))
            settings.folderSettings.isBundleEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isBundleHandled))
        }
    }
    
    @objc dynamic var folderUsesGenericIcon: Bool {
        get {
            return settings.folderSettings.usesGenericIcon
        }
        set {
            if settings.folderSettings.usesGenericIcon != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(folderUsesGenericIcon))
            settings.folderSettings.usesGenericIcon = newValue
            self.didChangeValue(forKey: #keyPath(folderUsesGenericIcon))
        }
    }
    @objc dynamic var folderSkippedHiddenFiles: Bool {
        get {
            return settings.folderSettings.skipHiddenFiles
        }
        set {
            if settings.folderSettings.skipHiddenFiles != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(folderSkippedHiddenFiles))
            settings.folderSettings.skipHiddenFiles = newValue
            self.didChangeValue(forKey: #keyPath(folderSkippedHiddenFiles))
        }
    }
    
    @objc dynamic var folderMaxFiles: Int {
        get {
            return settings.folderSettings.maxFiles
        }
        set {
            if settings.folderSettings.maxFiles != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(folderMaxFiles))
            settings.folderSettings.maxFiles = newValue
            self.didChangeValue(forKey: #keyPath(folderMaxFiles))
        }
    }
    
    @objc dynamic var folderMaxFilesInDepth: Int {
        get {
            return settings.folderSettings.maxDepth
        }
        set {
            if settings.folderSettings.maxFilesInDepth != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(folderMaxFilesInDepth))
            settings.folderSettings.maxFilesInDepth = newValue
            self.didChangeValue(forKey: #keyPath(folderMaxFilesInDepth))
        }
    }
    @objc dynamic var folderMaxDepth: Int {
        get {
            return settings.folderSettings.maxDepth
        }
        set {
            if settings.folderSettings.maxDepth != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(folderMaxDepth))
            settings.folderSettings.maxDepth = newValue
            self.didChangeValue(forKey: #keyPath(folderMaxDepth))
        }
    }
    
    @objc dynamic var isIconHidden: Bool {
        get {
            return settings.isIconHidden
        }
        set {
            if settings.isIconHidden != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isIconHidden))
            settings.isIconHidden = newValue
            self.didChangeValue(forKey: #keyPath(isIconHidden))
        }
    }
    
    @objc dynamic var isInfoOnSubmenu: Bool {
        get {
            return settings.isInfoOnSubMenu
        }
        set {
            if settings.isInfoOnSubMenu != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isInfoOnSubmenu))
            settings.isInfoOnSubMenu = newValue
            self.didChangeValue(forKey: #keyPath(isInfoOnSubmenu))
        }
    }
    
    @objc dynamic var isInfoOnMainItem: Bool {
        get {
            return settings.isInfoOnMainItem
        }
        set {
            if settings.isInfoOnMainItem != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isInfoOnMainItem))
            settings.isInfoOnMainItem = newValue
            self.didChangeValue(forKey: #keyPath(isInfoOnMainItem))
        }
    }
    
    @objc dynamic var useFirstItemAsMain: Bool {
        get {
            return settings.useFirstItemAsMain
        }
        set {
            if settings.useFirstItemAsMain != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(useFirstItemAsMain))
            settings.useFirstItemAsMain = newValue
            self.didChangeValue(forKey: #keyPath(useFirstItemAsMain))
        }
    }

    @objc dynamic var isEmptyItemsSkipped: Bool {
        get {
            return settings.isEmptyItemsSkipped
        }
        set {
            if settings.isEmptyItemsSkipped != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isEmptyItemsSkipped))
            settings.isEmptyItemsSkipped = newValue
            self.didChangeValue(forKey: #keyPath(isEmptyItemsSkipped))
        }
    }
    
    @objc dynamic var isRatioRounded: Bool {
        get {
            return !settings.isRatioPrecise
        }
        set {
            if settings.isRatioPrecise != !newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isRatioRounded))
            settings.isRatioPrecise = !newValue
            self.didChangeValue(forKey: #keyPath(isRatioRounded))
        }
    }
    
    @objc dynamic var indexOfBytesFormat: Int {
        get {
            return settings.bytesFormat.rawValue
        }
        set {
            let v = Settings.BytesFormat(rawValue: newValue) ?? .standard
            if settings.bytesFormat != v {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(indexOfBytesFormat))
            settings.bytesFormat = v
            self.didChangeValue(forKey: #keyPath(indexOfBytesFormat))
        }
    }
    @objc dynamic var indexOfBitsFormat: Int {
        get {
            return settings.bitsFormat.rawValue
        }
        set {
            let v = Settings.BitsFormat(rawValue: newValue) ?? .decimal
            if settings.bitsFormat != v {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(indexOfBitsFormat))
            settings.bitsFormat = v
            self.didChangeValue(forKey: #keyPath(indexOfBitsFormat))
        }
    }
    
    @objc dynamic var isMetadataExpanded: Bool {
        get {
            return settings.isMetadataExpanded
        }
        set {
            if settings.isMetadataExpanded != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isMetadataExpanded))
            settings.isMetadataExpanded = newValue
            self.didChangeValue(forKey: #keyPath(isMetadataExpanded))
        }
    }
    
    @objc dynamic var isTracksGrouped: Bool {
        get {
            return settings.isTracksGrouped
        }
        set {
            if settings.isTracksGrouped != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(isTracksGrouped))
            settings.isTracksGrouped = newValue
            self.didChangeValue(forKey: #keyPath(isTracksGrouped))
        }
    }
    
    @objc dynamic var isExtensionEnabled: Bool {
        return FIFinderSyncController.isExtensionEnabled
    }
        
    @objc var folders: [URL] {
        get {
            return settings.folders
        }
        set {
            if settings.folders != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(folders))
            settings.folders = newValue
            self.didChangeValue(forKey: #keyPath(folders))
            
            foldersTableView.reloadData()
        }
    }
    
    var representedObjects: [Int: Any] = [:]
    
    var systemActionInvoked = false
    var systemActionShowMessage = false
    
    // MARK: - Methods
    func refreshFirstItem() {
        for view in [imageMenuTableView, videoMenuTableView, audioMenuTableView, pdfMenuTableView, officeMenuTableView, modelsMenuTableView, archiveMenuTableView, folderMenuTableView] {
            view?.tableView.reloadData(forRowIndexes: IndexSet(integer: 0), columnIndexes: IndexSet(integer: 0))
        }
    }
    
    internal func initJSConsole(info: BaseInfo?) {
        guard let e = info else {
            return
        }
        let logFunction: @convention(block) ([AnyHashable]) -> Void  = { (object: [AnyHashable]) in
            let level = object.first as? String ?? "info"
            NotificationCenter.default.post(name: .JSConsole, object: (e, level, Array(object.dropFirst())))
        }
        e.jsContext?.setObject(logFunction, forKeyedSubscript: "__consoleLog" as NSString)
    }
    
    internal func initImageTab() {
        imagePopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.jpeg").resized(to: NSSize(width: 24, height: 24))
        
        imageMenuTableView.getSettings = { self.settings }
        imageMenuTableView.supportedType = .image
        imageMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenDimensional(mode: .widthHeight), TokenPrint(mode: TokenPrint.Mode.dpi)]),
            (label: NSLocalizedString("Color: ", comment: ""), tokens: [TokenColor(mode: .colorSpaceDepth)]),
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenImageExtra(mode: .animated), TokenFile(mode: .filesize), TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))])
        ]
        imageMenuTableView.validTokens = [TokenDimensional.self, TokenPrint.self, TokenColor.self, TokenFile.self, TokenImageExtra.self, TokenText.self, TokenScript.self, TokenAction.self]
        if let url = Bundle.main.url(forResource: "test", withExtension: "jpg"), let img = getCGImageInfo(forFile: url, processMetadata: true) {
            imageMenuTableView.example = img
        } else {
            imageMenuTableView.example = ImageInfo(file: Bundle.main.bundleURL, width: 1920, height: 1080, dpi: 150, colorMode: "RGB", depth: 8, profileName: "", animated: false, withAlpha: false, colorTable: .regular, metadata: [:], metadataRaw: [:])
        }
        
        do {
            let encoder = JSONEncoder()
            let d = try encoder.encode(imageMenuTableView.example)
            let decoder = JSONDecoder()
            let info = try decoder.decode(ImageInfo?.self, from: d)
            imageMenuTableView.example = info
        } catch {
            print(error)
        }
        imageMenuTableView.example?.jsDelegate = self
        imageMenuTableView.example?.actionDelegate = self
        imageMenuTableView.viewController = self
        initJSConsole(info: imageMenuTableView.example)
    }
    
    internal func initMovieTab() {
        videoPopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.mpeg-4").resized(to: NSSize(width: 24, height: 24))
        
        videoMenuTableView.getSettings = { self.settings }
        videoMenuTableView.supportedType = .video
        videoMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenDimensional(mode: .widthHeight)]),
            (label: NSLocalizedString("Length: ", comment: ""), tokens: [TokenDuration(mode: .hours)]),
            (label: NSLocalizedString("Language: ", comment: ""), tokens: [TokenLanguages(mode: .flags)]),
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenMediaExtra(mode: .codec_short_name), TokenVideoMetadata(mode: .frames), TokenMediaTrack(mode: .video), TokenFile(mode: .filesize), TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))]),
        ]
        videoMenuTableView.validTokens = [TokenDimensional.self, TokenDuration.self, TokenLanguages.self, TokenMediaExtra.self, TokenFile.self, TokenVideoMetadata.self, TokenMediaTrack.self, TokenText.self, TokenScript.self, TokenAction.self]
        
        if let url = Bundle.main.url(forResource: "test", withExtension: "mp4"), let video = getCMVideoInfo(forFile: url) {
            videoMenuTableView.example = video
        } else {
            videoMenuTableView.example = VideoInfo(
                file: Bundle.main.bundleURL,
                width: 1920, height: 1080,
                duration: 3600, start_time: -1,
                codec_short_name: "hevc", codec_long_name: "H265 / HEVC",
                profile: "Main",
                pixel_format: .argb, color_space: .smpte240m, field_order: .topFirst,
                lang: "EN",
                bitRate: 1024*1024, fps: 24,
                frames: 3600*25,
                title: "Movie title",
                encoder: "Encoder",
                isLossless: false,
                chapters: [Chapter(title: "title1", start: 0, end: 200), Chapter(title: "title2", start: 201, end: 600)],
                video: [
                    VideoTrackInfo(width: 1920, height: 1080, duration: 3600, start_time: 0, codec_short_name: "Codec", codec_long_name: "Codec long name", profile: "Main", pixel_format: VideoTrackInfo.VideoPixelFormat.argb, color_space: nil, field_order: VideoTrackInfo.VideoFieldOrder.progressive, lang: nil, bitRate: 1024*1024, fps: 24, frames: 3600*25, title: nil, encoder: nil, isLossless: nil)
                ],
                audio: [
                    AudioTrackInfo(duration: 3600, start_time: 0, codec_short_name: "mp3", codec_long_name: "MP3 (MPEG audio layer 3)", lang: "EN", bitRate: 512*1025, sampleRate: 44100, title: "Audio title", encoder: "Encoder", isLossless: false, channels: 2)
                ], subtitles: [
                    SubtitleTrackInfo(title: "English subtitle", lang: "EN"),
                    SubtitleTrackInfo(title: "Sottitoli in italiano", lang: "IT"),
                ],
                engine: .coremedia
                )
        }
        
        videoMenuTableView.example?.jsDelegate = self
        videoMenuTableView.example?.actionDelegate = self
        videoMenuTableView.viewController = self
        initJSConsole(info: videoMenuTableView.example)
    }
    
    internal func initAudioTab() {
        audioPopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.mp3").resized(to: NSSize(width: 24, height: 24))
        
        audioMenuTableView.getSettings = { self.settings }
        audioMenuTableView.supportedType = .audio
        audioMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Length: ", comment: ""), tokens: [TokenDuration(mode: .hours)]),
            (label: NSLocalizedString("Language: ", comment: ""), tokens: [TokenLanguage(mode: .flag)]),
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenMediaExtra(mode: .codec_short_name), TokenFile(mode: .filesize), TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))]),
            (label: NSLocalizedString("Metadata: ", comment: ""), tokens: [TokenAudioMetadata(mode: .title)])
        ]
        audioMenuTableView.validTokens = [TokenDuration.self, TokenLanguage.self, TokenMediaExtra.self, TokenFile.self, TokenAudioMetadata.self, TokenText.self, TokenScript.self, TokenAction.self]
        if let url = Bundle.main.url(forResource: "test", withExtension: "mp3") {
            audioMenuTableView.example = getCMAudioInfo(forFile: url)
        } else {
            audioMenuTableView.example = AudioInfo(
                file: Bundle.main.bundleURL,
                duration: 45, start_time: -1,
                codec_short_name: "mp3", codec_long_name: "MP3 (MPEG audio layer 3)",
                lang: "EN",
                bitRate: 512*1024,
                sampleRate: 44100,
                title: "Audio title", encoder: "Encoder",
                isLossless: false,
                chapters: [],
                channels: 2,
                engine: .coremedia)
        }
        
        audioMenuTableView.example?.jsDelegate = self
        audioMenuTableView.example?.actionDelegate = self
        audioMenuTableView.viewController = self
        initJSConsole(info: audioMenuTableView.example)
    }
    
    internal func initAcrobatTab() {
        pdfPopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "com.adobe.pdf").resized(to: NSSize(width: 24, height: 24))
        
        pdfMenuTableView.getSettings = { self.settings }
        pdfMenuTableView.supportedType = .pdf
        pdfMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenPdfBox(mode: .mediaBox, unit: .pt), TokenPdfBox(mode: .bleedBox, unit: .pt), TokenPdfBox(mode: .cropBox, unit: .pt), TokenPdfBox(mode: .artBox, unit: .pt)]),
            (label: NSLocalizedString("Metadata: ", comment: ""), tokens: [TokenPdfMetadata(mode: .pages)]),
            (label: NSLocalizedString("Extra", comment: ""), tokens: [TokenFile(mode: .filesize), TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))])
        ]
        pdfMenuTableView.validTokens = [TokenPdfBox.self, TokenPdfMetadata.self, TokenFile.self, TokenText.self, TokenScript.self, TokenAction.self]
        if let url = Bundle.main.url(forResource: "test", withExtension: "pdf"), let pdf = CGPDFDocument(url as CFURL) {
            pdfMenuTableView.example = PDFInfo(file: url, pdf: pdf)
        }
        
        pdfMenuTableView.example?.jsDelegate = self
        pdfMenuTableView.example?.actionDelegate = self
        pdfMenuTableView.viewController = self
        initJSConsole(info: pdfMenuTableView.example)
    }
    
    internal func initOfficeTab() {
        officePopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "org.openxmlformats.wordprocessingml.document").resized(to: NSSize(width: 24, height: 24))
        
        officeMenuTableView.getSettings = { self.settings }
        officeMenuTableView.supportedType = .office
        officeMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenOfficeSize(mode: .print_paper_cm)]),
            (label: NSLocalizedString("Metadata: ", comment: ""), tokens: [TokenOfficeMetadata(mode: .pages), TokenFile(mode: .filesize)]),
            (label: NSLocalizedString("Extra", comment: ""), tokens: [ TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))])
        ]
        officeMenuTableView.validTokens = [TokenOfficeSize.self, TokenOfficeMetadata.self, TokenFile.self, TokenText.self, TokenScript.self, TokenAction.self]
        officeMenuTableView.example = WordInfo(file: Bundle.main.bundleURL, charactersCount: 1765, charactersWithSpacesCount: 2000, wordsCount: 123, pagesCount: 3, creator: "sbarex", creationDate: Date(timeIntervalSinceNow: -60*60), modified: "sbarex", modificationDate: Date(timeIntervalSinceNow: 0), title: "Title", subject: "Subject", keywords: ["key1", "key2"], description: "Description", application: "Microsoft Word", width: 21/2.54, height: 29.7/2.54)
        
        officeMenuTableView.example?.jsDelegate = self
        officeMenuTableView.example?.actionDelegate = self
        officeMenuTableView.viewController = self
        initJSConsole(info: officeMenuTableView.example)
    }
    
    internal func initModelTab() {
        modelPopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.polygon-file-format").resized(to: NSSize(width: 24, height: 24))
        
        /*
         TODO: Implement 3D support.
        modelsMenuTableView.getSettings = { self.settings }
        modelsMenuTableView.supportedType = .model
        modelsMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Metadata: ", comment: ""), tokens: [TokenModelMetadata(mode: .meshCount), TokenFile(mode: .filesize)])
        ]
        modelsMenuTableView.validTokens = [TokenModelMetadata.self, TokenText.self, TokenFile.self, TokenScript.self, TokenOpenWidth.self]
        modelsMenuTableView.example = ModelInfo(parseModel: Bundle.main.url(forResource: "test", withExtension: "obj")!) ?? ModelInfo(parseModel: Bundle.main.bundleURL, meshes: [ModelInfo.Mesh(name: "mesh1", vertexCount: 2040, hasNormals: true, hasTangent: false, hasTextureCoordinate: true, hasVertexColor: false, hasOcclusion: false)]),
         (label: NSLocalizedString("Extra", comment: ""), tokens: [ TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))])
        */
        if let t = tabView.tabViewItems.first(where: { $0.identifier as? String == "3D"}) {
            // Hide the 3D tab.
            tabView.removeTabViewItem(t)
        }
        
        modelsMenuTableView.example?.jsDelegate = self
        modelsMenuTableView.example?.actionDelegate = self
        modelsMenuTableView.viewController = self
        initJSConsole(info: modelsMenuTableView.example)
    }
    
    internal func initArchiveTab() {
        archivePopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.zip-archive").resized(to: NSSize(width: 24, height: 24))
        
        archiveMenuTableView.getSettings = { self.settings }
        archiveMenuTableView.supportedType = .archive
        archiveMenuTableView.sampleTokens = [
            // (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenArchive(mode: .compressionMethod)]),
            (label: NSLocalizedString("Files: ", comment: ""), tokens: [TokenArchive(mode: .files)]),
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [ TokenFile(mode: .filesize), TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))])
        ]
        archiveMenuTableView.validTokens = [TokenArchive.self, TokenFile.self, TokenScript.self, TokenAction.self]
        archiveMenuTableView.example = try? ArchiveInfo(file: Bundle.main.url(forResource: "test", withExtension: "zip")!)
        
        archiveMenuTableView.example?.jsDelegate = self
        archiveMenuTableView.example?.actionDelegate = self
        archiveMenuTableView.viewController = self
        initJSConsole(info: archiveMenuTableView.example)
    }
    
    internal func initFolderTab() {
        folderPopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: kUTTypeFolder as String).resized(to: NSSize(width: 24, height: 24))
        
        folderMenuTableView.getSettings = { self.settings }
        folderMenuTableView.supportedType = .folder
        folderMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Files: ", comment: ""), tokens: [TokenFolder(mode: .files)]),
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenFile(mode: .filesize), TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))])
        ]
        folderMenuTableView.validTokens = [TokenFolder.self, TokenFile.self, TokenScript.self, TokenAction.self]
        folderMenuTableView.example = FolderInfo(
            folder: Bundle.main.bundleURL,
            maxFiles: self.folderMaxFiles,
            maxDepth: self.folderMaxDepth,
            maxFilesInDepth: self.folderMaxFilesInDepth,
            skipHidden: self.folderSkippedHiddenFiles,
            skipBundle: !self.isBundleHandled,
            useGenericIcon: self.folderUsesGenericIcon,
            sizeMode: .full
        )
        
        folderMenuTableView.example?.jsDelegate = self
        folderMenuTableView.example?.actionDelegate = self
        folderMenuTableView.viewController = self
        initJSConsole(info: folderMenuTableView.example)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reset()
        
        BaseInfo.debugJS = true
        
        initImageTab()
        initMovieTab()
        initAudioTab()
        initAcrobatTab()
        initOfficeTab()
        initModelTab()
        initArchiveTab()
        initFolderTab()
        
        enginesTableView.registerForDraggedTypes([NSPasteboard.PasteboardType("private.table-row-engine")])
        updateEngineSegmentedControl()
        otherFormatsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType("private.table-row-format")])
        updateFormatsSegmentedControl()
        
        DispatchQueue.main.async {
            if !FIFinderSyncController.isExtensionEnabled {
                let p = NSAlert()
                p.messageText = NSLocalizedString("Finder extension not enabled!", comment: "")
                // p.informativeText = "The finder sync extension is not enabled."
                p.alertStyle = .warning
                p.addButton(withTitle: NSLocalizedString("Open System Settings", comment: ""))
                p.addButton(withTitle: NSLocalizedString("Ignore", comment: "")).keyEquivalent = "\u{1b}" // esc
                
                let os = ProcessInfo().operatingSystemVersion
                switch (os.majorVersion, os.minorVersion, os.patchVersion) {
                case (15, 0, _):
                    p.addButton(withTitle: NSLocalizedString("Note on macOS Sequoia…", comment: ""))
                default:
                    break
                }
                
                switch p.runModal() {
                case .alertFirstButtonReturn:
                    FIFinderSyncController.showExtensionManagementInterface()
                case .alertThirdButtonReturn:
                    NSWorkspace.shared.open(URL(string: "https://github.com/sbarex/MediaInfo/blob/master/README.md#note-for-macos-sequoia")!)
                default:
                    break;
                }
            }
        }
    }
    
    @IBAction func doChangeFolder(_ sender: NSSegmentedControl) {
        if sender.indexOfSelectedItem == 0 {
            let dialog = NSOpenPanel();
            
            dialog.showsResizeIndicator    = true
            dialog.showsHiddenFiles        = false
            dialog.canChooseDirectories    = true
            dialog.canChooseFiles = false
            dialog.canCreateDirectories    = false
            dialog.allowsMultipleSelection = false

            if (dialog.runModal() == NSApplication.ModalResponse.OK) {
                if let result = dialog.url {
                    self.folders.append(result)
                    self.folders.sort(by: { $0.path < $1.path })
                    self.foldersTableView.reloadData()
                    self.view.window?.isDocumentEdited = true
                }
            } else {
                // User clicked on "Cancel"
                return
            }
        } else if sender.indexOfSelectedItem == 1 {
            guard foldersTableView.selectedRow >= 0 else {
                return
            }
            self.folders.remove(at: foldersTableView.selectedRow)
            self.view.window?.isDocumentEdited = true
            self.foldersTableView.reloadData()
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
    
    @IBAction func doSave(_ sender: Any) {
        if Set(self.folders).isEmpty {
            let p = NSAlert()
            p.messageText = NSLocalizedString("No folders selected to be monitored", comment: "")
            p.informativeText = NSLocalizedString("Are you sure you want to continue?", comment: "")
            p.alertStyle = .warning
            p.addButton(withTitle: NSLocalizedString("Continue", comment: "")).keyEquivalent="\r"
            p.addButton(withTitle: NSLocalizedString("Cancel", comment: "")).keyEquivalent = "\u{1b}" // esc
            let r = p.runModal()
            if r == .alertSecondButtonReturn {
                return
            }
        }
        
        for format in Settings.SupportedFile.allCases {
            if let items = settings.getFormatSettings(for: format)?.templates {
                format.infoClass.updateSettings(settings, forItems: items)
            }
        }
        
        SettingsWrapper.setSettings(settings) { status in
            DispatchQueue.main.async {
                guard status else {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Unable to save the settings!", comment: "")
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: NSLocalizedString("Close", comment: ""))
                    if let window = self.view.window {
                        alert.beginSheetModal(for: window, completionHandler: nil)
                    } else {
                        alert.runModal()
                    }
                    return
                }
                self.view.window?.isDocumentEdited = false
                
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Settings saved", comment: "")
                alert.alertStyle = .informational
                alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                if let window = self.view.window {
                    alert.beginSheetModal(for: window, completionHandler: nil)
                } else {
                    alert.runModal()
                }
            }
        }
    }
    
    func initFromSettings(_ settings: Settings) {
        DispatchQueue.main.async {
            self.settings = settings
            
            self.foldersTableView.reloadData()
            self.enginesTableView.reloadData()
            
            switch settings.menuAction {
            case .none: self.actionPopupButton.selectItem(at: 0)
            case .open: self.actionPopupButton.selectItem(at: 1)
            }
            
            self.imageMenuTableView.formatSettings = settings.imageSettings
            self.videoMenuTableView.formatSettings = settings.videoSettings
            self.audioMenuTableView.formatSettings = settings.audioSettings
            self.pdfMenuTableView.formatSettings = settings.pdfSettings
            self.officeMenuTableView.formatSettings = settings.officeSettings
            self.modelsMenuTableView.formatSettings = settings.modelSettings
            self.archiveMenuTableView.formatSettings = settings.archiveSettings
            self.folderMenuTableView.formatSettings = settings.folderSettings
            switch settings.folderSettings.action {
            case .standard: self.folderActionPopupButton.selectItem(at: 0)
            case .openFile: self.folderActionPopupButton.selectItem(at: 1)
            case .revealFile: self.folderActionPopupButton.selectItem(at: 2)
            }
            self.otherFormatsTableView.reloadData()
            
            self.view.window?.isDocumentEdited = false
        }
    }
    
    func reset() {
        SettingsWrapper.getSettings(withReply: {
            self.initFromSettings($0)
        })
    }
    
    @IBAction func revertDocumentToSaved(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Are you sure to revert to the original saved settings?", comment: "")
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("Yes", comment: "")) // .keyEquivalent = "\r"
        alert.addButton(withTitle: NSLocalizedString("No", comment: "")).keyEquivalent = "\u{1b}"
        alert.beginSheetModal(for: self.view.window!) { result in
            guard result == .alertFirstButtonReturn else {
                return
            }
            
            self.reset()
        }
    }
    
    @IBAction func saveDocument(_ sender: Any) {
        doSave(sender)
    }
    
    @IBAction func resetToStandardSettings(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Are you sure to reset the current settings to the standar values?", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "")).keyEquivalent = "\r"
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "")).keyEquivalent = "\u{1b}"
        let r = alert.runModal()
        guard r == .alertFirstButtonReturn else {
            return
        }
        let settings = Settings.getStandardSettings()
        settings.folders = self.folders
        initFromSettings(settings)
        DispatchQueue.main.async {
            self.view.window?.isDocumentEdited = true
        }
    }
    
    @IBAction func openSystemPreferences(_ sender: Any) {
        let os = ProcessInfo().operatingSystemVersion
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case (15, 0, _):
            let panel = NSAlert()
            panel.alertStyle = .warning
            panel.informativeText = NSLocalizedString("On macOS Sequoia 15.0 the System interface to handle the Finder Extension is missing!", comment: "")
            panel.addButton(withTitle: NSLocalizedString("Show more info…", comment: "")).keyEquivalent = "\r"
            panel.addButton(withTitle: NSLocalizedString("Open System Settings", comment: ""))
            panel.addButton(withTitle: NSLocalizedString("Cancel", comment: "")).keyEquivalent = "\u{1b}" // esc
            
            switch panel.runModal() {
            case .alertFirstButtonReturn:
                NSWorkspace.shared.open(URL(string: "https://github.com/sbarex/MediaInfo/blob/master/README.md#note-for-macos-sequoia")!)
            case .alertSecondButtonReturn:
                FIFinderSyncController.showExtensionManagementInterface()
            case .alertThirdButtonReturn:
                break;
            default:
                break
            }
        default:
            FIFinderSyncController.showExtensionManagementInterface()
        }
    }
    
    func getTemplate(fromTokens tokens: [Token]) -> String {
        var template = ""
        for token in tokens {
            template += token.placeholder
        }
        return template
    }
    
    @IBAction func handleMenuActionChanged(_ sender: NSPopUpButton) {
        switch self.actionPopupButton.indexOfSelectedItem {
        case 0: self.settings.menuAction = .none
        case 1: self.settings.menuAction = .open
        default: self.settings.menuAction = .none
        }
    }
    
    @IBAction func handleFolderActionChanged(_ sendeR: NSPopUpButton) {
        switch self.folderActionPopupButton.indexOfSelectedItem {
        case 0: settings.folderSettings.action = .standard
        case 1: settings.folderSettings.action = .openFile
        case 2: settings.folderSettings.action = .revealFile
        default:
            settings.folderSettings.action = .standard
        }
    }
    
    @IBAction func handleEngineSegmentedControl(_ sender: NSSegmentedControl) {
        let index = enginesTableView.selectedRow
        switch sender.selectedSegment {
        case 0: // up
            guard index > 0 else {
                return
            }
            enginesTableView.beginUpdates()
            enginesTableView.moveRow(at: index, to: index - 1)
            self.settings.engines.move(from: index, to: index - 1)
            enginesTableView.endUpdates()
            enginesTableView.selectRowIndexes(IndexSet(integer: index-1), byExtendingSelection: false)
            self.view.window?.isDocumentEdited = true
            updateEngineSegmentedControl()
        case 1: // down
            guard index < self.settings.engines.count - 1 else {
                return
            }
            enginesTableView.beginUpdates()
            enginesTableView.moveRow(at: index, to: index + 1)
            self.settings.engines.move(from: index, to: index + 1)
            enginesTableView.endUpdates()
            enginesTableView.selectRowIndexes(IndexSet(integer: index+1), byExtendingSelection: false)
            self.view.window?.isDocumentEdited = true
            updateEngineSegmentedControl()
        default:
            break
        }
    }
    
    internal func presentCustomFormatEditor(row: Int) {
        let custom: Settings.FormatSettings
        
        if row == self.settings.customFormatsSettings.count {
            custom = self.settings.otherFormatsSettings
        } else {
            if row < 0 {
                custom = Settings.CustomFormatSettings(uti: "", templates: [], triggers: [:])
            } else {
                custom = self.settings.customFormatsSettings[row]
            }
        }
        
        guard let vc = NSStoryboard.main?.instantiateController(withIdentifier: "CustomFormatViewController") as? CustomFormatViewController else {
            return
        }
        
        vc.settings = self.settings
        vc.formatSettings = custom
        vc.jsDelegate = self
        
        vc.onSave = { _ in
            DispatchQueue.main.async {
                if row >= 0 {
                    self.otherFormatsTableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integersIn: 0...0))
                } else {
                    let index = self.otherFormatsTableView.selectedRow
                    if let custom = custom as? Settings.CustomFormatSettings {
                        if index >= 0 && index < self.settings.customFormatsSettings.count {
                            self.settings.customFormatsSettings.insert(custom, at: index+1)
                            self.otherFormatsTableView.insertRows(at: IndexSet(integer: index+1), withAnimation: .slideDown)
                            self.otherFormatsTableView.selectRowIndexes(IndexSet(integer: index+1), byExtendingSelection: false)
                        } else {
                            self.settings.customFormatsSettings.append(custom)
                            self.otherFormatsTableView.insertRows(at: IndexSet(integer: self.settings.customFormatsSettings.count - 1), withAnimation: .slideDown)
                            self.otherFormatsTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                        }
                    }
                }
                
                self.view.window?.isDocumentEdited = true
            }
        }
        // self.presentAsModalWindow(vc)
        self.presentAsSheet(vc)
    }
    func confirmRemoveItem(action: @escaping ()->Void) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Are you sure to remove this item?", comment: "")
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: NSLocalizedString("Remove", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.beginSheetModal(for: self.view.window!) { r in
            if r == .alertFirstButtonReturn {
                action()
            }
        }
    }
    
    @IBAction func handleOthersSegmentedControl(_ sender: NSSegmentedControl) {
        let index = otherFormatsTableView.selectedRow
        let n = settings.customFormatsSettings.count
        
        switch sender.selectedSegment {
        case 0: // add
            self.presentCustomFormatEditor(row: -1)
        case 1: // remove
            guard index >= 0 && index < settings.customFormatsSettings.count else {
                return
            }
            confirmRemoveItem() {
                self.otherFormatsTableView.beginUpdates()
                self.settings.customFormatsSettings.remove(at: index)
                self.otherFormatsTableView.removeRows(at: IndexSet(integer: index), withAnimation: .slideUp)
                self.otherFormatsTableView.endUpdates()
                
                self.view.window?.isDocumentEdited = true
                self.updateFormatsSegmentedControl()
            }
        case 2: // edit
            self.presentCustomFormatEditor(row: index)
        case 3: // duplicate
            guard index >= 0 else {
                return
            }
            let format: Settings.CustomFormatSettings
            if index == n {
                let f = settings.otherFormatsSettings.copy()!
                var triggers: [Settings.TriggerName: Settings.Trigger] = [:]
                for trigger in f.triggers {
                    triggers[trigger.key] = trigger.value.copy()
                }
                format = Settings.CustomFormatSettings(uti: "", templates: f.templates, triggers: triggers)
            } else {
                format = settings.customFormatsSettings[index].copy()!
            }
            self.otherFormatsTableView.beginUpdates()
            settings.customFormatsSettings.insert(format, at: index)
            self.otherFormatsTableView.insertRows(at: IndexSet(integer: index), withAnimation: .slideDown)
            self.otherFormatsTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            self.otherFormatsTableView.endUpdates()
            
        case 4: // up
            guard index > 0 && index < n else {
                return
            }
            otherFormatsTableView.beginUpdates()
            otherFormatsTableView.moveRow(at: index, to: index - 1)
            self.settings.customFormatsSettings.move(from: index, to: index - 1)
            otherFormatsTableView.endUpdates()
            otherFormatsTableView.selectRowIndexes(IndexSet(integer: index-1), byExtendingSelection: false)
            updateFormatsSegmentedControl()
            self.view.window?.isDocumentEdited = true
        case 5: // down
            guard index>=0 && index < n-1 else {
                return
            }
            otherFormatsTableView.beginUpdates()
            otherFormatsTableView.moveRow(at: index, to: index + 1)
            self.settings.customFormatsSettings.move(from: index, to: index + 1)
            otherFormatsTableView.endUpdates()
            otherFormatsTableView.selectRowIndexes(IndexSet(integer: index+1), byExtendingSelection: false)
            updateFormatsSegmentedControl()
            self.view.window?.isDocumentEdited = true
        default:
            break
        }
    }
    
    func updateEngineSegmentedControl() {
        engineSegmentedControl.setEnabled(enginesTableView.selectedRow > 0, forSegment: 0)
        engineSegmentedControl.setEnabled(enginesTableView.selectedRow >= 0 && enginesTableView.selectedRow < self.settings.engines.count - 1, forSegment: 1)
    }
    
    func updateFormatsSegmentedControl() {
        let index = otherFormatsTableView.selectedRow
        let n = settings.customFormatsSettings.count
        othersSegmentedControl.setEnabled(index >= 0 && index != n, forSegment: 1)
        othersSegmentedControl.setEnabled(index >= 0 , forSegment: 2)
        othersSegmentedControl.setEnabled(index >= 0, forSegment: 3)
        othersSegmentedControl.setEnabled(index > 0 && index != n, forSegment: 4)
        othersSegmentedControl.setEnabled(index>=0 && index < n-1, forSegment: 5)
    }
    
    @IBAction func handleOtherFormatsTableDoubleClick(_ sender: NSTableView) {
        self.presentCustomFormatEditor(row: sender.clickedRow)
    }
    
    @objc internal func fakeMenuAction(_ sender: NSMenuItem) {
        // This function is never executed but is required to enable the menu item of the dropdown for the custom formats.
        // The function of the same name of the baseinfo object that generated the menu will be executed.
        print(sender)
    }
}

// MARK: - NSTableViewDataSource
extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView.identifier?.rawValue {
        case "engines": return self.settings.engines.count
        case "folders": return self.folders.count
        case "formats": return self.settings.customFormatsSettings.count + 1
        default: return 0
        }
    }
}

// MARK: - NSTableViewDelegate
extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableView.identifier?.rawValue {
        case "engines":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EngineCell"), owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = self.settings.engines[row].label
            return cell
        case "folders":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:  tableColumn?.identifier.rawValue == "image" ? "ImageCell" : "TextCell"), owner: nil) as? NSTableCellView
            
            if tableColumn?.identifier.rawValue == "image" {
                cell?.imageView?.image = NSWorkspace.shared.icon(forFile: self.folders[row].path)
            } else {
                cell?.textField?.stringValue = self.folders[row].path
            }
            return cell
        case "formats":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FormatCell"), owner: nil) as? FormatCellView
            let n = settings.customFormatsSettings.count
            if row == n {
                cell?.uti = nil
                cell?.switchView.state = self.settings.otherFormatsSettings.isEnabled ? .on : .off
                cell?.action = {
                    self.settings.otherFormatsSettings.isEnabled = !self.settings.otherFormatsSettings.isEnabled
                }
            } else {
                cell?.uti = settings.customFormatsSettings[row].uti
                cell?.switchView.state = settings.customFormatsSettings[row].isEnabled ? .on : .off
                cell?.action = {
                    self.settings.customFormatsSettings[row].isEnabled = !self.settings.customFormatsSettings[row].isEnabled
                }
            }
            cell?.popupButton.menu?.delegate = self
            
            return cell
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        switch tableView.identifier?.rawValue ?? "" {
        case "engines":
            item.setString(String(row), forType: NSPasteboard.PasteboardType(rawValue: "private.table-row-engine"))
        case "formats":
            guard row < self.settings.customFormatsSettings.count else {
                return nil
            }
            item.setString(String(row), forType: NSPasteboard.PasteboardType(rawValue: "private.table-row-format"))
        default:
            return nil
        }
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        switch tableView.identifier?.rawValue ?? "" {
        case "engines", "formats":
            if dropOperation == .above {
                return .move
            }
        default:
            break
        }
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let type: NSPasteboard.PasteboardType
        let move: (Int, Int)->Void
        let validate: (Int, Int) -> Bool
        let update: ()->Void
        switch tableView.identifier?.rawValue ?? "" {
        case "engines":
            type = NSPasteboard.PasteboardType(rawValue: "private.table-row-engine")
            move = { oldRow, newRow in
                self.settings.engines.move(from: oldRow, to: newRow)
            }
            validate = { _, _ in
                return true
            }
            update = {
                self.updateEngineSegmentedControl()
            }
        case "formats":
            type = NSPasteboard.PasteboardType(rawValue: "private.table-row-format")
            move = { oldRow, newRow in
                self.settings.customFormatsSettings.move(from: oldRow, to: newRow)
            }
            validate = { oldRow, newRow in
                return newRow < self.settings.customFormatsSettings.count
            }
            update = {
                self.updateFormatsSegmentedControl()
            }
        default:
            return false
        }
        
        var oldIndexes = [Int]()
        info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:]) { item, _, _ in
            if let str = (item.item as! NSPasteboardItem).string(forType: type), let index = Int(str) {
                oldIndexes.append(index)
            }
        }

        var oldIndexOffset = 0
        var newIndexOffset = 0
        
        var changed = false
        tableView.beginUpdates()
        defer {
            tableView.endUpdates()
            if changed {
                self.view.window?.isDocumentEdited = true
            }
            update()
        }
        for oldIndex in oldIndexes {
            let oldRow, newRow: Int
            if oldIndex < row {
                oldRow = oldIndex + oldIndexOffset
                newRow = row - 1
            
                oldIndexOffset -= 1
            } else {
                oldRow = oldIndex
                newRow = row + newIndexOffset
                
                newIndexOffset += 1
            }
            if !validate(oldRow, newRow) {
                return false
            }
            tableView.moveRow(at: oldRow, to: newRow)
            move(oldRow, newRow)
            changed = true
        }
        
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let t = notification.object as? NSTableView else {
            return
        }
        switch t.identifier?.rawValue ?? "" {
        case "engines":
            updateEngineSegmentedControl()
        case "formats":
            updateFormatsSegmentedControl()
        default:
            return
        }
    }
    
}

// MARK: - NSMenuDelegate
extension ViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        while menu.items.count > 1 {
            menu.removeItem(at: 1)
        }
        guard let menu_identifier = menu.identifier?.rawValue else {
            return
        }
        let itemSettings: Settings.FormatSettings
        let menuTableView: MenuTableView?
        let example: FileInfo?
        switch menu_identifier {
        case "mnu_image":
            menuTableView = imageMenuTableView
            itemSettings = settings.imageSettings
            example = menuTableView?.example as? FileInfo
        case "mnu_video":
            menuTableView = videoMenuTableView
            itemSettings = settings.videoSettings
            example = menuTableView?.example as? FileInfo
        case "mnu_audio":
            menuTableView = audioMenuTableView
            itemSettings = settings.audioSettings
            example = menuTableView?.example as? FileInfo
        case "mnu_pdf":
            menuTableView = pdfMenuTableView
            itemSettings = settings.pdfSettings
            example = menuTableView?.example as? FileInfo
        case "mnu_office":
            menuTableView = officeMenuTableView
            itemSettings = settings.officeSettings
            example = menuTableView?.example as? FileInfo
        case "mnu_model":
            menuTableView = modelsMenuTableView
            itemSettings = settings.modelSettings
            example = menuTableView?.example as? FileInfo
        case "mnu_archive":
            menuTableView = archiveMenuTableView
            itemSettings = settings.archiveSettings
            example = menuTableView?.example as? FileInfo
        case "mnu_folder":
            menuTableView = folderMenuTableView
            itemSettings = settings.folderSettings
            example = menuTableView?.example as? FileInfo
        default:
            menuTableView = nil
            if menu_identifier.isEmpty {
                itemSettings = settings.otherFormatsSettings
                example = FakeFileInfo(file: URL(fileURLWithPath: "/tmp/test"), fileSize: 1024, fileSizeFull: 1036, fileCreationDate: Date(timeIntervalSinceNow: -60*5), fileModificationDate: Date(timeIntervalSinceNow: -60), fileAccessDate: Date(), uti: "public.item", utiConformsToType: ["public.data"])
                example?.actionDelegate = self
                example?.jsDelegate = self
            } else {
                if let uti_settings = settings.customFormatsSettings.first(where: {$0.uti == menu_identifier }) {
                    itemSettings = uti_settings
                    var path = "/tmp/test"
                    if let ext = uti_settings.associatedExtension {
                        path += ".\(ext)"
                    }
                    example = FakeFileInfo(file: URL(fileURLWithPath: path), fileSize: 1024, fileSizeFull: 1036, fileCreationDate: Date(timeIntervalSinceNow: -60*5), fileModificationDate: Date(timeIntervalSinceNow: -60), fileAccessDate: Date(), uti: uti_settings.uti, utiConformsToType: uti_settings.conformsToUTI)
                    example?.actionDelegate = self
                    example?.jsDelegate = self
                } else {
                    return
                }
            }
        }
        guard let example = example else {
            return
        }
        example.initSettings(withItemSettings: itemSettings, globalSettings: self.settings)
        
        do {
            let r = try type(of: example).evaluateTriggerValidate(example.currentSettings?.triggers[.validate], for: example.file, globalSettings: self.settings, jsDelegate: self)
            guard r else {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = NSLocalizedString("The validate trigger has aborted the menu generation.", comment: "")
                alert.runModal()
                return
            }
        } catch {
            if let error = error as? BaseInfo.JSTriggerError {
                menuTableView?.triggers_error_validate = error
            }
        }
        guard let menu_example = example.getMenu(withItemSettings: itemSettings, globalSettings: self.settings) else {
            return
        }
        self.representedObjects = BaseInfo.preprocessMenu(menu_example)
        
        if settings.isInfoOnSubMenu, let item = menu_example.items.first {
            let mnu = menu.addItem(withTitle: item.title, action: nil, keyEquivalent: "")
            mnu.tag = item.tag
            mnu.representedObject = item.representedObject
            mnu.image = item.image
            if let submenu = item.submenu?.copy() as? NSMenu, !submenu.items.isEmpty {
                menu.setSubmenu(submenu, for: mnu)
            } else {
                menu.setSubmenu(nil, for: mnu)
            }
        }  else {
            for item in menu_example.items {
                menu.addItem(item.copy() as! NSMenuItem)
            }
        }
    }
}

// MARK: - JSDelegate
protocol FakeJSDelegate: JSDelegate, ActionDelegate {
    var systemActionShowMessage: Bool { get set }
    var systemActionInvoked: Bool { get set }
    var representedObjects: [Int: Any] { get set }
    var settings: Settings { get }
}

extension FakeJSDelegate {
    func jsOpen(path: String, reply: @escaping (Bool)->Void) {
        systemActionInvoked = true
        if systemActionShowMessage {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = NSLocalizedString("Opening a file/url", comment: "")
                alert.informativeText = String(format: NSLocalizedString("This action will open the %@ with the default application.", comment: ""), path)
                alert.runModal()
            }
        }
        reply(false)
        /*
        let r = NSWorkspace.shared.open(URL(fileURLWithPath: path))
        reply(r)
        */
    }
    func jsOpen(path: String, with app: String, reply: @escaping (Bool, String?)->Void) {
        systemActionInvoked = true
        if systemActionShowMessage {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = NSLocalizedString("Opening a file", comment: "")
                alert.informativeText = String(format: NSLocalizedString("This action will open the file %@ with the %@ application.", comment: ""), path, app)
                alert.runModal()
            }
        }
        reply(false, NSLocalizedString("Implemented only from the Finder extension.", comment: ""))
        
        /*
        let url = URL(fileURLWithPath: path)
        let conf = NSWorkspace.OpenConfiguration()
        conf.activates = true
        NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: path), configuration: conf) { app, error in
            reply(app != nil, error?.localizedDescription)
        }
        */
    }
    func jsExec(command: String, arguments: [String], reply: @escaping (Int32, String) -> Void) {
        systemActionInvoked = true
        if systemActionShowMessage {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = NSLocalizedString("Command execution", comment: "")
                alert.informativeText = String(format: NSLocalizedString("This action will exectute the command %@ with arguments: %@.", comment: ""), command, arguments.joined(separator: ", "))
                alert.runModal()
            }
        }
        reply(1, NSLocalizedString("Implemented only from the Finder extension.", comment: ""))
        /*
        //DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            let task = Process()
            let pipe = Pipe()
            
            task.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)!
                let status = task.terminationStatus
                reply(status, output)
            }
            
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.arguments = arguments
            task.launchPath = command
            
            task.launch()
            // task.waitUntilExit()
         // }
         */
    }
    func jsExecSync(command: String, arguments: [String]) -> (status: Int32, output: String) {
        let inflightSemaphore = DispatchSemaphore(value: 0)

        var status: Int32 = 0
        var output: String = ""
        var completed = false
        
        let task = Process()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pipe = Pipe()
            
            task.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output1 = String(data: data, encoding: .utf8)!
                let status1 = task.terminationStatus
                
                status = status1
                output = output1
                completed = true
                
                inflightSemaphore.signal()
            }
            
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.arguments = arguments
            task.launchPath = command
            do {
                try task.run()
            } catch {
                status = -1
                output = error.localizedDescription
                completed = true
                inflightSemaphore.signal()
            }
        }
        
        let timeoutLimit: DispatchTime = .now() + Settings.execSyncTimeout
        
        if !Thread.isMainThread {
            let r = inflightSemaphore.wait(timeout: timeoutLimit)
            if r == .timedOut && !completed {
                status = -1
                output = "Timeout"
            }
        } else {
            while inflightSemaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
                if DispatchTime.now() >= timeoutLimit {
                    if !completed {
                        status = -1
                        output = "Timeout"
                    }
                    break
                }
            }
        }
        
        if task.isRunning {
            task.terminate()
        }
        
        return (status: status, output: output)
    }
    
    func jsRunApp(at path: String, reply: @escaping (Bool, String?) -> Void) {
        systemActionInvoked = true
        if systemActionShowMessage {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = NSLocalizedString("Launching an application", comment: "")
                alert.informativeText = String(format: NSLocalizedString("This action will open the application %@.", comment: ""), path)
                alert.runModal()
            }
        }
        reply(false, NSLocalizedString("Implemented only from the Finder extension.", comment: ""))
        /*
        let url = URL(fileURLWithPath: path)
        let conf = NSWorkspace.OpenConfiguration()
        conf.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: conf) { app, error in
            reply(app != nil, error?.localizedDescription)
        }
        */
    }
    
    func jsCopyToClipboard(text: String) -> Bool {
        systemActionInvoked = true
        if systemActionShowMessage {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = NSLocalizedString("Clipboard", comment: "")
                alert.informativeText = String(format: NSLocalizedString("This action will copy \"%@\" to the clipboard.", comment: ""), text)
                alert.runModal()
            }
        }
        return false
    }

    func handleMenuAction(info: BaseInfo, selectedMenu menuItem: NSMenuItem) {
        self.systemActionInvoked = false
        self.systemActionShowMessage = true
        defer {
            self.systemActionShowMessage = false
        }
        
        let item = BaseInfo.postprocessMenuItem(menuItem, from: self.representedObjects) as? MenuItemInfo
        
        if let item = item {
            var alert: NSAlert? = NSAlert()
            alert?.alertStyle = .informational
            switch item.action {
            case .none:
                // No action
                return
            case .standard:
                // Standard action
                alert = nil
            case .openSettings:
                alert?.messageText = NSLocalizedString("Opening Settings", comment: "")
                alert?.informativeText = NSLocalizedString("The action will open this application.", comment: "")
            case .about:
                alert?.messageText = NSLocalizedString("Opening of the project website", comment: "")
                alert?.informativeText = NSLocalizedString("The action will open this project’s GitHub page.", comment: "")
            case .open:
                alert?.messageText = NSLocalizedString("Opening the file", comment: "")
                alert?.informativeText = NSLocalizedString("The action will open the file with the default application.", comment: "")
            case .openWith:
                alert?.messageText = NSLocalizedString("Opening the file with an Application", comment: "")
                alert?.informativeText = String(format: NSLocalizedString("The action will open the file with the application %@.", comment: ""), item.userInfo["application"] as? String ?? "")
            case .custom:
                alert?.messageText = NSLocalizedString("Running the script", comment: "")
                alert?.informativeText = NSLocalizedString("The action will execute a custom script.", comment: "")
                
                if let code = item.userInfo["code"] as? String {
                    info.initSettings(globalSettings: self.settings)
                    info.initAction(context: info.getJSContext(), selectedItem: item)
                    _ = try? info.evaluateScript(code: "globalThis['\(code)'](selectedMenuItem);", forItem: item)
                    if self.systemActionInvoked {
                        alert = nil
                    }
                }
            case .clipboard:
                alert?.messageText = NSLocalizedString("Clipboard", comment: "")
                alert?.informativeText = NSLocalizedString("The action will copy the path into the cliboard.", comment: "")
            case .export:
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                
                let e = JSONEncoder()
                e.outputFormatting = .prettyPrinted
                if let data = try? e.encode(info) {
                    let s = String(data: data, encoding: .utf8)!
                    pasteboard.setString(s, forType: NSPasteboard.PasteboardType.string)
                    print(s)
                }
                return
            case .reveal:
                alert?.messageText = NSLocalizedString("Reveal in Finder", comment: "")
                alert?.informativeText = NSLocalizedString("The action will select the file in the Finder.", comment: "")
            }
            
            if let alert = alert {
                alert.runModal()
                return
            }
        }
        
        var alert: NSAlert? = NSAlert()
        alert?.alertStyle = .informational
        
        if self.settings.getFormatSettings(for: type(of: info).infoType)?.hasActiveTrigger(.action) ?? false {
            alert?.messageText = NSLocalizedString("The action will run the trigger action script.", comment: "")
            info.initSettings(globalSettings: self.settings)
            try? info.evaluateTriggerAction(selectedItem: item)
            if self.systemActionInvoked {
                alert = nil
            }
        } else {
            switch self.settings.menuAction {
            case .none:
                return
            case .open:
                alert?.messageText = NSLocalizedString("The action will open the file with the default application.", comment: "")
            }
        }
        
        alert?.runModal()
    }
}

// MARK: - FakeJSDelegate
extension ViewController: FakeJSDelegate {
    
}

// MARK: - FormatCellView
class FormatCellView: NSTableCellView {
    @IBOutlet weak var switchView: NSSwitch!
    @IBOutlet weak var popupButton: NSPopUpButton!
    
    var uti: String? {
        didSet {
            if let uti = uti {
                self.textField?.stringValue = uti
                self.textField?.toolTip = ""
                if #available(macOS 11.0, *) {
                    if let uti_type = UTType(uti) {
                        if let desc = uti_type.localizedDescription {
                            self.textField?.stringValue = desc
                            self.textField?.toolTip = uti
                        }
                        popupButton.menu?.items.first?.image = NSWorkspace.shared.icon(for: uti_type).resized(to: NSSize(width: 16, height: 16))
                    } else {
                        popupButton.menu?.items.first?.image = NSWorkspace.shared.icon(for: UTType.data).resized(to: NSSize(width: 16, height: 16))
                    }
                } else {
                    if let desc = UTTypeCopyDescription(uti as CFString)?.takeRetainedValue() as? String {
                        self.textField?.stringValue = desc
                        self.textField?.toolTip = uti
                    }
                    popupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: uti).resized(to: NSSize(width: 16, height: 16))
                }
                popupButton.menu?.identifier = NSUserInterfaceItemIdentifier(rawValue: uti)
            } else {
                self.textField?.stringValue = NSLocalizedString("all other files", comment: "")
                self.textField?.toolTip = ""
                popupButton.menu?.identifier = nil
                if #available(macOS 11.0, *) {
                    popupButton.menu?.items.first?.image = NSWorkspace.shared.icon(for: UTType.data).resized(to: NSSize(width: 16, height: 16))
                } else {
                    popupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.data").resized(to: NSSize(width: 16, height: 16))
                }
                popupButton.menu?.identifier = NSUserInterfaceItemIdentifier(rawValue: "")
            }
        }
    }
    var action: (()->Void)?
    
    @IBAction func handleSwitch(_ sender: Any) {
        self.action?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        action = nil
        uti = nil
        popupButton.menu?.delegate = nil
    }
}
