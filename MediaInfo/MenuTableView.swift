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
            case action
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
    
    var sampleTokens: [MenuItemEditor.TokenSample] = []
    var validTokens: [Token.Type] = []
    
    var items: [MenuItem] = []
    
    var example: BaseInfo? {
        didSet {
            oldValue?.jsExceptionDelegate = nil
            example?.jsExceptionDelegate = self
        }
    }
    var supportedType: Token.SupportedType = .image
    weak var viewController: ViewController?
    
    var getSettings: ()->Settings = { return Settings(fromDict: [:]) }
    
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
            items.move(from: index, to: index - 1)
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
            items.move(from: index, to: index + 1)
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
                self.tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integersIn: 0...1))
            } else {
                let index = self.tableView.selectedRow
                if index >= 0 {
                    self.items.insert(MenuItem(image: image, template: self.getTemplate(fromTokens: tokens)), at: index+1)
                    self.tableView.insertRows(at: IndexSet(integer: index+1), withAnimation: .slideDown)
                    self.tableView.selectRowIndexes(IndexSet(integer: index+1), byExtendingSelection: false)
                } else {
                    self.items.append(MenuItem(image: image, template: self.getTemplate(fromTokens: tokens)))
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
        for (i, item) in self.items.enumerated() {
            self.refreshItem(item, atIndex: i, force: force, example: example, settings: settings)
        }
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
                        case .action: item.scriptType = .action
                        }
                    }
                }
            }
        }
        
        if item.formatted == nil || force {
            if let example = example {
                let info = MenuItemInfo(fileType: example.infoType, index: i, item: Settings.MenuItem(image: item.image, template: item.template))
                
                var isFilled = false
                item.formatted = example.replacePlaceholders(in: item.template, settings: settings, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue], isFilled: &isFilled, forItem: info)
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
            
            if item.scriptType == .global || item.scriptType == .action, item.template.hasPrefix("[[script-global:") || item.template.hasPrefix("[[script-action:") {
                cell?.editButton.image = NSImage(named: "applescript")
                cell?.editButton.toolTip = NSLocalizedString("Edit the script…", comment: "")
                cell?.editAction = {
                        let tokens = self.getTokens(from: item.template)
                    (tokens.first as? TokenScript)?.editScript(action: { _ in
                        item.template = self.getTemplate(fromTokens: tokens)
                        item.info = nil
                        self.window?.isDocumentEdited = true
                        self.tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integersIn: 0...1))
                    })
                }
            } else if item.template.hasPrefix("[[open-with:") {
                cell?.editButton.image = NSImage(named: "folder")
                cell?.editButton.toolTip = NSLocalizedString("Choose the application…", comment: "")
                cell?.editAction = {
                        let tokens = self.getTokens(from: item.template)
                    (tokens.first as? TokenAction)?.editPath(action: { _ in
                        item.template = self.getTemplate(fromTokens: tokens)
                        item.info = nil
                        self.window?.isDocumentEdited = true
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
                        vc.itemsView.items = self.getSettings().videoTracksMenuItems.map({ MenuTableView.MenuItem(image: $0.image, template: $0.template)})
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
                        self.viewController?.videoTracksMenuItems = vc.itemsView.items.map({ Settings.MenuItem(image: $0.image, template: $0.template)})
                    }
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(vc)
                    
                    self.window?.isDocumentEdited = true
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
                        vc.itemsView.items = self.getSettings().audioTracksMenuItems.map({ MenuTableView.MenuItem(image: $0.image, template: $0.template)})
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
                        self.viewController?.audioTracksMenuItems = vc.itemsView.items.map({ Settings.MenuItem(image: $0.image, template: $0.template)})
                    }
                    NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(vc)
                    
                    self.window?.isDocumentEdited = true
                }
            } else {
                cell?.editAction = nil
            }
            return cell
        }
        
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MenuTokensCell"), owner: nil) as? MenuTokensCell
        // cell?.isIndented = row > 0 && settings.useFirstItemAsMain
        let attributedString: NSMutableAttributedString
        
        let info = MenuItemInfo(fileType: example?.infoType ?? .none, index: row, item: Settings.MenuItem(image: item.image, template: item.template))
        
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

// MARK: -
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
