//
//  MenuTableView.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class MenuTableView: NSView {
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
    
    var items: [Settings.MenuItem] = []
    
    var example: BaseInfo?
    var supportedType: Token.SupportedType = .image
    
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
        
        tableView.doubleAction   = #selector(self.handleTableDoubleClick(_:))
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
            updateSegmentedControl()
        default:
            break
        }
    }
    
    func confirmRemoveItem(action: @escaping ()->Void) {
        let alert = NSAlert()
        alert.messageText = "Are you sure to remove this item?"
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: self.contentView.window!) { r in
            if r == .alertFirstButtonReturn {
                action()
            }
        }
    }
    
    internal func presentMenuEditor(row: Int) {
        guard let editor = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil).instantiateController(withIdentifier: "MenuItemEditor") as? MenuItemEditor else {
            return
        }
        
        let imageName: String
        let tokens: [Token]
        if row >= 0 {
            imageName = items[row].image
            tokens = Token.parseTemplate(items[row].template, for: self.supportedType)
        } else {
            imageName = ""
            tokens = []
        }
        editor.initialize(tokens: tokens, image: imageName, sampleTokens: sampleTokens)
        editor.validTokens = self.validTokens
        editor.supportedType = self.supportedType
        editor.doneAction = { image, tokens in
            if row >= 0 {
                self.items[row].image = image
                self.items[row].template = self.getTemplate(fromTokens: tokens)
                self.tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
            } else {
                let index = self.tableView.selectedRow
                if index >= 0 {
                    self.items.insert(Settings.MenuItem(image: image, template: self.getTemplate(fromTokens: tokens)), at: index+1)
                    self.tableView.insertRows(at: IndexSet(integer: index+1), withAnimation: .slideDown)
                    self.tableView.selectRowIndexes(IndexSet(integer: index+1), byExtendingSelection: false)
                } else {
                    self.items.append(Settings.MenuItem(image: image, template: self.getTemplate(fromTokens: tokens)))
                    self.tableView.reloadData()
                    // self.tableView.selectRowIndexes(IndexSet(integer: self.items.count-1), byExtendingSelection: false)
                }
            }
            self.contentView.window?.isDocumentEdited = true
        }
        
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
}

extension MenuTableView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        let settings = self.getSettings()
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MenuTokensCell"), owner: nil) as? NSTableCellView
        let attributedString: NSMutableAttributedString
        if isTagHidden, let example = example {
            // let font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            // let font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .light)
            // let font = NSFontManager.shared.convert(NSFont.systemFont(ofSize: NSFont.systemFontSize), toHaveTrait: [.italicFontMask])
            var isFilled = false
            let s = example.replacePlaceholders(in: item.template, settings: settings, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue], isFilled: &isFilled)
            if isFilled {
                attributedString = s
            } else {
                attributedString = BaseInfo.replacePlaceholdersFake(in: item.template, settings: settings, attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
            }
        } else {
            let font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .light)
            attributedString = BaseInfo.replacePlaceholdersFake(in: item.template, settings: settings, attributes: [.font: font, .underlineStyle: NSUnderlineStyle.single.rawValue])
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
