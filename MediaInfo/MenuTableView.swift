//
//  MenuTableView.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class MenuTableView: NSView {
    class MenuItem {
        enum ScriptType: Int {
            case none
            case inline
            case global
        }
        
        var image: String
        var template: String {
            didSet {
                formatted = nil
                isFilled = false
                info = nil
                warnings = []
                exception = nil
                line = nil
            }
        }
        
        var info: Set<String>?
        var warnings: Set<String>
        
        var exception: String?
        var line: Int?
        var scriptType: ScriptType
        var formatted: NSAttributedString?
        var isFilled: Bool
        
        init(image: String, template: String, warnings: Set<String> = [], exception: String? = nil, line: Int? = nil, info: Set<String>? = nil, scriptType: ScriptType = .none) {
            self.image = image
            self.template = template
            
            self.warnings = warnings
            
            self.exception = exception
            self.line = line
            self.info = info
            
            self.scriptType = scriptType
            self.formatted = nil
            self.isFilled = false
        }
    }
    
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var tagButton: NSButton!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    
    @IBOutlet weak var triggerLabel: NSTextField!
    @IBOutlet weak var triggerDisclosureButton: NSButton!
    @IBOutlet weak var triggersView: NSView!
    
    @IBOutlet weak var triggerValidateSwitch: NSSwitch!
    @IBOutlet weak var triggerValidateEditButton: NSButton!
    @IBOutlet weak var triggerValidateExceptionButton: NSButton!
    
    @IBOutlet weak var triggerBeforeRenderSwitch: NSSwitch!
    @IBOutlet weak var triggerBeforeRenderEditButton: NSButton!
    @IBOutlet weak var triggerBeforeRenderExceptionButton: NSButton!
    
    @IBOutlet weak var triggerActionSwitch: NSSwitch!
    @IBOutlet weak var triggerActionEditButton: NSButton!
    @IBOutlet weak var triggerActionExceptionButton: NSButton!
    
    @IBOutlet weak var heighConstraint: NSLayoutConstraint!
    
    @objc dynamic var isTagHidden = true {
        didSet {
            guard oldValue != isTagHidden else {
                return
            }
            if #available(macOS 11.0, *) {
                tagButton.image = NSImage(systemSymbolName: isTagHidden ? "tag" : "tag.fill", accessibilityDescription: nil)
            } else {
                tagButton.image = NSImage(named: isTagHidden ? "tag" : "tag.fill")
            }
            tableView.reloadData()
        }
    }
    
    var isTriggerHidden: Bool = true
    
    var sampleTokens: [MenuItemEditor.TokenSample] = []
    var validTokens: [Token.Type] = []
     
    var formatSettings: Settings.FormatSettings? {
        didSet {
            self.items = formatSettings?.templates.map({ MenuTableView.MenuItem(image: $0.image, template: $0.template)}) ?? []
            self.tableView?.reloadData()
            
            triggerValidateSwitch.state = (formatSettings?.hasActiveTrigger(.validate) ?? false) ? .on : .off
            triggerValidateEditButton.isEnabled = triggerValidateSwitch.state == .on
            
            triggerActionSwitch.state = (formatSettings?.hasActiveTrigger(.action) ?? false) ? .on : .off
            triggerActionEditButton.isEnabled = triggerActionSwitch.state == .on
            
            triggerBeforeRenderSwitch.state = (formatSettings?.hasActiveTrigger(.beforeRender) ?? false) ? .on : .off
            triggerBeforeRenderEditButton.isEnabled = triggerBeforeRenderSwitch.state == .on
            
            triggers_error_validate = nil
            triggers_error_before_render = nil
            triggers_error_action = nil
            
            if let formatSettings = formatSettings {
                isTriggerHidden = !formatSettings.allowTriggers || formatSettings.triggers.isEmpty
                hideTriggers(animated: false)
                triggersView.isHidden = isTriggerHidden || !formatSettings.allowTriggers
                triggerDisclosureButton.isHidden = !formatSettings.allowTriggers
                triggerLabel.isHidden = !formatSettings.allowTriggers
            } else {
                isTriggerHidden = true
                hideTriggers(animated: false)
                triggersView.isHidden = true
                triggerDisclosureButton.isHidden = true
                triggerLabel.isHidden = true
            }
        }
    }
    
    fileprivate var items: [MenuItem] = []
    var triggers_error_validate: BaseInfo.JSTriggerError? {
        didSet {
            self.triggerValidateExceptionButton.isHidden = triggers_error_validate == nil
        }
    }
    var triggers_error_action: BaseInfo.JSTriggerError?{
        didSet {
            self.triggerActionExceptionButton.isHidden = triggers_error_action == nil
        }
    }
    var triggers_error_before_render: BaseInfo.JSTriggerError?{
        didSet {
            self.triggerBeforeRenderExceptionButton.isHidden = triggers_error_before_render == nil
        }
    }
    
    var example: BaseInfo? {
        didSet {
            oldValue?.jsExceptionDelegate = nil
            example?.jsExceptionDelegate = self
        }
    }
    var supportedType: Token.SupportedType = .image
    weak var viewController: ViewController?
    
    var getSettings: ()->Settings = { return Settings.getStandardSettings() }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)
        
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.width, .height]
        
        tableView.doubleAction = #selector(self.handleTableDoubleClick(_:))
        tableView.registerForDraggedTypes([NSPasteboard.PasteboardType("private.table-row")])
        
        hideTriggers(animated: false)
        
        triggerDisclosureButton.isHidden = !(formatSettings?.allowTriggers ?? false)
        triggerLabel.isHidden = !(formatSettings?.allowTriggers ?? false)
    }
    
    @IBAction func handleTableDoubleClick(_ sender: NSTableView) {
        presentMenuEditor(row: sender.clickedRow)
    }
    
    @IBAction func handleMenuAction(_ sender: NSSegmentedControl) {
        let index = tableView.selectedRow
        switch sender.selectedSegment {
        case 0: // add
            presentMenuEditor(row: -1)
        case 1: // del
            guard index >= 0 else {
                return
            }
            confirmRemoveItem() {
                self.tableView.beginUpdates()
                
                self.items.remove(at: index)
                self.formatSettings?.templates.remove(at: index)
                self.tableView.removeRows(at: IndexSet(integer: index), withAnimation: .slideUp)
                
                self.tableView.endUpdates()
                
                self.contentView.window?.isDocumentEdited = true
            }
        case 2: // edit
            if tableView.selectedRow >= 0 {
                presentMenuEditor(row: tableView.selectedRow)
            }
        case 3: // up
            guard index > 0 else {
                return
            }
            tableView.beginUpdates()
            tableView.moveRow(at: index, to: index - 1)
            self.items.move(from: index, to: index - 1)
            self.formatSettings?.templates.move(from: index, to: index - 1)
            if index == 1 {
                tableView.reloadData(forRowIndexes: IndexSet(0...1), columnIndexes: IndexSet(integer: 0))
            }
            tableView.endUpdates()
            self.contentView.window?.isDocumentEdited = true
            updateSegmentedControl()
        case 4: // down
            guard index < items.count - 1 else {
                return
            }
            tableView.beginUpdates()
            tableView.moveRow(at: index, to: index + 1)
            self.items.move(from: index, to: index + 1)
            self.formatSettings?.templates.move(from: index, to: index + 1)
            if index == 0 {
                tableView.reloadData(forRowIndexes: IndexSet(0...1), columnIndexes: IndexSet(integer: 0))
            }
            tableView.endUpdates()
            self.contentView.window?.isDocumentEdited = true
            updateSegmentedControl()
        default:
            break
        }
    }
    
    @IBAction func doRefresh(_ sender: Any) {
        tableView.beginUpdates()
        self.refreshItems(example: self.example, force: true, settings: self.getSettings())
        tableView.reloadData()
        tableView.endUpdates()
    }
    
    @IBAction func handleDisclosureButton(_ sender: Any) {
        self.isTriggerHidden = !self.isTriggerHidden
        hideTriggers(animated: false)
    }
    
    @IBAction func handleTriggerEnable(_ sender: NSButton) {
        guard let formatSettings = self.formatSettings else {
            return
        }
        guard let name = Settings.TriggerName(rawValue: sender.tag) else {
            return
        }
        if formatSettings.triggers[name] == nil {
            formatSettings.triggers[name] = Settings.Trigger(code: "")
        }
        let trigger = formatSettings.triggers[name]!
        trigger.isEnabled = !trigger.isEnabled
        let triggerSwitch: NSSwitch
        let triggerEditButton: NSButton
        switch name {
        case .validate:
            triggerSwitch = triggerValidateSwitch
            triggerEditButton = triggerValidateEditButton
        case .beforeRender:
            triggerSwitch = triggerBeforeRenderSwitch
            triggerEditButton = triggerBeforeRenderEditButton
        case .action:
            triggerSwitch = triggerActionSwitch
            triggerEditButton = triggerActionEditButton
        }
        triggerEditButton.isEnabled = trigger.isEnabled
        triggerSwitch.state = trigger.isEnabled ? .on : .off
        self.contentView.window?.isDocumentEdited = true
    }
    
    func confirmRemoveItem(action: @escaping ()->Void) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Are you sure to remove this item?", comment: "")
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: NSLocalizedString("Remove", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.beginSheetModal(for: self.contentView.window!) { r in
            if r == .alertFirstButtonReturn {
                action()
            }
        }
    }
    
    internal func getTokens(from template: String) -> [Token] {
        return Token.parseTemplate(template, for: self.supportedType)
    }
    
    internal func presentMenuEditor(row: Int) {
        guard let editor = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil).instantiateController(withIdentifier: "MenuItemEditor") as? MenuItemEditor else {
            return
        }
        
        let imageName: String
        let tokens: [Token]
        if row >= 0 {
            imageName = items[row].image
            tokens = self.getTokens(from: items[row].template)
        } else {
            imageName = ""
            tokens = []
        }
        editor.validTokens = self.validTokens
        editor.supportedType = self.supportedType
        editor.doneAction = { image, tokens in
            if row >= 0 {
                self.items[row].image = image
                self.items[row].template = self.getTemplate(fromTokens: tokens)
                self.formatSettings?.templates[row].image = image
                self.formatSettings?.templates[row].template = self.getTemplate(fromTokens: tokens)
                self.tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integersIn: 0...1))
            } else {
                let index = self.tableView.selectedRow
                if index >= 0 {
                    self.items.insert(MenuItem(image: image, template: self.getTemplate(fromTokens: tokens)), at: index+1)
                    self.formatSettings?.templates.insert(Settings.MenuItem(image: image, template: self.getTemplate(fromTokens: tokens)), at: index+1)
                    self.tableView.insertRows(at: IndexSet(integer: index+1), withAnimation: .slideDown)
                    self.tableView.selectRowIndexes(IndexSet(integer: index+1), byExtendingSelection: false)
                } else {
                    self.items.append(MenuItem(image: image, template: self.getTemplate(fromTokens: tokens)))
                    self.formatSettings?.templates.append(Settings.MenuItem(image: image, template: self.getTemplate(fromTokens: tokens)))
                    self.tableView.insertRows(at: IndexSet(integer: self.items.count - 1), withAnimation: .slideDown)
                }
            }
            self.contentView.window?.isDocumentEdited = true
        }
        editor.initialize(tokens: tokens, image: imageName, sampleTokens: sampleTokens)
        
        self.contentView.parentViewController?.presentAsSheet(editor)
    }
    
    func updateSegmentedControl() {
        segmentedControl.setEnabled(tableView.selectedRow >= 0, forSegment: 1)
        segmentedControl.setEnabled(tableView.selectedRow >= 0, forSegment: 2)
        segmentedControl.setEnabled(tableView.selectedRow > 0, forSegment: 3)
        segmentedControl.setEnabled(tableView.selectedRow >= 0 && tableView.selectedRow < items.count - 1, forSegment: 4)
    }
    
    func getTemplate(fromTokens tokens: [Token]) -> String {
        var template = ""
        for token in tokens {
            template += token.placeholder
        }
        return template
    }
    
    func refreshItems(example: BaseInfo?, force: Bool = false, settings: Settings) {
        do {
            try execTriggerValidate()
            self.triggers_error_validate = nil
        } catch {
            if let error = error as? BaseInfo.JSTriggerError {
                self.triggers_error_validate = error
            }
        }
        do {
            try execTriggerBeforeRender()
            self.triggers_error_before_render = nil
        } catch {
            if let error = error as? BaseInfo.JSTriggerError {
                self.triggers_error_before_render = error
            }
        }
        
        for (i, item) in self.items.enumerated() {
            self.refreshItem(item, atIndex: i, force: force, example: example, settings: settings)
        }
    }
    
    func execTriggerValidate() throws {
        guard let example = example else {
            return
        }
        let url : URL
        if let example = example as? FileInfo {
            url = example.file
        } else {
            url = Bundle.main.bundleURL
        }
        _ = try type(of: example).evaluateTriggerValidate(self.formatSettings?.triggers[.validate], for: url, globalSettings: self.getSettings(), jsDelegate: example.jsDelegate)
    }
    
    func execTriggerBeforeRender() throws {
        guard let example = example else {
            return
        }
        example.initSettings(globalSettings: self.getSettings())
        _ = try example.evaluateTriggerBeforeRender()
    }
    
    func refreshItem(_ item: MenuItem, atIndex i: Int, force: Bool = false, example: BaseInfo?, settings: Settings) {
        if item.info == nil || force {
            item.info = []
            item.warnings = []
            item.scriptType = .none
            
            let tokens = self.getTokens(from: item.template)
            for token in tokens {
                let info = token.validate(with: self.example)
                if !info.info.isEmpty {
                    item.info?.insert(info.info)
                }
                if !info.warnings.isEmpty {
                    item.warnings.insert(info.warnings)
                }
                if let token = token as? TokenScript {
                    if item.scriptType == .none {
                        switch token.mode as! TokenScript.Mode {
                        case .inline: item.scriptType = .inline
                        case .global: item.scriptType = .global
                        }
                    }
                }
            }
        }
        
        if item.formatted == nil || force {
            if let example = example {
                example.initSettings(globalSettings: settings)
                let info = MenuItemInfo(fileType: type(of: example).infoType, index: i, item: Settings.MenuItem(image: item.image, template: item.template))
                
                var isFilled = false
                item.formatted = example.replacePlaceholders(in: item.template, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue], isFilled: &isFilled, forItem: info)
                item.isFilled = isFilled
                
                if !isFilled {
                    item.formatted = example.replacePlaceholdersFake(in: item.template, settings: settings, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue], forItem: info)
                }
            } else {
                item.formatted = nil
                item.isFilled = false
            }
        }
    }
    
    func hideTriggers(animated: Bool) {
        self.triggerDisclosureButton.state = isTriggerHidden ? .off : .on
        
        let heightValue: CGFloat = isTriggerHidden ? 0 : 72
        
        if animated {
            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                self.triggersView.isHidden = false
                self.triggerLabel.stringValue = NSLocalizedString(self.isTriggerHidden ? "Triggers" : "Triggers:", comment: "")
                
                context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                self.heighConstraint.animator().constant = heightValue
            }, completionHandler: { () -> Void in
                // animation completed
                if heightValue == 0 {
                    self.triggersView.isHidden = true
                }
            })
        } else {
            self.triggerLabel.stringValue = NSLocalizedString(self.isTriggerHidden ? "Triggers" : "Triggers:", comment: "")
            self.heighConstraint.constant = heightValue
            self.triggersView.isHidden = heightValue == 0
        }
    }
    
    @IBAction func handleTriggerEditor(_ sender: NSButton) {
        guard let name = Settings.TriggerName(rawValue: sender.tag) else {
            return
        }
        presentTriggerEditor(name: name)
    }
    
    func presentTriggerEditor(name: Settings.TriggerName) {
        guard let formatSettings = formatSettings else {
            return
        }
        if formatSettings.triggers[name] == nil {
            formatSettings.triggers[name] = Settings.Trigger(code: "")
        }
        let trigger = formatSettings.triggers[name]!
        let code = trigger.code
        switch name {
        case .validate:
            ScriptViewController.editCode(code, mode: .validate) { code in
                trigger.code = code
                trigger.isEnabled = !code.isEmpty
                self.triggerValidateSwitch.state = trigger.isEnabled ? .on : .off
                self.triggerValidateEditButton.isEnabled = !code.isEmpty
                do {
                    try self.execTriggerValidate()
                    self.triggers_error_validate = nil
                } catch {
                    if let error = error as? BaseInfo.JSTriggerError {
                        self.triggers_error_validate = error
                    }
                }
                self.contentView.window?.isDocumentEdited = true
            }
        case .beforeRender:
            ScriptViewController.editCode(code, mode: .beforeRender) { code in
                trigger.code = code
                trigger.isEnabled = !code.isEmpty
                self.triggerBeforeRenderSwitch.state = trigger.isEnabled ? .on : .off
                self.triggerBeforeRenderEditButton.isEnabled = !code.isEmpty
                do {
                    try self.execTriggerBeforeRender()
                    self.triggers_error_before_render = nil
                } catch {
                    if let error = error as? BaseInfo.JSTriggerError {
                        self.triggers_error_before_render = error
                    }
                }
                self.contentView.window?.isDocumentEdited = true
            }
        case .action:
            ScriptViewController.editCode(code, mode: .action) { code in
                trigger.code = code
                trigger.isEnabled = !code.isEmpty
                self.triggerActionSwitch.state = trigger.isEnabled ? .on : .off
                self.triggerActionEditButton.isEnabled = !code.isEmpty
                do {
                    self.example?.initSettings(globalSettings: self.getSettings())
                    try self.example?.evaluateTriggerAction(selectedItem: nil)
                    self.triggers_error_action = nil
                } catch {
                    if let error = error as? BaseInfo.JSTriggerError {
                        self.triggers_error_action = error
                    }
                }
                self.contentView.window?.isDocumentEdited = true
            }
        }
    }
    
    @IBAction func handleTriggerExceptionButton(_ sender: NSButton) {
        let exception: BaseInfo.JSTriggerError?
        let triggerName: Settings.TriggerName
        if sender.tag == 1 {
            exception = triggers_error_validate
            triggerName = .validate
        } else if sender.tag == 2 {
            exception = triggers_error_before_render
            triggerName = .beforeRender
        } else if sender.tag == 3 {
            exception = triggers_error_action
            triggerName = .action
        } else {
            return
        }
        guard let exception = exception else {
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Warning", comment: "")
        alert.alertStyle = .critical
        
        switch exception {
        case .jsInitError:
            alert.messageText = "JS Init error"
        case .exception(let info):
            if info.line >= 0 {
                alert.messageText = String(format: NSLocalizedString("JS Exception at line %d", comment: ""), info.line) + ": "
            } else {
                alert.messageText = NSLocalizedString("JS Exception", comment: "")
            }
            alert.informativeText = info.message
        case .invalidResult:
            alert.messageText = "Invalid returned value"
            switch triggerName {
            case .validate:
                alert.informativeText = "The validate trigger must return a boolean value."
            case .beforeRender:
                alert.informativeText = "The before render trigger must null or an array of menu item templates."
            case .action:
                break
            }
             
        }
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "")).keyEquivalent = "\r"
        alert.runModal()
    }
}

// MARK: - NSTableViewDelegate
extension MenuTableView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        
        let settings = self.getSettings()
        
        self.refreshItem(items[row], atIndex: row, example: self.example, settings: settings)
        if tableColumn?.identifier.rawValue == "actions" {
            let exception = item.exception
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "InfoCell"), owner: nil) as? ScriptCell
            cell?.exception = exception
            cell?.warnings = item.warnings
            cell?.line = item.line
            cell?.info = item.info
            
            if item.scriptType == .global, item.template.hasPrefix("[[script-global:") {
                cell?.editButton.image = NSImage(named: "applescript")
                cell?.editButton.toolTip = NSLocalizedString("Edit the script…", comment: "")
                cell?.editAction = {
                    let tokens = self.getTokens(from: item.template)
                    (tokens.first as? TokenScript)?.editScript(action: { code in
                        item.template = self.getTemplate(fromTokens: tokens)
                        self.formatSettings?.templates[row].template = item.template
                        item.info = nil
                        self.contentView.window?.isDocumentEdited = true
                        self.tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integersIn: 0...1))
                    })
                }
            } else if item.template.hasPrefix("[[open-with:") {
                cell?.editButton.image = NSImage(named: "folder")
                cell?.editButton.toolTip = NSLocalizedString("Choose the application…", comment: "")
                cell?.editAction = {
                    let tokens = self.getTokens(from: item.template)
                    (tokens.first as? TokenAction)?.editPath(action: { code in
                        item.template = self.getTemplate(fromTokens: tokens)
                        item.info = nil
                        self.contentView.window?.isDocumentEdited = true
                        self.tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integersIn: 0...1))
                    })
                }
            } else if item.template == "[[video]]" {
                cell?.editButton.image = NSImage(named: "contextualmenu.and.cursorarrow")
                cell?.editButton.toolTip = NSLocalizedString("Edit the submenu…", comment: "")
                cell?.editAction = {
                    guard let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ItemsEditorController") as? ItemsEditorController else {
                        return
                    }
                    vc.initView = { vc in
                        vc.title = NSLocalizedString("Video track menu items", comment: "")
                        vc.itemsView.supportedType = .video
                        vc.itemsView.getSettings = self.getSettings
                        vc.itemsView.formatSettings = self.getSettings().videoTrackSettings
                        vc.itemsView.sampleTokens = [
                            (label: NSLocalizedString("Size: ", comment: ""), tokens: [TokenDimensional(mode: .widthHeight)]),
                            (label: NSLocalizedString("Length: ", comment: ""), tokens: [TokenDuration(mode: .hours)]),
                            (label: NSLocalizedString("Language: ", comment: ""), tokens: [TokenLanguage(mode: .flag)]),
                            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenMediaExtra(mode: .codec_short_name), TokenVideoMetadata(mode: .frames), TokenScript(mode: .inline(code: ""))]),
                        ]
                        vc.itemsView.validTokens = [TokenDimensional.self, TokenDuration.self, TokenLanguage.self, TokenMediaExtra.self, TokenVideoMetadata.self, TokenText.self, TokenScript.self]
                        
                        vc.itemsView.example = (self.example as? VideoInfo)?.videoTrack
                    }
                    vc.onSave = { vc in
                        self.contentView.window?.isDocumentEdited = true
                    }
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(vc)
                }
            } else if item.template == "[[audio]]" {
                cell?.editButton.image = NSImage(named: "contextualmenu.and.cursorarrow")
                cell?.editAction = {
                    guard let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ItemsEditorController") as? ItemsEditorController else {
                        return
                    }
                    vc.initView = { vc in
                        vc.title = NSLocalizedString("Audio track menu items", comment: "")
                        vc.itemsView.supportedType = .audio
                        vc.itemsView.getSettings = self.getSettings
                        vc.itemsView.formatSettings = self.getSettings().audioTrackSettings
                        vc.itemsView.sampleTokens = [
                            (label: NSLocalizedString("Length: ", comment: ""), tokens: [TokenDuration(mode: .hours)]),
                            (label: NSLocalizedString("Language: ", comment: ""), tokens: [TokenLanguage(mode: .flag)]),
                            (label: NSLocalizedString("Extra: ", comment: ""), tokens: [TokenMediaExtra(mode: .codec_short_name), TokenScript(mode: .inline(code: ""))]),
                            (label: NSLocalizedString("Metadata: ", comment: ""), tokens: [TokenAudioTrackMetadata(mode: .title)])
                        ]
                        vc.itemsView.validTokens = [TokenDuration.self, TokenLanguage.self, TokenMediaExtra.self, TokenAudioTrackMetadata.self, TokenText.self, TokenScript.self]

                        vc.itemsView.example = (self.example as? VideoInfo)?.audioTracks.first
                    }
                    vc.onSave = { vc in
                        self.contentView.window?.isDocumentEdited = true
                    }
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(vc)
                }
            } else {
                cell?.editAction = nil
            }
            return cell
        }
        
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MenuTokensCell"), owner: nil) as? MenuTokensCell
        // cell?.isIndented = row > 0 && settings.useFirstItemAsMain
        let attributedString: NSMutableAttributedString
        
        let infoType = example != nil ? type(of: example!).infoType : .none
        let info = MenuItemInfo(fileType: infoType, index: row, item: Settings.MenuItem(image: item.image, template: item.template))
        
        if isTagHidden, let s = item.formatted {
            attributedString = NSMutableAttributedString(attributedString: s)
        } else {
            let font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .light)
            attributedString = BaseInfo.replacePlaceholdersFake(in: item.template, settings: settings, attributes: [.font: font, .underlineStyle: NSUnderlineStyle.single.rawValue], forItem: info)
        }
        if row == 0 && settings.isUsingFirstItemAsMain {
            attributedString.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize), range: NSRange(location: 0, length: attributedString.length))
        }
        cell?.textField?.attributedStringValue = attributedString
        
        var img = MenuItemEditor.getImage(named: item.image)
        cell?.imageView?.image = img?.hasImage ?? false ? img?.image : nil
        return cell
    }
}

// MARK: - NSTableViewDataSource
extension MenuTableView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: NSPasteboard.PasteboardType(rawValue: "private.table-row"))
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        var oldIndexes = [Int]()
        info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:]) { item, _, _ in
            if let str = (item.item as! NSPasteboardItem).string(forType: NSPasteboard.PasteboardType(rawValue: "private.table-row")), let index = Int(str) {
                oldIndexes.append(index)
            }
        }

        let settings = self.getSettings()
        
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
            self.items.move(from: oldRow, to: newRow)
            self.formatSettings?.templates.move(from: oldRow, to: newRow)
            
            if settings.isUsingFirstItemAsMain {
                if oldRow == 0 {
                    tableView.reloadData(forRowIndexes: IndexSet(integer: newRow), columnIndexes: IndexSet(integer: 0))
                    tableView.reloadData(forRowIndexes: IndexSet(integer: 0), columnIndexes: IndexSet(integer: 0))
                } else if newRow == 0 {
                    tableView.reloadData(forRowIndexes: IndexSet(integer: 0), columnIndexes: IndexSet(integer: 0))
                    if items.count > 1 {
                        tableView.reloadData(forRowIndexes: IndexSet(integer: 1), columnIndexes: IndexSet(integer: 0))
                    }
                }
            }
        }
        
        tableView.endUpdates()
        updateSegmentedControl()
        
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateSegmentedControl()
    }
    
}

// MARK: - JSExceptionDelegate
extension MenuTableView: JSExceptionDelegate {
    func onJSException(info: BaseInfo, exception: String?, atLine line: Int, forItem item: MenuItemInfo?) {
        guard let itemIndex = item?.index else {
            return
        }
        if itemIndex >= 0 && itemIndex < self.items.count {
            let old = self.items[itemIndex].exception
            self.items[itemIndex].exception = exception
            self.items[itemIndex].line = line
            if old == nil {
                self.tableView.reloadData(forRowIndexes: IndexSet(integer: itemIndex), columnIndexes: IndexSet(integer: 1))
            }
        }
        NotificationCenter.default.post(name: .JSException, object: (info, exception, line, itemIndex))
    }
}

// MARK: - Extensions
extension NSResponder {
    public var parentViewController: NSViewController? {
        return nextResponder as? NSViewController ?? nextResponder?.parentViewController
    }
}

extension Array where Element: Equatable {
    mutating func move(_ element: Element, to newIndex: Index) {
        if let oldIndex: Int = self.firstIndex(of: element) {
            self.move(from: oldIndex, to: newIndex)
            
        }
    }
}

extension Array {
    mutating func move(from oldIndex: Index, to newIndex: Index) {
        // Don't work for free and use swap when indices are next to each other - this
        // won't rebuild array and will be super efficient.
        guard oldIndex != newIndex else {
            return
            
        }
        if abs(newIndex - oldIndex) == 1 {
            return self.swapAt(oldIndex, newIndex)
        }
        self.insert(self.remove(at: oldIndex), at: newIndex)
    }
}

// MARK: - ScriptCell
class ScriptCell: NSTableCellView {
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var exceptionButton: NSButton!
    @IBOutlet weak var infoButton: NSButton!
    
    var warnings: Set<String>? {
        didSet {
            exceptionButton?.isHidden = (warnings?.isEmpty ?? true) && (exception?.isEmpty ?? true)
        }
    }
    var exception: String? {
        didSet {
            exceptionButton?.isHidden = (warnings?.isEmpty ?? true) && (exception?.isEmpty ?? true)
        }
    }
    var line: Int?
    var info: Set<String>? {
        didSet {
            infoButton?.isHidden = info == nil || info!.isEmpty
        }
    }
    var editAction: (()->Void)? {
        didSet {
            editButton.isHidden = editAction == nil
        }
    }
    
    override func prepareForReuse() {
        self.exception = nil
        self.line = nil
        self.info = nil
        self.editAction = nil
        super.prepareForReuse()
    }
    
    @IBAction func handleJSButton(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Warning", comment: "")
        alert.alertStyle = .critical
        
        var msg = self.warnings?.joined(separator: "\n") ?? ""
        
        if let num = line, num >= 0 {
            if !msg.isEmpty {
                msg += "\n"
            }
            msg += NSLocalizedString(String(format: "JS Exception at line %d", num), comment: "") + ": "
        } else if !(self.exception?.isEmpty ?? true) {
            if !msg.isEmpty {
                msg += "\n"
            }
            msg += NSLocalizedString("JS Exception: ", comment: "")
        }
        msg += exception ?? ""
        
        alert.informativeText = msg
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "")).keyEquivalent = "\r"
        alert.runModal()
    }
    
    @IBAction func handleInfoButton(_ sender: Any) {
        guard let info = self.info, !info.isEmpty else {
            return
        }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = info.joined(separator: " \n")
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "")).keyEquivalent = "\r"
        alert.runModal()
    }
    
    @IBAction func handleEdit(_ sender: Any) {
        self.editAction?()
    }
}

// MARK: - MenuTokensCell

class MenuTokensCell: NSTableCellView {
    @IBOutlet weak var stackLeadingConstraint: NSLayoutConstraint!
    
    var isIndented: Bool = false {
        didSet {
            stackLeadingConstraint.constant = isIndented ? 26 : 2
        }
    }
}

