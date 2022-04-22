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
        static let noImageNames = ["no-image", "target-icon", "no-space", ""]
        let name: String
        let title: String
        let color: Bool
        let alternate_names: [String]
        let indent: Int
        
        var hasImage: Bool {
            return !name.isEmpty && !Self.noImageNames.contains(name)
        }
        lazy var image: NSImage? = {
            guard !Self.noImageNames.contains(name) else {
                let img: NSImage?
                if self.name == "" {
                    img = NSImage(named: "square.dashed")?.resized(to: NSSize(width: 16, height: 16))
                } else if self.name == "no-space" {
                    img = NSImage(named: "square.split.diagonal.2x2")?.resized(to: NSSize(width: 16, height: 16))
                } else if self.name == "target-icon" {
                    img = NSImage(named: "doc.viewfinder")?.resized(to: NSSize(width: 16, height: 16))
                } else {
                    img = NSImage(named: "no-image")?.resized(to: NSSize(width: 16, height: 16))
                }
                img?.isTemplate = !color
                return img
            }
            
            var name = self.name
            if name == "bleed" || name == "artbox" || name == "pdf" {
                name += "_v"
            }
            let img = NSImage(named: name)?.resized(to: NSSize(width: 16, height: 16))
            img?.isTemplate = !color
            return img
        }()
        
        init(name: String, title: String, color: Bool = false, alternateNames: [String] = [], indent: Int = 0) {
            self.name = name
            self.title = title
            self.color = color
            self.alternate_names = alternateNames
            self.indent = indent
        }
        
        func isValid(for name: String)->Bool {
            return self.name == name || self.alternate_names.contains(name)
        }
        
        static func separator() -> Image {
            return Image(name: "-", title: "-")
        }
    }
    
    static let images: [Image] = [
        Image(name: "", title: NSLocalizedString("No image", comment: "")),
        Image(name: "no-space", title: NSLocalizedString("No image (and no space)", comment: "")),
        Image(name: "target-icon", title: NSLocalizedString("Icon of current file", comment: "")),
        Image.separator(),
        Image(name: "image", title: NSLocalizedString("Image (auto oriented)", comment: "")),
        Image(name: "image_h", title: NSLocalizedString("Image (landscape)", comment: ""), indent: 1),
        Image(name: "image_v", title: NSLocalizedString("Image (portrait)", comment: ""), indent: 1),
        
        Image(name: "video", title: NSLocalizedString("Video (auto oriented)", comment: "")),
        Image(name: "video_h", title: NSLocalizedString("Video (landscape)", comment: ""), indent: 1),
        Image(name: "video_v", title: NSLocalizedString("Video (portrait)", comment: ""), indent: 1),
        
        Image(name: "audio", title: NSLocalizedString("Audio", comment: "")),
        Image(name: "txt", title: NSLocalizedString("Subtitle", comment: "")),
        Image(name: "pdf", title: NSLocalizedString("PDF (auto oriented)", comment: "")),
        Image(name: "pdf_v", title: NSLocalizedString("PDF (portrait)", comment: ""), indent: 1),
        Image(name: "pdf_h", title: NSLocalizedString("PDF (landscape)", comment: ""), indent: 1),
        
        Image(name: "office", title: NSLocalizedString("Office suite", comment: "")),
        Image(name: "doc", title: NSLocalizedString("Office text document (auto oriented)", comment: ""), alternateNames: ["docx", "word"]),
        Image(name: "doc_h", title: NSLocalizedString("Office text document (landscape)", comment: ""), alternateNames: ["docx_h", "word_h"], indent: 1),
        Image(name: "doc_v", title: NSLocalizedString("Office text document (portrait)", comment: ""), alternateNames: ["docx_v", "word_v"], indent: 1),
        Image(name: "xls", title: NSLocalizedString("Office spreadsheet", comment: ""), alternateNames: [ "xlsx", "excel"]),
        Image(name: "ppt", title: NSLocalizedString("Office presentation", comment: ""), alternateNames: ["pptx", "powerpoint"]),
        
        Image(name: "3d", title: NSLocalizedString("3D model", comment: ""), alternateNames: ["3D"]),
        Image(name: "zip", title: NSLocalizedString("Compressed archive", comment: "")),
        Image(name: "folder", title: NSLocalizedString("Folder", comment: "")),
        
        Image.separator(),
        
        Image(name: "aspectratio", title: NSLocalizedString("Aspect ratio (auto oriented)", comment: ""), alternateNames: ["ratio"]),
        Image(name: "aspectratio_h", title: NSLocalizedString("Aspect ratio (landscape)", comment: ""), alternateNames: ["ratio_h"], indent: 1),
        Image(name: "aspectratio_v", title: NSLocalizedString("Aspect ratio (portrait)", comment: ""), alternateNames: ["ratio_v"], indent: 1),
        Image(name: "size", title: NSLocalizedString("File size", comment: "")),
        Image(name: "print", title: NSLocalizedString("Printer", comment: ""), alternateNames: ["printer"]),
        Image(name: "person", title: NSLocalizedString("Person", comment: "")),
        Image(name: "person_y", title: NSLocalizedString("Person (allow)", comment: ""), indent: 1),
        Image(name: "person_n", title: NSLocalizedString("Person (deny)", comment: ""), indent: 1),
        Image(name: "people", title: NSLocalizedString("People", comment: "")),
        Image(name: "group_y", title: NSLocalizedString("Group (allow)", comment: ""), indent: 1),
        Image(name: "group_n", title: NSLocalizedString("Group (deny)", comment: ""), indent: 1),
        Image(name: "speaker", title: NSLocalizedString("Speaker (mono or stereo)", comment: "")),
        Image(name: "speaker_mono", title: NSLocalizedString("Speaker (mono)", comment: ""), indent: 1),
        Image(name: "speaker_stereo", title: NSLocalizedString("Speakers (stereo)", comment: ""), indent: 1),
        
        Image.separator(),
        Image(name: "color", title: NSLocalizedString("Color", comment: "")),
        Image(name: "color_bw", title: NSLocalizedString("Black and White", comment: "")),
        Image(name: "color_gray", title: NSLocalizedString("Gray scale", comment: ""), color: true),
        Image(name: "color_rgb", title: NSLocalizedString("RGB color", comment: ""), color: true),
        Image(name: "color_cmyk", title: NSLocalizedString("CMYK color", comment: ""), color: true),
        Image(name: "color_lab", title: NSLocalizedString("CIE Lab color", comment: ""), color: true),
        
        Image.separator(),
        Image(name: "page",   title: NSLocalizedString("PDF page (auto oriented)", comment: "")),
        Image(name: "page_h", title: NSLocalizedString("PDF page (landscape)", comment: ""), indent: 1),
        Image(name: "page_v", title: NSLocalizedString("PDF page (portrait)", comment: ""), indent: 1),
        Image(name: "pages",  title: NSLocalizedString("PDF number of pages", comment: "")),
        Image(name: "page",   title: NSLocalizedString("PDF media box (auto oriented)", comment: "")),
        Image(name: "bleed",  title: NSLocalizedString("PDF bleed box (auto oriented)", comment: "")),
        Image(name: "bleed_v",  title: NSLocalizedString("PDF bleed box (portrait)", comment: ""), indent: 1),
        Image(name: "bleed_h",  title: NSLocalizedString("PDF bleed box (landscape)", comment: ""), indent: 1),
        Image(name: "crop",   title: NSLocalizedString("PDF trim box", comment: "")),
        Image(name: "artbox", title: NSLocalizedString("PDF art box (auto oriented)", comment: "")),
        Image(name: "artbox_v", title: NSLocalizedString("PDF art box (portrait)", comment: ""), indent: 1),
        Image(name: "artbox_h", title: NSLocalizedString("PDF art box (landscape)", comment: ""), indent: 1),
        Image(name: "shield", title: NSLocalizedString("PDF security", comment: "")),
        
        Image.separator(),
        
        Image(name: "3d_points", title: NSLocalizedString("3D points", comment: "")),
        Image(name: "3d_lines", title: NSLocalizedString("3D lines", comment: "")),
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
        Image(name: "gearshape", title: NSLocalizedString("Gear", comment: ""), alternateNames: ["gear"]),
        Image(name: "script", title: NSLocalizedString("Script", comment: "")),
        Image(name: "calendar", title: NSLocalizedString("Calendar", comment: "")),
        Image(name: "clipboard", title: NSLocalizedString("Clipboard", comment: "")),
        Image(name: "flag", title: NSLocalizedString("Flag", comment: "")),
        Image(name: "info", title: NSLocalizedString("Info", comment: "")),
        Image(name: "abc", title: NSLocalizedString("ABC", comment: "")),
        Image(name: "exclamationmark", title: NSLocalizedString("Exclamation mark", comment: "")),
    ]
    
    static func getImage(named name: String) -> Image? {
        if let image = images.first(where: { $0.isValid(for: name) }) {
            return image
        }
        if #available(macOS 11.0, *) {
            if let _ = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
                return Image(name: name, title: name)
            }
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
            DispatchQueue.main.async {
                self.tokenField?.becomeFirstResponder()
                self.tokenField?.currentEditor()?.moveToEndOfLine(nil)
            }
            
        }
    }
    internal var imageName: String = "" {
        didSet {
            self.imagePopupButton?.selectItem(at: Self.images.firstIndex(where: { $0.isValid(for: self.imageName) }) ?? 0)
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
                item.indentationLevel = image.indent
                item.image = image.image
                imagePopupButton.menu?.addItem(item)
            }
        }
        /*
        if #available(macOS 11.0, *) {
            imagePopupButton.menu?.addItem(NSMenuItem.separator())
            let mnu = NSMenuItem(title: "Other…", action: nil, keyEquivalent: "")
            
            mnu.image = NSImage(systemSymbolName: "ellipsis", accessibilityDescription: nil)
            imagePopupButton.menu?.addItem(mnu)
        }
        */
        let size = self.tableView(self.tableView, sizeToFitWidthOfColumn: 0)
        tableView.tableColumns[0].width = size
        
        tokenField.tokenizingCharacterSet = CharacterSet(charactersIn: "\t")
        
        tokenField.objectValue = tokens
        
        self.imagePopupButton?.selectItem(at: Self.images.firstIndex(where: { $0.isValid(for: self.imageName) }) ?? 0)
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

// MARK: - NSTokenFieldDelegate
extension MenuItemEditor: NSTokenFieldDelegate {
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        var result: [Token] = []
        for token in tokens {
            if let t = token as? Token {
                if t.isValidFor(type: self.supportedType) && self.validTokens.contains(where: { type(of: t) == $0 }) {
                    t.isReadOnly = tokenField != self.tokenField
                    result.append(t)
                }
            } else if let text = token as? String {
                let t = TokenText(text: text)
                t.isReadOnly = tokenField != self.tokenField
                result.append(t)
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
            return self.tokenField == tokenField ? token.displayString : token.title
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
        
        token.isReadOnly = tokenField != self.tokenField
        return token.getMenu() { token, _ in
            if tokenField != self.tokenField {
                var tokens = self.tokenField.objectValue as? [Token] ?? []
                tokens.append(token)
                self.tokens = tokens
            }
            
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
