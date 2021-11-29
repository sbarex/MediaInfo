//
//  MenuItemEditor.swift
//  MediaInfoEx
//
//  Created by Sbarex on 16/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class MenuItemEditor: NSViewController {
    struct Image {
        static let noImageName = "no-image"
        let name: String
        let title: String
        let color: Bool
        
        var hasImage: Bool {
            return !name.isEmpty && name != Self.noImageName
        }
        lazy var image: NSImage? = {
            guard !name.isEmpty else {
                return NSImage(named: Self.noImageName)?.resized(to: NSSize(width: 16, height: 16))
            }
            var name = self.name
            if name == "page" || name == "bleed" || name == "artbox" || name == "pdf" {
                name += "_v"
            }
            let img = NSImage(named: name)?.resized(to: NSSize(width: 16, height: 16))
            img?.isTemplate = !color
            return img
        }()
        
        init(name: String, title: String, color: Bool = false) {
            self.name = name
            self.title = title
            self.color = color
        }
        
        static func separator() -> Image {
            return Image(name: "-", title: "-")
        }
    }
    
    static let images: [Image] = [
        Image(name: "", title: NSLocalizedString("No image", comment: ""), color: true),
        Image.separator(),
        Image(name: "image", title: NSLocalizedString("Image", comment: "")),
        Image(name: "video", title: NSLocalizedString("Video", comment: "")),
        Image(name: "audio", title: NSLocalizedString("Audio", comment: "")),
        Image(name: "txt", title: NSLocalizedString("Subtitle", comment: "")),
        Image(name: "pdf", title: NSLocalizedString("PDF", comment: "")),
        
        Image.separator(),
        Image(name: "aspectratio", title: NSLocalizedString("Aspect ratio", comment: "")),
        Image(name: "size", title: NSLocalizedString("File size", comment: "")),
        Image(name: "print", title: NSLocalizedString("Printer", comment: "")),
        Image(name: "person", title: NSLocalizedString("Person", comment: "")),
        Image(name: "speaker", title: NSLocalizedString("Speaker (mono or stereo)", comment: "")),
        Image(name: "speaker_mono", title: NSLocalizedString("Speaker", comment: "")),
        Image(name: "speaker_stereo", title: NSLocalizedString("Speakers", comment: "")),
        
        Image.separator(),
        Image(name: "color", title: NSLocalizedString("Color", comment: "")),
        Image(name: "color_bw", title: NSLocalizedString("Black and White", comment: "")),
        Image(name: "color_gray", title: NSLocalizedString("Gray scale", comment: ""), color: true),
        Image(name: "color_rgb", title: NSLocalizedString("RGB color", comment: ""), color: true),
        Image(name: "color_cmyk", title: NSLocalizedString("CMYK color", comment: ""), color: true),
        Image(name: "color_lab", title: NSLocalizedString("CIE Lab color", comment: ""), color: true),
        
        Image.separator(),
        Image(name: "page",   title: NSLocalizedString("PDF page", comment: "")),
        Image(name: "pages",  title: NSLocalizedString("PDF number of pages", comment: "")),
        Image(name: "page",   title: NSLocalizedString("PDF media box", comment: "")),
        Image(name: "bleed",  title: NSLocalizedString("PDF bleed box", comment: "")),
        Image(name: "crop",   title: NSLocalizedString("PDF trim box", comment: "")),
        Image(name: "artbox", title: NSLocalizedString("PDF art box", comment: "")),
        Image(name: "shield", title: NSLocalizedString("PDF security", comment: "")),
        
        Image.separator(),
        Image(name: "office", title: NSLocalizedString("Office suite", comment: "")),
        Image(name: "doc", title: NSLocalizedString("Office text document", comment: "")),
        Image(name: "xls", title: NSLocalizedString("Office spreadsheet", comment: "")),
        Image(name: "ppt", title: NSLocalizedString("Office presentation", comment: "")),
        
        Image.separator(),
        Image(name: "3d", title: NSLocalizedString("3D model", comment: "")),
        
        Image(name: "3d_point", title: NSLocalizedString("3D points", comment: "")),
        Image(name: "3d_line", title: NSLocalizedString("3D lines", comment: "")),
        Image(name: "3d_triangle", title: NSLocalizedString("3D triangle faces", comment: "")),
        Image(name: "3d_triangle_stripe", title: NSLocalizedString("3D triangle stripe", comment: "")),
        Image(name: "3d_quads", title: NSLocalizedString("3D quads faces", comment: "")),
        Image(name: "3d_variable", title: NSLocalizedString("3D variable faces", comment: "")),
        
        Image(name: "3d_normal", title: NSLocalizedString("3D normals", comment: "")),
        Image(name: "3d_tangent", title: NSLocalizedString("3D tangents", comment: "")),
        Image(name: "3d_color", title: NSLocalizedString("3D color per vertex", comment: ""), color: true),
        Image(name: "3d_uv", title: NSLocalizedString("3D texture coords", comment: "")),
        Image(name: "3d_occlusion", title: NSLocalizedString("3D occlusion per vertex", comment: ""), color: true),

        Image.separator(),
        Image(name: "tag", title: NSLocalizedString("Tag", comment: "")),
        Image(name: "pencil", title: NSLocalizedString("Pencil", comment: "")),
        Image(name: "abc", title: NSLocalizedString("ABC", comment: "")),
    ]
    
    static func getImage(named name: String) -> Image? {
        if let image = images.first(where: {$0.name == name}) {
            return image
        }
        return nil
    }
    
    @IBOutlet weak var tokenField: NSTokenField!
    @IBOutlet weak var imagePopupButton: NSPopUpButton!
    @IBOutlet weak var tableView: NSTableView!
    
    typealias TokenSample = (label: String, tokens: [Token])
    internal var sampleTokens: [TokenSample] = [] {
        didSet {
            tableView?.reloadData()
            if let tableView = self.tableView {
                let size = self.tableView(self.tableView, sizeToFitWidthOfColumn: 0)
                tableView.tableColumns[0].width = size
            }
        }
    }
    
    var supportedType: Token.SupportedType = .image
    internal var validTokens: [Token.Type] = []
    internal var tokens: [Token] = [] {
        didSet {
            tokenField?.objectValue = tokens
        }
    }
    internal var imageName: String = "" {
        didSet {
            self.imagePopupButton?.selectItem(at: Self.images.firstIndex(where: {$0.name == self.imageName}) ?? 0)
        }
    }
    
    var doneAction: (String, [Token])->Void = { _, _ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePopupButton.removeAllItems()
        
        for var image in Self.images {
            if image.name == "-" {
                imagePopupButton.menu?.addItem(NSMenuItem.separator())
            } else {
                let item = NSMenuItem(title: image.title, action: nil, keyEquivalent: "")
                item.image = image.image
                imagePopupButton.menu?.addItem(item)
            }
        }
        
        
        let size = self.tableView(self.tableView, sizeToFitWidthOfColumn: 0)
        tableView.tableColumns[0].width = size
        
        tokenField.tokenizingCharacterSet = CharacterSet(charactersIn: "\t")
        
        tokenField.objectValue = tokens
        self.imagePopupButton?.selectItem(at: Self.images.firstIndex(where: {$0.name == self.imageName}) ?? 0)
    }
    
    @IBAction func handleCancel(_ sender: Any) {
        self.view.window?.makeFirstResponder(nil) // Force tokens update
        self.dismiss(self)
    }
    
    @IBAction func handleDone(_ sender: Any) {
        self.view.window?.makeFirstResponder(nil) // Force tokens update
        let tokens = tokenField.objectValue as? [Token] ?? []
        if tokens.count > 1, let t = tokens.first(where: { $0 .requireSingle }) {
            let alert = NSAlert()
            alert.messageText = String(format: NSLocalizedString("Error, the token [%@] must be the only one.", comment: ""), t.displayString)
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
            return 
        }
        doneAction(Self.images[imagePopupButton.indexOfSelectedItem].name, tokens)
        self.dismiss(self)
    }
    
    func initialize(tokens: [Token], image: String, sampleTokens: [(label: String, tokens: [Token])]) {
        self.imageName = image
        self.tokens = tokens
        self.sampleTokens = sampleTokens
    }
}

extension MenuItemEditor: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sampleTokens.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = sampleTokens[row]
        if tableColumn?.identifier.rawValue == "label" {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("LabelCell"), owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = item.label
            return cell
        } else if tableColumn?.identifier.rawValue == "tokens" {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("TokenCell"), owner: nil) as? TokenCell
            cell?.tokenField.objectValue = item.tokens
            return cell
        } else {
            return nil
        }
    }
}

extension MenuItemEditor: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        guard column == 0 else {
            return 1000
        }
        let font = NSFont.labelFont(ofSize: NSFont.labelFontSize)
        var size: CGFloat = 0
        for t in self.sampleTokens {
            let label = t.label as NSString
            size = max(size, label.size(withAttributes: [.font: font]).width)
        }
        return size + 8 + tableView.intercellSpacing.width
    }
}

extension MenuItemEditor: NSTokenFieldDelegate {
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        var result: [Token] = []
        for token in tokens {
            if let t = token as? Token {
                if t.isValidFor(type: self.supportedType) && self.validTokens.contains(where: { type(of: t) == $0 }) {
                    result.append(t)
                }
            } else if let t = token as? String {
                result.append(TokenText(text: t))
            } else {
                print(token)
            }
        }
        return result
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        if let txt = representedObject as? TokenText {
            return txt.text
        } else if let token = representedObject as? Token {
            return token.displayString
        } else {
            return nil
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
        if representedObject is TokenText {
            return .default // FIXME: NSTokenField.TokenStyle.none cause crash!
        } else {
            return .default
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        if let s = representedObject as? TokenText {
            return s.text
        } else {
            return nil
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any? {
        return TokenText(text: editingString)
    }
    
    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        guard let token = representedObject as? Token else {
            return false
        }
        return token.hasMenu
    }
    
    func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
        guard let token = representedObject as? Token, token.hasMenu else {
            return nil
        }
        
        return token.getMenu() { _, _ in
            self.view.window?.makeFirstResponder(nil) // Force tokens update.
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, readFrom pboard: NSPasteboard) -> [Any]? {
        if let r = pboard.readObjects(forClasses: validTokens, options: nil) {
            return r.isEmpty ? nil : r
        }
        return nil
    }
    
    func tokenField(_ tokenField: NSTokenField, writeRepresentedObjects objects: [Any], to pboard: NSPasteboard) -> Bool {
        
        guard let o = objects as? [NSPasteboardWriting] else {
            return false
        }
        pboard.clearContents()
        pboard.writeObjects(o)
        return true
    }
}

class TokenCell: NSTableCellView {
    @IBOutlet weak var tokenField: NSTokenField!
}
