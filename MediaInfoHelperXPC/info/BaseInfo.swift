//
//  BaseInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import JavaScriptCore

extension NSNotification.Name {
    static let JSConsole = NSNotification.Name(rawValue: "JSConsole")
    static let JSException = NSNotification.Name(rawValue: "JSException")
}

extension CodingUserInfoKey {
    static let exportStoredValues = CodingUserInfoKey(rawValue: "exportStored")!
}

protocol JSExceptionDelegate: AnyObject {
    func onJSException(info: BaseInfo, exception: String?, atLine line: Int, forItemAtIndex itemIndex: Int)
}

enum JSException: Error {
    case exception(desc: String, line: Int)
}

// MARK: - BaseInfo
class BaseInfo: Codable {
    static let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.allowsFloats = true
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        
        return numberFormatter
    }()
    static let byteCountFormatter:ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        
        return formatter
    }()
    
    static func getImage(for mode: String) -> NSImage? {
        var img: NSImage?
        var isColor = false
        switch mode {
        case "image", "image_h":
            img = NSImage(named: "image")
        case "image_v":
            img = NSImage(named: "image_v")
        case "aspectratio_h":
            img = NSImage(named: "aspectratio")
        case "color":
            img = NSImage(named: "color")
        case "color_rgb":
            img = NSImage(named: "color_rgb")
            isColor = true
        case "color_cmyk":
            img = NSImage(named: "color_cmyk")
            isColor = true
        case "color_gray":
            img = NSImage(named: "color_gray")
            isColor = true
        case "color_lab":
            img = NSImage(named: "color_lab")
            isColor = true
        case "color_bw":
            img = NSImage(named: "color_bw")
            isColor = true
        case "print", "printer":
            img = NSImage(named: "print")
        case "video", "video_h":
            img = NSImage(named: "video")
        case "video_v":
            img = NSImage(named: "video_v")
        case "audio":
            img = NSImage(named: "audio")
        case "text":
            img = NSImage(named: "txt")
        case "ratio":
            img = NSImage(named: "aspectratio")
        case "ratio_v":
            img = NSImage(named: "aspectratio_v")
        case "size":
            img = NSImage(named: "size")
        case "page", "page_h":
            img = NSImage(named: "page")
        case "page_v":
            img = NSImage(named: "page_v")
            
        case "pages":
            img = NSImage(named: "pages")
        case "tag":
            img = NSImage(named: "tag")
        case "pencil":
            img = NSImage(named: "pencil")
            
        case "office":
            img = NSImage(named: "doc")
        case "doc", "docx", "word":
            img = NSImage(named: "doc")
        case "xls", "xlsx", "excel":
            img = NSImage(named: "xls")
        case "ppt", "pptx", "powerpoint":
            img = NSImage(named: "ppt")
        case "abc":
            img = NSImage(named: "abc")
        case "speaker":
            img = NSImage(named: "speaker_mono")
            
        case "3d", "3D":
            img = NSImage(named: "3d")
        case "3d_color":
            img = NSImage(named: mode)
            isColor = true
        case "3d_occlusion":
            img = NSImage(named: mode)
            isColor = true
            
        default:
            img = NSImage(named: mode)
        }
        
        img = img?.resized(to: NSSize(width: 16, height: 16))
        if !isColor {
            img?.isTemplate = true
            let i = img?.image(withTintColor: NSColor.labelColor)
            i?.isTemplate = true
            return i
        } else {
            return img
        }
    }
    
    var jsInitialized = false
    
    lazy fileprivate(set) var jsContext: JSContext? = {
        let context = self.initJSContext()
        jsInitialized = true
        return context
    }()
    
    weak var jsDelegate: JSExceptionDelegate?
    
    /// In debug mode allow the js log. Must be set before initialize the js context.
    static var debugJS: Bool = false
    
    static var jsOpen: (@convention(block) (String) -> Void)?
    static var jsExec: (@convention(block) (String, [String]) -> Void)?
    static var menuAction: ((BaseInfo, NSMenuItem)->Void)?
    
    // MARK: -
    init() { }
    
    required init(from decoder: Decoder) throws {
        
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
    
    // MARK: - Script support
    func initJSContext() -> JSContext? {
        guard let context = JSContext() else {
            return nil
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.exportStoredValues] = true
        
        context.exceptionHandler = { context, exception in
            print(exception?.toString() ?? "JS exception!")
        }
       
        /*
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try! encoder.encode(self)
        print(String(data: data, encoding: .utf8)!)
        encoder.outputFormatting = JSONEncoder.OutputFormatting(rawValue: 0)
        */
        
        context.evaluateScript("""
function deepFreeze(object) {
  // Retrieve the property names defined on object
  const propNames = Object.getOwnPropertyNames(object);

  // Freeze properties before freezing self

  for (const name of propNames) {
    const value = object[name];

    if (value && typeof value === "object") {
      deepFreeze(value);
    }
  }

  return Object.freeze(object);
}
const console = {
    debug: function() {
        let a = Array.prototype.slice.call(arguments);
        a.unshift("debug");
        __consoleLog(a);
    },
    log: function() {
        let a = Array.prototype.slice.call(arguments);
        a.unshift("log");
        __consoleLog(a);
    },
    info: function() {
        let a = Array.prototype.slice.call(arguments);
        a.unshift("info");
        __consoleLog(a);
    },
    warn: function() {
        let a = Array.prototype.slice.call(arguments);
        a.unshift("warn");
        __consoleLog(a);
    },
    error: function() {
        let a = Array.prototype.slice.call(arguments);
        a.unshift("error");
        __consoleLog(a);
    },
    assert: function() {
        let a = Array.prototype.slice.call(arguments);
        if (a.shift()) {
            a.unshift("info");
            __consoleLog(a);
        }
    },
}
deepFreeze(console);

let selectedMenuItem = null;
""");
        if Self.debugJS {
            let logFunction: @convention(block) ([AnyHashable]) -> Void  = { (object: [AnyHashable]) in
                let level = object.first as? String ?? "info"
                NotificationCenter.default.post(name: .JSConsole, object: (self, level, Array(object.dropFirst())))
            }
            context.setObject(logFunction, forKeyedSubscript: "__consoleLog" as NSString)
        } else {
            context.evaluateScript("function __consoleLog() { }")
        }
        if let data = try? encoder.encode(self), let s = String(data: data, encoding: .utf8) {
            context.setObject(s , forKeyedSubscript: "fileJSONData" as NSString)
            context.evaluateScript("const fileData = JSON.parse(fileJSONData); ")
            context.evaluateScript("""
if (fileData["metadataRaw"]) {
    for (key in fileData["metadataRaw"]) {
        if (!fileData["metadataRaw"].hasOwnProperty(key)) {
            continue;
        }
        fileData["metadataRaw"][key] = JSON.parse(fileData["metadataRaw"][key]);
    }
}
delete fileJSONData;
""")
        } else {
            context.setObject(nil, forKeyedSubscript: "fileJSONData" as NSString)
        }
        context.evaluateScript("deepFreeze(fileData);")
        /*
        let logFunction: @convention(block) (String) -> Void  = { (object: AnyHashable) in
            print("JSConsole: ", object)
        }
        context.setObject(logFunction, forKeyedSubscript: "__consoleLog" as NSString)
         */
        
        return context
    }
    
    /// Reset the Javascript context for the specified settings.
    /// Embed in the context the `settings` var.
    /// - parameters:
    ///    - settings:
    func resetJSContext(settings: Settings?) {
        self.jsContext = initJSContext()
        
        guard let context = self.jsContext else { return }
        if let settings = settings {
            let encoder = JSONEncoder()
            encoder.userInfo[.exportStoredValues] = true
            
            if let data = try? encoder.encode(settings), let s = String(data: data, encoding: .utf8) {
                context.setObject(s, forKeyedSubscript: "settingsJSONData" as NSString)
                context.evaluateScript("const settings = JSON.parse(settingsJSONData); delete settingsJSONData;")
                // context.evaluateScript("console.log(settings); ")
            } else {
                context.setObject(nil, forKeyedSubscript: "fileJSONData" as NSString)
            }
        } else {
            context.setObject(nil, forKeyedSubscript: "settings" as NSString)
        }
        context.evaluateScript("deepFreeze(settings);")
        
    }
    
    /// Initialize the context cor the action token.
    func initActionJSContext(selectedItem: NSMenuItem) {
        guard let context = self.jsContext else { return }
        
        if let jsOpen = Self.jsOpen {
            context.setObject(jsOpen, forKeyedSubscript: "systemOpen" as NSString)
        }
        if let jsExec = Self.jsExec {
            context.setObject(jsExec, forKeyedSubscript: "systemExec" as NSString)
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.exportStoredValues] = true
        
        if let data = try? encoder.encode(selectedItem), let s = String(data: data, encoding: .utf8) {
            context.setObject(s, forKeyedSubscript: "menuJSONData" as NSString)
            context.evaluateScript("selectedMenuItem = JSON.parse(menuJSONData); delete menuJSONData;")
            // context.evaluateScript("console.log(selectedMenuItem); ")
        } else {
            context.setObject(nil, forKeyedSubscript: "selectedMenuItem" as NSString)
        }
        context.evaluateScript("Object.freeze(selectedMenuItem);")
    }
    
    func evaluateScript(code: String, forItem itemIndex: Int, extendExceptionHandler: Bool = true) throws -> JSValue? {
        guard let context = self.jsContext else {
            return nil
        }
        var js_exception: JSException?
        let old_exceptionHandler = context.exceptionHandler
        if extendExceptionHandler {
            context.exceptionHandler = { context, exception in
                let line_num = exception?.objectForKeyedSubscript("line")?.toNumber().intValue ?? -1
                let message = exception?.toString()
                js_exception = JSException.exception(desc: message ?? "", line: line_num)
                self.jsDelegate?.onJSException(info: self, exception: message, atLine: line_num, forItemAtIndex: itemIndex)
                old_exceptionHandler?(context, exception)
            }
        }
        defer {
            if extendExceptionHandler {
                context.exceptionHandler = old_exceptionHandler
            }
        }
        context.setObject(itemIndex, forKeyedSubscript: "templateItemIndex" as NSString)
        let result = context.evaluateScript(code)
        
        if let js_exception = js_exception {
            throw js_exception
        }
        
        return result
    }
    
    // MARK: - Placeholder support.
    internal func processPlaceholder(_ placeholder: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        isFilled = false
        if placeholder.hasPrefix("[[script-inline:") {
            guard let code = String(placeholder.dropFirst(16).dropLast(2)).fromBase64(), !code.isEmpty else {
                isFilled = false
                return ""
            }
            
            if !self.jsInitialized {
                self.resetJSContext(settings: settings)
            }
            
            guard let result = try? evaluateScript(code: code, forItem: itemIndex) else {
                isFilled = false
                return ""
            }
            guard !result.isNull else {
                isFilled = false
                return ""
            }
            if !result.isString {
                self.jsDelegate?.onJSException(info: self, exception: NSLocalizedString("Inline script token must return a string value!", comment: ""), atLine: -1, forItemAtIndex: itemIndex)
            }
            if let r = result.toString() {
                isFilled = true
                return r
            } else {
                return ""
            }
        } else {
            return placeholder
        }
    }
    
    func purgeString(_ text: String) -> String {
        var text = text
        // Remove empty brackets: empty, or with only spaces, comma, semicolon or pipe.
        text = text.replacingOccurrences(of: #"\s*\([\s,;|]*\)"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s*\[[\s,;|]*\]"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s*\<[\s,;|]*\>"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s*\{[\s,;|]*\}"#, with: " ", options: .regularExpression)
        // Remove consecutive comma (or semicolon or pipe) separated only by spaces.
        text = text.replacingOccurrences(of: #"[,;|]\s*([,;|])"#, with: "$1", options: .regularExpression)
        // Remove multiple spaces
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        // Trim spaces, comma, semicolon and pipe.
        text = text.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ",;|")))
        // Capitalize first letter.
        text = text.capitalizingFirstLetter()
        
        return text
    }
    
    /// Translate the placeholder inside the template
    /// - parameters:
    ///   - template: Template with the placeholders to replace.
    ///   - settings: Settings used to customize the data.
    ///   - values: Values that override the standard value.
    ///   - isFilled: Set to `true` when at least one placeholder is replaced.
    ///   - itemIndex: Index of the menu item.
    func replacePlaceholders(in template: String, settings: Settings, isFilled: inout Bool, forItem itemIndex: Int) -> String {
        let results = Self.splitTokens(in: template)
        
        var text = template
       
        isFilled = false
        var isPlaceholderFilled = false
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r = processPlaceholder(placeholder, settings: settings, isFilled: &isPlaceholderFilled, forItem: itemIndex)
            if isPlaceholderFilled {
                isFilled = true
            }
            text = text.replacingOccurrences(of: placeholder, with: r)
        }
        
        text = purgeString(text)
        
        return text
    }
    
    /// Translate the placeholder inside the template
    /// - parameters:
    ///   - template: Template with the placeholders to replace.
    ///   - settings: Settings used to customize the data.
    ///   - attributes: Attributes used to format the value of placeholders.
    ///   - values: Values that override the standard value.
    ///   - isFilled: Set to `true` when at least one placeholder is replaced.
    ///   - itemIndex: Index of the menu item.
    func replacePlaceholders(in template: String, settings: Settings, attributes: [NSAttributedString.Key: Any]? = nil, isFilled: inout Bool, forItem itemIndex: Int) -> NSMutableAttributedString {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[([^]]+)\]\]"#) else {
            return NSMutableAttributedString(string: template)
        }
        let results = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        
        let text = NSMutableAttributedString(string: template)
        
        isFilled = false
        var isPlaceholderFilled = false
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r = processPlaceholder(placeholder, settings: settings, isFilled: &isPlaceholderFilled, forItem: itemIndex)
            if isPlaceholderFilled {
                isFilled = true
            }
            guard r != placeholder else {
                continue
            }
            while text.mutableString.contains(placeholder) {
                let range = text.mutableString.range(of: placeholder)
                text.replaceCharacters(in: range, with: NSAttributedString(string: r, attributes: attributes))
            }
        }
        
        // Remove empty brackets: empty, or with only spaces, comma, semicolon or pipe.
        text.mutableString.replaceOccurrences(of: #"\s*\([\s,;|]*\)"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        text.mutableString.replaceOccurrences(of: #"\s*\[[\s,;|]*\]"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        text.mutableString.replaceOccurrences(of: #"\s*\<[\s,;|]*\>"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        text.mutableString.replaceOccurrences(of: #"\s*\{[\s,;|]*\}"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        // Remove consecutive comma (or semicolon or pipe) separated only by spaces.
        text.mutableString.replaceOccurrences(of: #"[,;|]\s*([,;|])"#, with: "$1", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        // Remove multiple spaces
        text.mutableString.replaceOccurrences(of: #"\s+"#, with: " ", options: .regularExpression, range: NSMakeRange(0, text.mutableString.length))
        
        // Trim spaces, comma, semicolon and pipe.
        text.trimCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ",;|")))
        // Capitalize first letter.
        return text.capitalizingFirstLetter()
    }
    
    static func splitTokens(in template: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[([^]]+)\]\]"#) else {
            return []
        }
        let results = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        return results
    }
    
    func getStandardTitle(forSettings settings: Settings) -> String {
        return ""
    }
    
    internal func getImage(for name: String) -> NSImage? {
        return Self.getImage(for: name)
    }
    
    internal func createMenuItem(title: String, image: String?, settings: Settings, tag: Int) -> NSMenuItem {
        let mnu = NSMenuItem(title: title, action: #selector(self.fakeMenuAction(_:)), keyEquivalent: "")
        mnu.isEnabled = true
        mnu.target = self
        if !settings.isIconHidden {
            if image == "no-space" {
                mnu.image = nil
            } else if let image = image, !image.isEmpty {
                mnu.image = self.getImage(for: image)
            } else {
                mnu.image = self.getImage(for: "no-image")
            }
        } else {
            mnu.image = nil
        }
        mnu.tag = tag
        return mnu
    }
    
    func getMenu(withSettings settings: Settings) -> NSMenu? {
        return nil
    }
    
    internal func generateMenu(items: [Settings.MenuItem], image: NSImage?, withSettings settings: Settings) -> NSMenu? {
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let use_submenu  = settings.isInfoOnSubMenu
        
        // ALERT: NSMenuItem in the extension do not preserve the image template rendering mode, delegate, attributedTitle (rendered as simple string), isAlternate, separator (render as a menu item with an empty title). See the FIFinderSyncProtocol source file for the list of valid properties.
        
        let destination_sub_menu: NSMenu
        if use_submenu {
            let info_sub_menu = NSMenu(title: "MediaInfo")
            let info_mnu = menu.addItem(withTitle: "MediaInfo", action: nil, keyEquivalent: "")
            info_mnu.image = image
            
            menu.setSubmenu(info_sub_menu, for: info_mnu)
            destination_sub_menu = info_sub_menu
        } else {
            destination_sub_menu = menu
        }
        
        var isFirst = true
        var isFirstFilled = false
        self.jsInitialized = false // Force JSContext reset.
        for (i, item) in items.enumerated() {
            defer {
                isFirst = false
            }
            if self.processSpecialMenuItem(item, atIndex: i, inMenu: destination_sub_menu, withSettings: settings) {
                continue
            }
            
            var isFilled = false
            let s = self.replacePlaceholders(in: item.template, settings: settings, isFilled: &isFilled, forItem: i)
            if s.isEmpty || (settings.isEmptyItemsSkipped && !isFilled) {
                continue
            }
            if isFirst {
                isFirstFilled = true
            }
            let mnu = self.createMenuItem(title: s, image: item.image, settings: settings, tag: i)
            destination_sub_menu.addItem(mnu)
        }
        
        self.formatMainTitleMenu(mainMenu: menu, destination_sub_menu: destination_sub_menu, isFirstFilled: isFirstFilled, settings: settings)
        
        return menu
    }
    
    internal func generateMenuFromGlobalScript(_ result: [Any], in submenu: NSMenu, settings: Settings, forItem itemIndex: Int) -> Bool {
        guard !result.isEmpty else {
            return false
        }
        var n = 0
        for item in result {
            if let title = item as? String {
                if title == "-" {
                    submenu.addItem(NSMenuItem.separator())
                } else {
                    let mnu = self.createMenuItem(title: title, image: nil, settings: settings, tag: itemIndex)
                    submenu.addItem(mnu)
                }
                n += 1
            } else if let item = item as? [String: AnyHashable] {
                guard let title = item["title"] as? String else {
                    continue
                }
                if title == "-" {
                    submenu.addItem(NSMenuItem.separator())
                    continue
                }
                let image = item["image"] as? String
                let mnu = self.createMenuItem(title: title, image: image, settings: settings, tag: itemIndex)
                if let b = item["checked"] as? Bool, b {
                    mnu.state = .on
                }
                if let i = item["indent"] as? Int {
                    mnu.indentationLevel = i
                }
                if let i = item["tag"] as? Int {
                    mnu.tag = i
                } else {
                    mnu.tag = itemIndex
                }
                submenu.addItem(mnu)
                if let items = item["items"] as? [Any] {
                    let new_sub_menu = NSMenu()
                    _ = generateMenuFromGlobalScript(items, in: new_sub_menu, settings: settings, forItem: itemIndex)
                    if !new_sub_menu.items.isEmpty {
                        mnu.submenu = new_sub_menu
                    }
                }
                n += 1
            }
        }
        return n > 0
    }
    
    internal func processSpecialMenuItem(_ item: Settings.MenuItem, atIndex itemIndex: Int, inMenu destination_sub_menu: NSMenu, withSettings settings: Settings) -> Bool {
        if item.template == "-" {
            destination_sub_menu.addItem(NSMenuItem.separator())
            return true
        } else if item.template.hasPrefix("[[script-global:")  {
            guard let code = String(item.template.dropFirst(16).dropLast(2)).fromBase64(), !code.isEmpty else {
                return false
            }
        
            if !self.jsInitialized {
                self.resetJSContext(settings: settings)
            }
            
            guard let result = try? evaluateScript(code: code, forItem: itemIndex) else {
                return false
            }
            
            guard !result.isNull else {
                return false
            }
            
            if !result.isArray {
                self.jsDelegate?.onJSException(info: self, exception: NSLocalizedString("Global script token must return an array with the new menu items", comment: ""), atLine: -1, forItemAtIndex: itemIndex)
            }
            if let r = result.toArray() {
                return self.generateMenuFromGlobalScript(r, in: destination_sub_menu, settings: settings, forItem: itemIndex)
            } else if let r = result.toString(), !r.isEmpty {
                let mnu = self.createMenuItem(title: r, image: nil, settings: settings, tag: itemIndex)
                destination_sub_menu.addItem(mnu)
            } else {
                return false
            }
            return true
        } else if item.template.hasPrefix("[[open-with:") {
            guard let path = String(item.template.dropFirst(12).dropLast(2)).fromBase64(), !path.isEmpty else {
                return true
            }
                let title = String(format: NSLocalizedString("Open with %@…", tableName: "LocalizableExt", comment: ""),
                               FileManager.default.displayName(atPath: path))
            let mnu = self.createMenuItem(title: title, image: item.image, settings: settings, tag: itemIndex)
            if item.image.isEmpty {
                let img = NSWorkspace.shared.icon(forFile: path).resized(to: NSSize(width: 16, height: 16))
                mnu.image = img
            }
            mnu.toolTip = path
            destination_sub_menu.addItem(mnu)
            return true
        }  else {
            return false
        }
    }
    
    internal func formatMainTitleMenu(mainMenu menu: NSMenu, destination_sub_menu: NSMenu, isFirstFilled: Bool, settings: Settings) {
        if settings.isInfoOnSubMenu && settings.isInfoOnMainItem {
            if settings.useFirstItemAsMain && isFirstFilled {
                if let item = destination_sub_menu.items.first, !item.isSeparatorItem {
                    menu.items.first!.title = item.title
                    destination_sub_menu.items.remove(at: 0)
                }
            } else {
                let mainTitle = self.getStandardTitle(forSettings: settings)
                if !mainTitle.isEmpty {
                    menu.items.first!.title = mainTitle
                }
            }
        }
    }
    
    @objc internal func fakeMenuAction(_ sender: Any) {
        print(sender)
    }
    
    func formatND(useEmptyData: Bool) -> String {
        return useEmptyData ? NSLocalizedString("N/D", tableName: "LocalizableExt", comment: "") : ""
    }
    func formatERR(useEmptyData: Bool) -> String {
        return useEmptyData ? NSLocalizedString("ERR", tableName: "LocalizableExt", comment: "") : ""
    }
    
    func formatCount(_ n: Int, noneLabel: String, singleLabel: String, manyLabel: String, isFilled: inout Bool, useEmptyData: Bool, formatAsString: Bool = true) -> String {
        isFilled = n > 0
        if n == 0 {
            return useEmptyData ? NSLocalizedString(noneLabel, tableName: "LocalizableExt", comment: "") : ""
        } else if n == 1 {
            return NSLocalizedString(singleLabel, tableName: "LocalizableExt", comment: "")
        } else {
            if formatAsString {
                return String(format: NSLocalizedString(manyLabel, tableName: "LocalizableExt", comment: ""), BaseInfo.numberFormatter.string(from: NSNumber(integerLiteral: n)) ?? "\(n)")
            } else {
                return String(format: NSLocalizedString(manyLabel, tableName: "LocalizableExt", comment: ""), n)
            }
        }
    }
    func formatCount(_ n: Int, noneLabel: String, singleLabel: String, manyLabel: String, useEmptyData: Bool, formatAsString: Bool = true) -> String {
        var isFilled = false
        return formatCount(n, noneLabel: noneLabel, singleLabel: singleLabel, manyLabel: manyLabel, isFilled: &isFilled, useEmptyData: useEmptyData, formatAsString: formatAsString)
    }
}

