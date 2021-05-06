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
            alert.addButton(withTitle: NSLocalizedString("Don't Save", comment: "")).keyEquivalent = "d"
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
    
    @objc dynamic var isImageHandled: Bool = true {
        willSet {
            self.willChangeValue(forKey: "isDPIEnabled")
        }
        didSet {
            self.didChangeValue(forKey: "isDPIEnabled")
            if oldValue != isImageHandled {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isPrintedSizeHidden: Bool = false {
        didSet {
            if oldValue != isPrintedSizeHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isCustomDPIHidden: Bool = false  {
        willSet {
            self.willChangeValue(forKey: "isDPIEnabled")
        }
        didSet {
            self.didChangeValue(forKey: "isDPIEnabled")
            if oldValue != isCustomDPIHidden {
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
            }
        }
    }
    @objc dynamic var isInfoOnMainItem: Bool = false {
        didSet {
            if oldValue != isInfoOnMainItem {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isFileSizeHidden: Bool = false {
        didSet {
            if oldValue != isFileSizeHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isRatioHidden: Bool = false {
        didSet {
            if oldValue != isRatioHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isRatioPrecise: Int = 0 {
        didSet {
            if oldValue != isRatioPrecise {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isResolutionNameHidden: Bool = false {
        didSet {
            if oldValue != isResolutionNameHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var customDPI: Int = 300 {
        didSet {
            if oldValue != customDPI {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var unit: Int = 0 {
        didSet {
            if oldValue != unit {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isColorHidden: Bool = false {
        didSet {
            if oldValue != isColorHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isDepthHidden: Bool = false {
        didSet {
            if oldValue != isDepthHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isDPIEnabled: Bool {
        return isImageHandled && !isCustomDPIHidden
    }
    
    @objc dynamic var isVideoHandled: Bool = true {
        didSet {
            if oldValue != isVideoHandled {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isFramesHidden: Bool = false {
        didSet {
            if oldValue != isFramesHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isCodecHidden: Bool = false {
        didSet {
            if oldValue != isColorHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isBPSHidden: Bool = false {
        didSet {
            if oldValue != isBPSHidden {
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
    @objc dynamic var isMediaIconHidden: Bool = false {
        didSet {
            if oldValue != isMediaIconHidden {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    @objc dynamic var isMediaInfoOnSubmenu: Bool = true {
        didSet {
            if oldValue != isMediaInfoOnSubmenu {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @objc dynamic var isExtensionEnabled: Bool {
        return FIFinderSyncController.isExtensionEnabled
    }
    
    var folders: [URL] = [] {
        didSet {
            if oldValue != folders {
                self.view.window?.isDocumentEdited = true
            }
        }
    }
    
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reset()
        
        DispatchQueue.main.async {
            if !FIFinderSyncController.isExtensionEnabled {
                let p = NSAlert()
                p.messageText = NSLocalizedString("Finder extension not enabled", comment: "")
                // p.informativeText = "The finder sync extension is not enabled."
                p.alertStyle = .warning
                p.addButton(withTitle: NSLocalizedString("Enable", comment: ""))
                p.addButton(withTitle: NSLocalizedString("Ignore", comment: ""))
                if p.runModal() == .alertFirstButtonReturn {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func doChangeFolder(_ sender: NSSegmentedControl) {
        if sender.indexOfSelectedItem == 0 {
            doAddFolder(sender)
        } else if sender.indexOfSelectedItem == 1 {
            doRemoveFolder(sender)
        }
    }
    
    @IBAction func doAddFolder(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        // dialog.title                   = "Choose an archive file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles = false
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        // dialog.allowedFileTypes        = ["txt"];

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
    }
    
    @IBAction func doRemoveFolder(_ sender: Any) {
        guard tableView.selectedRow >= 0 else {
            return
        }
        self.folders.remove(at: tableView.selectedRow)
        self.view.window?.isDocumentEdited = true
        self.tableView.reloadData()
    }

    @IBAction func doSave(_ sender: Any) {
        self.doApplySettings(self)
    }
    
    func reset() {
        let settings = Settings.shared
        settings.refresh()
        
        self.isIconHidden = settings.isIconHidden
        self.isInfoOnSubmenu = settings.isInfoOnSubMenu
        self.isInfoOnMainItem = settings.isInfoOnMainItem
        self.isFileSizeHidden = settings.isFileSizeHidden
        self.isRatioHidden = settings.isRatioHidden
        self.isRatioPrecise = settings.isRatioPrecise ? 0 : 1
        self.isResolutionNameHidden = settings.isResolutionNameHidden
        
        self.isImageHandled = settings.isImagesHandled
        self.isPrintedSizeHidden = settings.isPrintHidden
        self.isCustomDPIHidden = settings.isCustomPrintHidden
        self.isColorHidden = settings.isColorHidden
        self.isDepthHidden = settings.isDepthHidden
        self.customDPI = settings.customDPI
        self.unit = settings.unit.rawValue
        
        self.isVideoHandled = settings.isMediaHandled
        self.isFramesHidden = settings.isFramesHidden
        self.isCodecHidden = settings.isCodecHidden
        self.isBPSHidden = settings.isBPSHidden
        self.isTracksGrouped = settings.isTracksGrouped
        
        self.folders = settings.folders.sorted(by: { $0.path < $1.path })
        
        self.view.window?.isDocumentEdited = false
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
        doApplySettings(sender)
    }
    
    @IBAction func doApplySettings(_ sender: Any) {
        let folders = Array(Set(self.folders))
        if folders.isEmpty {
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
        
        let settings = Settings.shared
        
        let current_folders = settings.folders
        
        settings.folders = folders
                
        settings.isIconHidden = self.isIconHidden
        settings.isInfoOnSubMenu = self.isInfoOnSubmenu
        settings.isInfoOnMainItem = self.isInfoOnMainItem
        settings.isFileSizeHidden = self.isFileSizeHidden
        settings.isRatioHidden = self.isRatioHidden
        settings.isRatioPrecise = self.isRatioPrecise == 0
        settings.isResolutionNameHidden = self.isResolutionNameHidden
        
        settings.isImagesHandled = self.isImageHandled
        settings.isPrintHidden = self.isPrintedSizeHidden
        settings.isCustomPrintHidden = self.isCustomDPIHidden
        settings.isColorHidden = self.isColorHidden
        settings.isDepthHidden = self.isDepthHidden
        settings.customDPI = self.customDPI
        settings.unit = PrintUnit(rawValue: self.unit) ?? .cm
        
        settings.isMediaHandled = self.isVideoHandled
        settings.isFramesHidden = self.isFramesHidden
        settings.isCodecHidden = self.isCodecHidden
        settings.isBPSHidden = self.isBPSHidden
        settings.isTracksGrouped = self.isTracksGrouped
        
        settings.synchronize()
        
        if current_folders != folders && FIFinderSyncController.isExtensionEnabled {
            DistributedNotificationCenter.default().postNotificationName(.MediaInfoMonitoredFolderChanged, object: Bundle.main.bundleIdentifier, userInfo: nil, options: [.deliverImmediately])
        }
        DistributedNotificationCenter.default().postNotificationName(.MediaInfoSettingsChanged, object: Bundle.main.bundleIdentifier, userInfo: nil, options: [.deliverImmediately])
        
        self.view.window?.isDocumentEdited = false
    }

    @IBAction func doClose(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func openSystemPreferences(_ sender: Any) {
        FIFinderSyncController.showExtensionManagementInterface()
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.folders.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.folders[row].path
    }
}

extension ViewController: NSTableViewDelegate {
    
}

