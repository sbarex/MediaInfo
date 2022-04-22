//
//  CustoMFormatViewController.swift
//  MediaInfoEx
//
//  Created by Sbarex on 19/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import AppKit
import UniformTypeIdentifiers

class CustomFormatViewController: NSViewController {
    @IBOutlet weak var customMenuTableView: MenuTableView!
    @IBOutlet weak var utiField: NSTextField!
    @IBOutlet weak var utiLabel: NSTextField!
    @IBOutlet weak var utiBrowseButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var enabledSwitch: NSSwitch!
    @IBOutlet weak var menuButton: NSPopUpButton!
    
    @objc dynamic var isUtiEnabled: Bool {
        get {
            return formatSettings?.isEnabled ?? false
        }
        set {
            self.willChangeValue(forKey: #keyPath(isUtiEnabled))
            formatSettings?.isEnabled = newValue
            self.didChangeValue(forKey: #keyPath(isUtiEnabled))
        }
    }
    
    @objc dynamic var uti: String {
        get {
            return (formatSettings as? Settings.CustomFormatSettings)?.uti ?? ""
        }
        set {
            if (formatSettings as? Settings.CustomFormatSettings)?.uti ?? newValue != newValue {
                self.view.window?.isDocumentEdited = true
            }
            self.willChangeValue(forKey: #keyPath(uti))
            self.willChangeValue(forKey: #keyPath(isValid))
            (formatSettings as? Settings.CustomFormatSettings)?.uti = newValue
            self.didChangeValue(forKey: #keyPath(uti))
            self.didChangeValue(forKey: #keyPath(isValid))
            
            example.uti = self.uti
            example.utiConformsToType = (formatSettings as? Settings.CustomFormatSettings)?.conformsToUTI ?? []
            var path = "/tmp/test"
            if let ext = (formatSettings as? Settings.CustomFormatSettings)?.associatedExtension {
                path += ".\(ext)"
            }
            example.file = URL(fileURLWithPath: path)
            self.menuButton.menu?.items.first?.image = (formatSettings as? Settings.CustomFormatSettings)?.icon?.resized(to: NSSize(width: 16, height: 16))
        }
    }
    
    @objc dynamic var isValid: Bool {
        get {
            guard let _ = formatSettings as? Settings.CustomFormatSettings else {
                return true
            }
            guard !uti.isEmpty else {
                return false
            }
            if #available(macOS 11.0, *) {
                guard let _ = UTType(self.uti) else {
                    return false
                }
                return true
            } else {
                let r = UTTypeCopyDeclaration(self.uti as CFString)
                return r != nil
                // Fallback on earlier versions
            }
        }
    }
    
    fileprivate var orig_settings: Settings.FormatSettings?
    var formatSettings: Settings.FormatSettings? {
        didSet {
            orig_settings = formatSettings?.copy()
            customMenuTableView?.formatSettings = formatSettings
            self.utiField?.isHidden = formatSettings is Settings.CustomFormatSettings
            self.utiBrowseButton?.isHidden = self.utiField.isHidden
            self.utiLabel?.isHidden = self.utiField.isHidden
        }
    }
    
    var settings: Settings = Settings.getStandardSettings()
    
    var representedObjects: [Int: Any] = [:]
    
    var example: FakeFileInfo = FakeFileInfo(file: URL(fileURLWithPath: "/tmp/test"), fileSize: 1024, fileSizeFull: 1036, fileCreationDate: Date(timeIntervalSinceNow: -60*5), fileModificationDate: Date(timeIntervalSinceNow: -60), fileAccessDate: Date(), uti: "public.item", utiConformsToType: ["public.data"])
    
    var systemActionShowMessage: Bool = false
    var systemActionInvoked: Bool = false
    
    var onSave: ((CustomFormatViewController)->Void)?
    weak var jsDelegate: JSDelegate? {
        didSet {
            example.jsDelegate = jsDelegate
        }
    }
    
    @IBAction func handleDone(_ sender: Any) {
        self.onSave?(self)
        self.dismiss(sender)
    }
    
    @IBAction func handleClose(_ sender: Any) {
        formatSettings?.update(from: orig_settings?.toDictionary() ?? [:])
        orig_settings = formatSettings?.copy()
        self.dismiss(sender)
    }
    
    @IBAction func handleBrowse(_ sender: Any) {
        let dialog = NSOpenPanel()
        dialog.showsHiddenFiles = true
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true
        dialog.allowsMultipleSelection = false
        guard dialog.runModal() == .OK, let url = dialog.url else {
            return
        }
        if #available(macOS 11.0, *) {
            if let data = try? url.resourceValues(forKeys: [.contentTypeKey]), let t = data.contentType {
                self.uti = t.identifier
            }
        } else {
            if let data = try? url.resourceValues(forKeys: [.typeIdentifierKey]), let t = data.typeIdentifier {
                self.uti = t
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customMenuTableView.formatSettings = formatSettings
        customMenuTableView.validTokens = [TokenFile.self, TokenAction.self, TokenScript.self]
        customMenuTableView.sampleTokens = [
            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenFile(mode: .filesize), TokenScript(mode: .inline(code: "")), TokenAction(mode: .app(path: ""))])
        ]
        customMenuTableView.example = self.example
        self.example.actionDelegate = self
        self.example.jsDelegate = self.jsDelegate
        
        if let _ = formatSettings?.triggers.first(where: {$0.value.isEnabled}) {
            
        } else {
            customMenuTableView.hideTriggers(animated: false)
        }
        if let formatSettings = formatSettings as? Settings.CustomFormatSettings {
            self.menuButton.menu?.items.first?.image = formatSettings.icon?.resized(to: NSSize(width: 16, height: 16))
            self.utiField.isHidden = false
            self.utiLabel.isHidden = false
            self.utiBrowseButton.isHidden = false
        } else {
            self.menuButton.menu?.items.first?.image = NSWorkspace.shared.icon(forFileType: "public.data").resized(to: NSSize(width: 16, height: 16))
            self.utiField.isHidden = true
            self.utiLabel.isHidden = true
            self.utiBrowseButton.isHidden = true
        }
    }
}

extension CustomFormatViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        while menu.items.count > 1 {
            menu.removeItem(at: 1)
        }
        example.initSettings(withItemSettings: self.formatSettings, globalSettings: self.settings)
        
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
                self.customMenuTableView.triggers_error_validate = error
            }
        }
        guard let menu_example = example.getMenu(withItemSettings: self.formatSettings, globalSettings: self.settings) else {
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

extension CustomFormatViewController: FakeJSDelegate {
    
}
