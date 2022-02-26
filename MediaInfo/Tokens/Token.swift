//
//  Token.swift
//  MediaInfoEx
//
//  Created by Sbarex on 11/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

extension NSPasteboard.PasteboardType {
    static let MIToken = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token")
    static let MITokenDimensional = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-dim")
    static let MITokenDuration = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-time")
    static let MITokenFile = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-file")
    static let MITokenOpenWith = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-open-with")
    static let MITokenImageExtra = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-image-extra")
    static let MITokenVideoExtra = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-video-extra")
    static let MITokenMediaTrack = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-media-track")
    static let MITokenColor = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-color")
    static let MITokenPrint = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-print")
    static let MITokenLanguage = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-language")
    static let MITokenLanguages = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-languages")
    static let MIText = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-text")
    static let MITokenPDFBox = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-pdfbox")
    static let MITokenPDFMetadata = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-pdf-metadata")
    static let MITokenOfficeSize = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-office-size")
    static let MITokenOfficeMetadata = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-office-metadata")
    static let MITokenVideoMetadata = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-video-metadata")
    static let MITokenAudioMetadata = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-audio-metadata")
    static let MITokenModelMetadata = NSPasteboard.PasteboardType(rawValue: "org.sbarex.model-metadata")
    static let MITokenArchiveTrack = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-archive-track")
    static let MITokenScript = NSPasteboard.PasteboardType(rawValue: "org.sbarex.mi-token-script")
}

protocol BaseMode {
    static var pasteboardType: NSPasteboard.PasteboardType { get }
    
    var displayString: String { get }
    var placeholder: String { get }
    var tooltip: String? { get }
    var title: String { get }
    
    init?(placeholder: String)
    init?(integer: Int)
    
    init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType)
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any?
}

extension BaseMode {
    var displayString: String { return "TOKEN" }
    var placeholder: String { return "" }
    var tooltip: String? { return nil }
    var title: String { return displayString }
    
    init?(placeholder: String) { return nil }
}

extension BaseMode where Self: RawRepresentable, Self.RawValue == Int {
    init?(integer: Int) {
        self.init(rawValue: integer)
    }
    
    init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        guard type == Self.pasteboardType, let data = propertyList as? Data, let t = String(data: data, encoding: .utf8), let n = Int(t) else {
            return nil
        }
        self.init(rawValue: n)
    }
    
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        return "\(self.rawValue)"
    }
}

protocol BaseToken {
    static var ModeClass: BaseMode.Type { get }
    var mode: BaseMode { get }
    var informativeMessage: String { get }
}

class Token: NSObject, NSPasteboardWriting, NSPasteboardReading, BaseToken {
    enum SupportedType: Int, CaseIterable {
        case image
        case video
        case audio
        case pdf
        case subtitle
        case office
        case model
        case archive
    }
    
    enum Mode: Int, BaseMode {
        case none = 0
        
        static var pasteboardType: NSPasteboard.PasteboardType { return .MIToken }
    }
    class var ModeClass: BaseMode.Type {
        return Mode.self
    }
    
    class var supportedTypes: [SupportedType] {
        return []
    }
    
    var requireSingle: Bool {
        return false
    }
    
    var mode: BaseMode = Mode.none
    
    var placeholder: String {
        return mode.placeholder
    }
    var displayString: String {
        return mode.displayString
    }
    var title: String {
        return "Token"
    }
    
    var informativeMessage: String {
        return ""
    }
    
    var hasMenu: Bool { return true }
    var callbackMenu: ((Token, NSMenuItem)->Void)?
    
    var isReadOnly: Bool = true
    
    override init() {
        super.init()
    }
    
    required init?(mode: BaseMode) {
        super.init()
        self.mode = mode
    }
    
    required init?(placeholder: String) {
        if let mode = Self.ModeClass.init(placeholder: placeholder) {
            super.init()
            self.mode = mode
        } else {
            return nil
        }
    }
    
    // MARK: - Pasteboard Writing Protocol
    @objc func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [Self.ModeClass.pasteboardType]
    }
    
    @objc func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        return mode.pasteboardPropertyList(forType: type)
    }
    
    // MARK: - Pasteboard Reading Protocol
    class func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [Self.ModeClass.pasteboardType]
    }
    static func readingOptionsForType(type: String!, pasteboard: NSPasteboard!) -> NSPasteboard.ReadingOptions {
        return .asString
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        guard let mode = Self.ModeClass.init(pasteboardPropertyList: propertyList, ofType: type) else {
            return nil
        }
        super.init()
        self.mode = mode
    }
    
    static func parseTemplate(_ template: String, for supportedType: SupportedType) -> [Token] {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[([^]]+)\]\]"#) else {
            return []
        }
        let results = regex.matches(in: template,
                                            range: NSRange(template.startIndex..., in: template))
        
        let tokenClasses = [
            TokenDimensional.self,
            TokenDuration.self,
            TokenColor.self,
            TokenLanguage.self, TokenLanguages.self,
            TokenImageExtra.self, TokenMediaExtra.self,
            TokenFile.self,
            TokenPrint.self,
            TokenPdfBox.self, TokenPdfMetadata.self,
            TokenVideoMetadata.self,
            TokenAudioMetadata.self,
            TokenMediaTrack.self,
            TokenOfficeSize.self,
            TokenOfficeMetadata.self,
            TokenArchive.self,
            TokenScript.self, TokenOpenWith.self
        ]
        var tokens: [Token] = []
        
        var prev_index = 0
        for result in results {
            if prev_index < result.range.lowerBound {
                let s = template[template.index(template.startIndex, offsetBy: prev_index)..<template.index(template.startIndex, offsetBy: result.range.lowerBound)]
                tokens.append(TokenText(text: String(s)))
            }
            let placeholder = String(template[Range(result.range, in: template)!])
            var token: Token! = nil
            for tokenClass in tokenClasses {
                if tokenClass.supportedTypes.contains(supportedType), let t = tokenClass.init(placeholder: placeholder) {
                    token = t
                    break
                }
            }
            if token == nil {
                token = TokenText(text: placeholder)
            }
            
            tokens.append(token)
            prev_index = result.range.upperBound
        }
        if prev_index < template.count {
            let s = template[template.index(template.startIndex, offsetBy: prev_index)...]
            tokens.append(TokenText(text: String(s)))
        }
        return tokens
    }
    
    func createMenuItem(title: String, state: Bool, tag: Int, tooltip: String?) -> NSMenuItem {
        let mnu = NSMenuItem(title: title, action: #selector(self.handleTokenMenu(_:)), keyEquivalent: "")
        mnu.representedObject = self
        mnu.state = state ? .on : .off
        mnu.isEnabled = true
        mnu.tag = tag
        mnu.toolTip = tooltip
        mnu.target = self
        return mnu
    }
    
    func createMenu() -> NSMenu? {
        return nil
    }
    
    func getMenu(callback: @escaping ((Token, NSMenuItem)->Void)) -> NSMenu? {
        let menu = self.createMenu()
        menu?.showsStateColumn = !self.isReadOnly
        
        self.callbackMenu = callback
        
        return menu
    }
    
    func isValidFor(type supportedType: SupportedType) -> Bool {
        return Self.supportedTypes.contains(supportedType)
    }
    
    func getTokenFromSender(_ sender: NSMenuItem) -> BaseMode? {
        return Self.ModeClass.init(integer: sender.tag)
    }
    
    @IBAction func handleTokenMenu(_ sender: NSMenuItem) {
        guard let token = sender.representedObject as? Self, let mode = self.getTokenFromSender(sender), type(of: mode) == type(of: self).ModeClass else {
            return
        }
        
        if self.isReadOnly {
            if let t = Self.init(mode: mode) {
                self.callbackMenu?(t, sender)
            }
        } else {
            token.mode = mode
            self.callbackMenu?(self, sender)
        }
    }
}

// MARK: - TokenText
class TokenText: Token {
    enum Mode: Int, BaseMode {
        case text = 0
        
        static var pasteboardType: NSPasteboard.PasteboardType {
            return .MIText
        }
    }
    override class var ModeClass: BaseMode.Type {
        return Mode.self
    }
    
    override class var supportedTypes: [SupportedType] {
        return SupportedType.allCases
    }
    
    override var hasMenu: Bool { return false }
    
    var text: String
    override var placeholder: String {
        return text
    }
    override var title: String { return self.text }
    
    init(text: String) {
        self.text = text
        super.init()
    }
    
    init(mode: Mode) {
        self.text = ""
        super.init()
        self.mode = mode
    }
    
    required convenience init?(mode: BaseMode) {
        self.init(mode: mode)
    }
    
    required convenience init?(placeholder: String) {
        self.init(text: placeholder)
    }
    
    // MARK: - Pasteboard Writing Protocol
    @objc override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        return text
    }
    
    
    // MARK: - Pasteboard Reading Protocol
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        guard type == Self.ModeClass.pasteboardType, let data = propertyList as? Data, let t = String(data: data, encoding: .utf8) else {
            return nil
        }
        text = t
        super.init()
    }
}
