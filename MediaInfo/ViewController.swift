//
//  ViewController.swift
//  MediaInfo
//
//  Created by Sbarex on 21/08/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import Cocoa
import FinderSync


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
    @IBOutlet weak var imagePopupButton: NSPopUpButton!
    @IBOutlet weak var videoPopupButton: NSPopUpButton!
    @IBOutlet weak var audioPopupButton: NSPopUpButton!
    @IBOutlet weak var pdfPopupButton: NSPopUpButton!
    @IBOutlet weak var officePopupButton: NSPopUpButton!
    
    @IBOutlet weak var imageMenuTableView: MenuTableView!
    @IBOutlet weak var videoMenuTableView: MenuTableView!
    @IBOutlet weak var audioMenuTableView: MenuTableView!
    @IBOutlet weak var pdfMenuTableView: MenuTableView!
    @IBOutlet weak var officeMenuTableView: MenuTableView!
    
    @IBOutlet weak var enginesTableView: NSTableView!
    @IBOutlet weak var engineSegmentedControl: NSSegmentedControl!
    
    @IBOutlet weak var tableView: NSTableView!
    
    @objc dynamic var isImageHandled: Bool = true {
        didSet {
            if oldValue != isImageHandled {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isVideoHandled: Bool = true {
        didSet {
            if oldValue != isVideoHandled {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isAudioHandled: Bool = true {
        didSet {
            if oldValue != isAudioHandled {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isPDFHandled: Bool = true {
        didSet {
            if oldValue != isPDFHandled {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isOfficeHandled: Bool = true {
        didSet {
            if oldValue != isOfficeHandled {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isOfficeDeepScan: Bool = true {
        didSet {
            if oldValue != isOfficeHandled {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isIconHidden: Bool = false {
        didSet {
            if oldValue != isIconHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isInfoOnSubmenu: Bool = true {
        didSet {
            if oldValue != isInfoOnSubmenu {
                self.view.window?.isDocumentEdited = true
                refreshFirstItem()
            }
        }
    }
    
    @objc dynamic var isInfoOnMainItem: Bool = false {
        didSet {
            if oldValue != isInfoOnMainItem {
                self.view.window?.isDocumentEdited = true
                refreshFirstItem()
            }
        }
    }
    
    @objc dynamic var useFirstItemAsMain: Bool = false {
        didSet {
            if oldValue != useFirstItemAsMain {
                self.view.window?.isDocumentEdited = true
                refreshFirstItem()
            }
        }
    }

    @objc dynamic var isEmptyItemsSkipped: Bool = true {
        didSet {
            if oldValue != isEmptyItemsSkipped {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isRatioRounded: Bool = true {
        didSet {
            if oldValue != isRatioRounded {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isTracksGrouped: Bool = false {
        didSet {
            if oldValue != isTracksGrouped {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isExtensionEnabled: Bool {
        return FIFinderSyncController.isExtensionEnabled
    }
    
    @objc dynamic var menuWillOpenFile: Bool = true
    
    var folders: [URL] = [] {
        didSet {
            if oldValue != folders {
                self.view.window?.isDocumentEdited = true
            }
            tableView.reloadData()
        }
    }
    
    var engines: [MediaEngine] = [.ffmpeg, .coremedia, .metadata] {
        didSet {
            enginesTableView.reloadData()
        }
    }
    
    func refreshFirstItem() {
        for view in [imageMenuTableView, videoMenuTableView, audioMenuTableView, pdfMenuTableView] {
            view?.tableView.reloadData(forRowIndexes: IndexSet(integer: 0), columnIndexes: IndexSet(integer: 0))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reset()
        
        imagePopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.jpeg").resized(to: NSSize(width: 24, height: 24))
        videoPopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.mpeg-4").resized(to: NSSize(width: 24, height: 24))
        audioPopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.mp3").resized(to: NSSize(width: 24, height: 24))
        pdfPopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "com.adobe.pdf").resized(to: NSSize(width: 24, height: 24))
        officePopupButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "org.openxmlformats.wordprocessingml.document").resized(to: NSSize(width: 24, height: 24))
        
        imageMenuTableView.getSettings = { self.getSettings() }
        imageMenuTableView.supportedType = .image
        imageMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenDimensional(mode: .widthHeight), TokenPrint(mode: TokenPrint.Mode.dpi)]),
            (label: NSLocalizedString("Color: ", comment: ""), tokens: [TokenColor(mode: .colorSpaceDepth)]),
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenImageExtra(mode: .animated)])
        ]
        imageMenuTableView.validTokens = [TokenDimensional.self, TokenPrint.self, TokenColor.self, TokenImageExtra.self, TokenText.self]
        if let url = Bundle.main.url(forResource: "test", withExtension: "jpg"), let img = getCGImageInfo(forFile: url) {
            imageMenuTableView.example = img
        } else {
            imageMenuTableView.example = ImageInfo(file: Bundle.main.bundleURL, width: 1920, height: 1080, dpi: 150, colorMode: "RGB", depth: 8, animated: false)
        }
        
        videoMenuTableView.getSettings = { self.getSettings() }
        videoMenuTableView.supportedType = .video
        videoMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenDimensional(mode: .widthHeight)]),
            (label: NSLocalizedString("Length: ", comment: ""), tokens: [TokenDuration(mode: .hours)]),
            (label: NSLocalizedString("Language: ", comment: ""), tokens: [TokenLanguage(mode: .flag)]),
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenMediaExtra(mode: .codec_short_name), TokenVideoMetadata(mode: .frames), TokenMediaTrack(mode: .video)]),
        ]
        videoMenuTableView.validTokens = [TokenDimensional.self, TokenDuration.self, TokenLanguage.self, TokenMediaExtra.self, TokenVideoMetadata.self, TokenMediaTrack.self, TokenText.self]
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
                video: [], audio: [
                    AudioTrackInfo(duration: 3600, start_time: 0, codec_short_name: "mp3", codec_long_name: "MP3 (MPEG audio layer 3)", lang: "EN", bitRate: 512*1025, title: "Audio title", encoder: "Encoder", isLossless: false, channels: 2)
                ], subtitles: [
                    SubtitleTrackInfo(title: "English subtitle", lang: "EN"),
                    SubtitleTrackInfo(title: "Sottitoli in italiano", lang: "IT"),
                ],
                engine: .coremedia
                )
        }
        
        audioMenuTableView.getSettings = { self.getSettings() }
        audioMenuTableView.supportedType = .audio
        audioMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Length: ", comment: ""), tokens: [TokenDuration(mode: .hours)]),
            (label: NSLocalizedString("Language: ", comment: ""), tokens: [TokenLanguage(mode: .flag)]),
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenMediaExtra(mode: .codec_short_name)]),
            (label: NSLocalizedString("Metadata: ", comment: ""), tokens: [TokenAudioMetadata(mode: .title)])
        ]
        audioMenuTableView.validTokens = [TokenDuration.self, TokenLanguage.self, TokenMediaExtra.self, TokenAudioMetadata.self, TokenText.self]
        if let url = Bundle.main.url(forResource: "test", withExtension: "mp3") {
            audioMenuTableView.example = getCMAudioInfo(forFile: url)
        } else {
            audioMenuTableView.example = AudioInfo(
                file: Bundle.main.bundleURL,
                duration: 45, start_time: -1,
                codec_short_name: "mp3", codec_long_name: "MP3 (MPEG audio layer 3)", 
                lang: "EN",
                bitRate: 512*1024,
                title: "Audio title", encoder: "Encoder",
                isLossless: false,
                chapters: [],
                channels: 2,
                engine: .coremedia)
        }
        
        pdfMenuTableView.getSettings = { self.getSettings() }
        pdfMenuTableView.supportedType = .pdf
        pdfMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenPdfBox(mode: .mediaBox, unit: .pt), TokenPdfBox(mode: .bleedBox, unit: .pt), TokenPdfBox(mode: .cropBox, unit: .pt), TokenPdfBox(mode: .artBox, unit: .pt)]),
            (label: NSLocalizedString("Metadata: ", comment: ""), tokens: [TokenPdfMetadata(mode: .pages)])
        ]
        pdfMenuTableView.validTokens = [TokenPdfBox.self, TokenPdfMetadata.self, TokenText.self]
        if let url = Bundle.main.url(forResource: "test", withExtension: "pdf"), let pdf = CGPDFDocument(url as CFURL) {
            pdfMenuTableView.example = PDFInfo(file: url, pdf: pdf)
        }
        
        officeMenuTableView.getSettings = { self.getSettings() }
        officeMenuTableView.supportedType = .office
        officeMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenOfficeSize(mode: .print_paper_cm)]),
            (label: NSLocalizedString("Metadata: ", comment: ""), tokens: [TokenOfficeMetadata(mode: .pages)])
        ]
        officeMenuTableView.validTokens = [TokenOfficeSize.self, TokenOfficeMetadata.self, TokenText.self]
        officeMenuTableView.example = WordInfo(file: Bundle.main.bundleURL, charactersCount: 1765, charactersWithSpacesCount: 2000, wordsCount: 123, pagesCount: 3, creator: "sbarex", creationDate: Date(timeIntervalSinceNow: -60*60), modified: "sbarex", modificationDate: Date(timeIntervalSinceNow: 0), title: "Title", subject: "Subject", keywords: ["key1", "key2"], description: "Description", application: "Microsoft Word", width: 21/2.54, height: 29.7/2.54)
        
        enginesTableView.registerForDraggedTypes([NSPasteboard.PasteboardType("private.table-row-engine")])
        updateEngineSegmentedControl()
        
        DispatchQueue.main.async {
            if !FIFinderSyncController.isExtensionEnabled {
                let p = NSAlert()
                p.messageText = NSLocalizedString("Finder extension not enabled!", comment: "")
                // p.informativeText = "The finder sync extension is not enabled."
                p.alertStyle = .warning
                p.addButton(withTitle: NSLocalizedString("Open System Settings", comment: ""))
                p.addButton(withTitle: NSLocalizedString("Ignore", comment: ""))
                if p.runModal() == .alertFirstButtonReturn {
                    FIFinderSyncController.showExtensionManagementInterface()
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
                    self.tableView.reloadData()
                    self.view.window?.isDocumentEdited = true
                }
            } else {
                // User clicked on "Cancel"
                return
            }
        } else if sender.indexOfSelectedItem == 1 {
            guard tableView.selectedRow >= 0 else {
                return
            }
            self.folders.remove(at: tableView.selectedRow)
            self.view.window?.isDocumentEdited = true
            self.tableView.reloadData()
        }
    }
    
    func convertNetwordSharedUrl(_ url: URL) -> URL? {
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

    func getSettings() -> Settings {
        let settings = Settings(fromDict: [:])
        
        let folders = Array(Set(self.folders))
        settings.folders = folders
                
        settings.isIconHidden = self.isIconHidden
        settings.isInfoOnSubMenu = self.isInfoOnSubmenu
        settings.isInfoOnMainItem = self.isInfoOnMainItem
        settings.useFirstItemAsMain = self.useFirstItemAsMain
        settings.isRatioPrecise = !self.isRatioRounded
        settings.isEmptyItemsSkipped = self.isEmptyItemsSkipped
        
        settings.isImagesHandled = self.isImageHandled
        settings.imageMenuItems = self.imageMenuTableView.items
        
        settings.isVideoHandled = self.isVideoHandled
        settings.videoMenuItems = self.videoMenuTableView.items
        
        settings.isTracksGrouped = self.isTracksGrouped
        
        settings.isAudioHandled = self.isAudioHandled
        settings.audioMenuItems = self.audioMenuTableView.items
        
        settings.isPDFHandled = self.isPDFHandled
        settings.pdfMenuItems = self.pdfMenuTableView.items
        
        settings.isOfficeHandled = self.isOfficeHandled
        settings.officeMenuItems = self.officeMenuTableView.items
        settings.isOfficeDeepScan = self.isOfficeDeepScan
        
        settings.engines = self.engines
        
        settings.menuWillOpenFile = self.menuWillOpenFile
        
        return settings
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
        
        let settings = self.getSettings()
        
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
            self.isIconHidden = settings.isIconHidden
            self.isInfoOnSubmenu = settings.isInfoOnSubMenu
            self.isInfoOnMainItem = settings.isInfoOnMainItem
            self.useFirstItemAsMain = settings.useFirstItemAsMain
            self.isRatioRounded = !settings.isRatioPrecise
            self.isEmptyItemsSkipped = settings.isEmptyItemsSkipped
            
            self.isTracksGrouped = settings.isTracksGrouped
            
            self.folders = settings.folders.sorted(by: { $0.path < $1.path })
            
            self.isImageHandled = settings.isImagesHandled
            self.imageMenuTableView.items = settings.imageMenuItems
            self.imageMenuTableView.tableView?.reloadData()
            
            self.isVideoHandled = settings.isVideoHandled
            self.videoMenuTableView.items = settings.videoMenuItems
            self.videoMenuTableView.tableView?.reloadData()
            
            self.isAudioHandled = settings.isAudioHandled
            self.audioMenuTableView.items = settings.audioMenuItems
            self.audioMenuTableView.tableView?.reloadData()
            
            self.isPDFHandled = settings.isPDFHandled
            self.pdfMenuTableView.items = settings.pdfMenuItems
            self.pdfMenuTableView.tableView?.reloadData()
            
            self.isOfficeHandled = settings.isOfficeHandled
            self.officeMenuTableView.items = settings.officeMenuItems
            self.officeMenuTableView.tableView?.reloadData()
            self.isOfficeDeepScan = settings.isOfficeDeepScan
            
            self.menuWillOpenFile = settings.menuWillOpenFile
            
            self.engines = settings.engines
            
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
        FIFinderSyncController.showExtensionManagementInterface()
    }
    
    func getTemplate(fromTokens tokens: [Token]) -> String {
        var template = ""
        for token in tokens {
            template += token.placeholder
        }
        return template
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
            self.engines.move(from: index, to: index - 1)
            enginesTableView.endUpdates()
            enginesTableView.selectRowIndexes(IndexSet(integer: index-1), byExtendingSelection: false)
        case 1: // down
            guard index < self.engines.count - 1 else {
                return
            }
            enginesTableView.beginUpdates()
            enginesTableView.moveRow(at: index, to: index + 1)
            self.engines.move(from: index, to: index + 1)
            enginesTableView.endUpdates()
            enginesTableView.selectRowIndexes(IndexSet(integer: index+1), byExtendingSelection: false)
        default:
            break
        }
    }
    
    func updateEngineSegmentedControl() {
        engineSegmentedControl.setEnabled(enginesTableView.selectedRow > 0, forSegment: 0)
        engineSegmentedControl.setEnabled(enginesTableView.selectedRow >= 0 && enginesTableView.selectedRow < self.engines.count - 1, forSegment: 1)
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView.identifier?.rawValue == "engines" {
            return 3
        } else {
            return self.folders.count
        }
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView.identifier?.rawValue == "engines" {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EngineCell"), owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = self.engines[row].label
            return cell
        } else {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:  tableColumn?.identifier.rawValue == "image" ? "ImageCell" : "TextCell"), owner: nil) as? NSTableCellView
            
            if tableColumn?.identifier.rawValue == "image" {
                cell?.imageView?.image = NSWorkspace.shared.icon(forFile: self.folders[row].path)
            } else {
                cell?.textField?.stringValue = self.folders[row].path
            }
            return cell
        }
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        guard tableView.identifier?.rawValue == "engines" else { return nil }
        item.setString(String(row), forType: NSPasteboard.PasteboardType(rawValue: "private.table-row-engine"))
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard tableView.identifier?.rawValue == "engines" else { return [] }
        if dropOperation == .above {
            return .move
        }
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard tableView.identifier?.rawValue == "engines" else { return false }
        
        var oldIndexes = [Int]()
        info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:]) { item, _, _ in
            if let str = (item.item as! NSPasteboardItem).string(forType: NSPasteboard.PasteboardType(rawValue: "private.table-row-engine")), let index = Int(str) {
                oldIndexes.append(index)
            }
        }

        var oldIndexOffset = 0
        var newIndexOffset = 0

        // For simplicity, the code below uses `tableView.moveRowAtIndex` to move rows around directly.
        // You may want to move rows in your content array and then call `tableView.reloadData()` instead.
        tableView.beginUpdates()
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
            
            tableView.moveRow(at: oldRow, to: newRow)
            self.engines.move(from: oldRow, to: newRow)
        }
        
        tableView.endUpdates()
        
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let t = notification.object as? NSTableView, t.identifier?.rawValue == "engines" else { return }
        updateEngineSegmentedControl()
    }
    
}

extension ViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let example: BaseInfo
        if menu.identifier?.rawValue == "mnu_image", let e = imageMenuTableView.example {
           example = e
        } else if menu.identifier?.rawValue == "mnu_video", let e = videoMenuTableView.example {
            example = e
        } else if menu.identifier?.rawValue == "mnu_audio", let e = audioMenuTableView.example {
            example = e
        } else if menu.identifier?.rawValue == "mnu_pdf", let e = pdfMenuTableView.example {
            example = e
        } else if menu.identifier?.rawValue == "mnu_office", let e = officeMenuTableView.example {
            example = e
        } else {
            return
        }
        
        let settings = self.getSettings()
        guard let menu_example = example.getMenu(withSettings: settings) else {
            return
        }
        
        while menu.items.count > 1 {
            menu.removeItem(at: 1)
        }
        
        if settings.isInfoOnSubMenu, let item = menu_example.items.first {
            let mnu = menu.addItem(withTitle: item.title, action: nil, keyEquivalent: "")
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
