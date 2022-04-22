//
//  BaseInfo.swift
//  MediaInfo
//
//  Created by Sbarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa
import os.log
import JavaScriptCore

struct JSExceptionInfo {
    let line: Int
    let message: String
}

extension NSNotification.Name {
    static let JSConsole = NSNotification.Name(rawValue: "JSConsole")
    static let JSException = NSNotification.Name(rawValue: "JSException")
}

extension CodingUserInfoKey {
    static let exportStoredValues = CodingUserInfoKey(rawValue: "exportStored")!
}

protocol JSExceptionDelegate: AnyObject {
    func onJSException(info: BaseInfo, exception: String?, atLine line: Int, forItem item: MenuItemInfo?)
}

protocol JSDelegate: SystemExecDelegate {
    func jsOpen(path: String, reply: @escaping (Bool)->Void)
    func jsOpen(path: String, with app: String, reply: @escaping (Bool, String?)->Void)
    func jsExec(command: String, arguments: [String], reply: @escaping (Int32, String)->Void)
    func jsRunApp(at path: String, reply: @escaping (Bool, String?)->Void)
    func jsCopyToClipboard(text: String) -> Bool
}

protocol SystemExecDelegate: AnyObject {
    func jsExecSync(command: String, arguments: [String]) -> (status: Int32, output: String)
}

protocol ActionDelegate: AnyObject {
    func handleMenuAction(info: BaseInfo, selectedMenu: NSMenuItem)
}

enum JSException: Error {
    case exception(desc: String, line: Int)
}

enum MenuAction: String, Codable {
    case standard
    case none
    case open
    case openWith
    case openSettings
    case about
    case custom
    case clipboard
    case reveal
}

struct MenuItemInfo: Hashable, Encodable {
    enum CodingKeys: String, CodingKey {
        case index
        case menuItem
        case fileType
        case userInfo
        case action
        case tag
    }
    
    static func == (lhs: MenuItemInfo, rhs: MenuItemInfo) -> Bool {
        return lhs.fileType == rhs.fileType && lhs.index == rhs.index && lhs.menuItem == rhs.menuItem && lhs.userInfo == rhs.userInfo && lhs.tag == rhs.tag
    }
    
    let index: Int
    let menuItem: Settings.MenuItem
    let fileType: Settings.SupportedFile
    var userInfo: [String: AnyHashable]
    var action: MenuAction
    var tag: Int
    
    init (fileType: Settings.SupportedFile, index: Int, item: Settings.MenuItem, action: MenuAction = .standard, tag: Int = 0, userInfo: [String: AnyHashable] = [:]) {
        self.fileType = fileType
        self.index = index
        self.menuItem = item
        self.userInfo = userInfo
        self.action = action
        self.tag = tag
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(fileType)
        hasher.combine(index)
        hasher.combine(menuItem)
        hasher.combine(userInfo)
        // hasher.combine(tag)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(menuItem, forKey: .menuItem)
        try container.encode(fileType, forKey: .fileType)
        
        var userInfo: [String: AnyCodable] = [:]
        for info in self.userInfo {
            userInfo[info.key] = AnyCodable(value: info.value)
        }
        try container.encode(userInfo, forKey: .userInfo)
        try container.encode(action, forKey: .action)
        try container.encode(tag, forKey: .tag)
    }
}

// MARK: - BaseInfo
class BaseInfo: Codable {
    struct ExtraName: Hashable, Codable {
        enum CodingKeys: String, CodingKey {
            case name
        }
        let name: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
        
        init(name: String) {
            self.name = name
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case extra
    }
    
    static let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.allowsFloats = true
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        
        return numberFormatter
    }()
    static let byteCountFormatter:ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB, .useBytes]
        formatter.countStyle = .file
        formatter.allowsNonnumericFormatting = true
        
        return formatter
    }()
    
    static func getImage(for mode: String) -> NSImage? {
        var img: NSImage?
        var isColor = false
        switch mode {
        case "image":
            img = NSImage(named: "image_h")
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
        case "video":
            img = NSImage(named: "video_h")
        case "audio":
            img = NSImage(named: "audio")
        case "text":
            img = NSImage(named: "txt")
        case "ratio", "aspectratio":
            img = NSImage(named: "aspectratio_h")
        case "ratio_h":
            img = NSImage(named: "aspectratio_h")
        case "ratio_v":
            img = NSImage(named: "aspectratio_v")
        case "size":
            img = NSImage(named: "size")
        case "page":
            img = NSImage(named: "page_h")
            
        case "mediabox_h", "mediabox":
            img = NSImage(named: "page_h")
        case "mediabox_v":
            img = NSImage(named: "page_v")
        case "bleed":
            img = NSImage(named: "bleed_v")
            
        case "pages":
            img = NSImage(named: "pages")
        case "tag":
            img = NSImage(named: "tag")
        case "pencil":
            img = NSImage(named: "pencil")
        case "gear", "gearshape":
            img = NSImage(named: "gearshape")
            
        case "office":
            img = NSImage(named: "doc")
        case "doc", "docx", "word":
            img = NSImage(named: "doc_v")
        case "docx_v", "word_v":
            img = NSImage(named: "doc_v")
        case "docx_h", "word_h":
            img = NSImage(named: "doc_h")
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
            
        case "pdf":
            img = NSImage(named: "pdf_v")
        
        case "info":
            img = NSImage(named: "info")
            
        default:
            if let i = NSImage(named: mode) {
                img = i
            } else {
                if #available(macOS 11.0, *) {
                    img = NSImage(systemSymbolName: mode, accessibilityDescription: nil)
                } else {
                    img = nil
                }
            }
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
    
    /// Update settings by enabling options based on menu item templates.
    class func updateSettings(_ settings: Settings, forItems items: [Settings.MenuItem]) {
        
    }
    
    var extra: [ExtraName: AnyHashable] = [:]
    
    var jsInitialized = false
    
    /// Callback uset to initialize the Javascript Context.
    lazy var initJS: ((Settings)->JSContext?) = { settings in
        return self.initJSContext(settings: settings)
    }
    
    fileprivate(set) var jsContext: JSContext? {
        didSet {
            jsInitialized = jsContext != nil
        }
    }
    
    weak var jsExceptionDelegate: JSExceptionDelegate?
    weak var jsDelegate: JSDelegate?
    
    weak var actionDelegate: ActionDelegate?
    
    /// In debug mode allow the Javascript log. Must be set before initialize the Javascript context.
    static var debugJS: Bool = false
    
    class var infoType: Settings.SupportedFile { return .none }
    
    var standardMainItem: MenuItemInfo {
        return MenuItemInfo(fileType: Self.infoType, index: -1, item: Settings.MenuItem(image: "", template: ""))
    }
    
    var currentSettings: Settings.FormatSettings?
    var globalSettings: Settings?
    
    // MARK: -
    init() { }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.extra = [:]
        let extra = try container.decode([String: AnyCodable].self, forKey: .extra)
        for info in extra {
            guard let v = info.value.value as? AnyHashable else {
                continue
            }
            self.extra[ExtraName(name: info.key)] = v
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var extra: [String: AnyCodable] = [:]
        for info in self.extra {
            extra[info.key.name] = AnyCodable(value: info.value)
        }
        try container.encode(extra, forKey: .extra)
    }
    
    // MARK: - Script support
    
    /// Get the Javascript context, initializing it if needed.
    func getJSContext(reset: Bool = false) -> JSContext? {
        if !jsInitialized || reset {
            guard let settings = self.globalSettings else {
                return nil
            }
            self.jsContext = self.initJS(settings)
        }
        return self.jsContext
    }
    
    /// Initialize the Javascript context for the specified settings.
    ///
    /// Exposed global vars:
    /// - `console`
    /// - `macOS_version`
    /// - `settings`
    ///
    /// Availbale functions:
    /// - `systemExecSync(String, [String])->{status: Int, output: String}`
    /// - `deepFreeze(Object)`
    /// - `toBase64(String)->String`
    /// - `fromBase64(String)->String`
    ///
    /// - parameters:
    ///    - settings:
    static func initJSContext(settings: Settings, jsDelegate: JSDelegate?) -> JSContext? {
        let time = CFAbsoluteTimeGetCurrent()
        os_log("Initializing JS Context…", log: OSLog.menuGeneration, type: .debug)
        defer {
            os_log("JS Context initialized in %{public}lf seconds.", log: OSLog.menuGeneration, type: .info, CFAbsoluteTimeGetCurrent() - time)
        }
        guard let context = JSContext() else {
            return nil
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.exportStoredValues] = true
        
        context.exceptionHandler = { context, exception in
            let line_num = exception?.objectForKeyedSubscript("line")?.toNumber().intValue ?? -1
            let message = exception?.toString() ?? ""
            os_log("JS Exception at line %{public}%d: %{public}@", log: OSLog.menuGeneration, type: .error, line_num, message)
        }
        
        let processInfo = ProcessInfo()
        context.evaluateScript("""
const macOS_version = "\(processInfo.operatingSystemVersion.majorVersion).\(processInfo.operatingSystemVersion.minorVersion).\(processInfo.operatingSystemVersion.patchVersion)";

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
""");
        let toBase64: @convention(block) (String) -> String  = { text in
            return text.toBase64()
        }
        context.setObject(toBase64, forKeyedSubscript: "toBase64" as NSString)
        let fromBase64: @convention(block) (String) -> String?  = { text in
            return text.fromBase64()
        }
        context.setObject(fromBase64, forKeyedSubscript: "fromBase64" as NSString)
        
        if Self.debugJS {
            let logFunction: @convention(block) ([AnyHashable]) -> Void  = { (object: [AnyHashable]) in
                let level = object.first as? String ?? "info"
                NotificationCenter.default.post(name: .JSConsole, object: (self, level, Array(object.dropFirst())))
            }
            context.setObject(logFunction, forKeyedSubscript: "__consoleLog" as NSString)
            
            let voidFunction: @convention(block) () -> Void  = { }
            context.setObject(voidFunction, forKeyedSubscript: "systemOpen" as NSString)
            context.setObject(voidFunction, forKeyedSubscript: "systemExec" as NSString)
            context.setObject(voidFunction, forKeyedSubscript: "systemOpenApp" as NSString)
            context.setObject(voidFunction, forKeyedSubscript: "systemOpenWith" as NSString)
            context.setObject(true, forKeyedSubscript: "debugMode" as NSString)
        } else {
            context.evaluateScript("function __consoleLog() { }")
            context.setObject(false, forKeyedSubscript: "debugMode" as NSString)
        }
        
        if let data = try? encoder.encode(settings), let s = String(data: data, encoding: .utf8) {
            context.setObject(s, forKeyedSubscript: "settingsJSONData" as NSString)
            context.evaluateScript("const settings = JSON.parse(settingsJSONData); delete settingsJSONData;")
            // context.evaluateScript("console.log(settings); ")
        } else {
            context.setObject(nil, forKeyedSubscript: "settings" as NSString)
        }
        context.evaluateScript("deepFreeze(settings);")
        
        let jsExecSync: @convention(block) (String, [String]) -> JSValue? = { command, arguments in
            guard let jsDelegate = jsDelegate else {
                return JSValue(nullIn: context)
            }
            let r = jsDelegate.jsExecSync(command: command, arguments: arguments)
            let jr = JSValue(newObjectIn: context)
            
            jr?.setObject(r.status, forKeyedSubscript: "status" as NSString)
            jr?.setObject(r.output, forKeyedSubscript: "output" as NSString)
            return jr
        }
        context.setObject(jsExecSync, forKeyedSubscript: "systemExecSync" as NSString)
        
        return context
    }
    
    /// Initialize the Javascript context for the specified settings.
    /// - parameters:
    ///    - settings:
    /// - SeeAlso:Sef.initJSContext(settings:, jsDelegate:)
    ///
    /// Exposed global vars:
    /// - `currentFileType` (Int)
    /// - `selectedMenuItem` (null)
    /// - `fileData`
    ///
    /// Available functions:
    /// - `formatTemplate(String)->{output: String, filled: Bool}`
    func initJSContext(settings: Settings) -> JSContext? {
        guard let context = Self.initJSContext(settings: settings, jsDelegate: self.jsDelegate) else {
            return nil
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.exportStoredValues] = true
        
        context.evaluateScript("""
const currentFileType = \(Self.infoType.rawValue);
let selectedMenuItem = null;
""");
        
        let formatTemplate: @convention(block) (String) -> JSValue? = { placeholder in
            var isFilled = false
            let s = self.processPlaceholder(placeholder, isFilled: &isFilled, forItem: nil)
            let jr = JSValue(newObjectIn: context)
            
            jr?.setObject(isFilled, forKeyedSubscript: "filled" as NSString)
            jr?.setObject(s, forKeyedSubscript: "output" as NSString)
            return jr
        }
        context.setObject(formatTemplate, forKeyedSubscript: "formatTemplate" as NSString)
        
        if let data = try? encoder.encode(self), let s = String(data: data, encoding: .utf8) {
            context.setObject(s , forKeyedSubscript: "fileJSONData" as NSString)
            context.evaluateScript("""
const fileData = JSON.parse(fileJSONData);
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
        
        return context
    }
    
    /// Initialize the context for the action trigger.
    ///
    /// Exposed global vars:
    /// - `selectedMenuItem` (Object)
    ///
    /// Available functions:
    /// - `systemOpen(String)->Promise`
    /// - `systemOpenWith(String, String)->Promise`
    /// - `systemExec(String, [String])->Promise`
    /// - `systemOpenApp(String)->Promise`
    /// - `systemCopyToClipboard(String)->Bool`
    func initAction(context: JSContext?, selectedItem item: MenuItemInfo?) {
        guard let context = context else {
            return
        }

        let jsOpen: @convention(block) (String) -> JSValue? = { path in
            guard let jsDelegate = self.jsDelegate else {
                return JSValue(newPromiseRejectedWithReason: [], in: context)
            }
            let result = JSValue(newPromiseIn: context) { resolve, reject in
                jsDelegate.jsOpen(path: path) { success in
                    if success {
                        resolve?.call(withArguments: [])
                    } else {
                        reject?.call(withArguments: [])
                    }
                }
            }
            return result
        }
        context.setObject(jsOpen, forKeyedSubscript: "systemOpen" as NSString)
        
        let jsOpenWith: @convention(block) (String, String) -> JSValue? = { path, app in
           guard let jsDelegate = self.jsDelegate else {
                return JSValue(newPromiseRejectedWithReason: [], in: context)
            }
            let result = JSValue(newPromiseIn: context) { resolve, reject in
                jsDelegate.jsOpen(path: path, with: app) { success, error_msg in
                    if success {
                        resolve?.call(withArguments: [])
                    } else {
                        reject?.call(withArguments: error_msg != nil ? [error_msg!] : [])
                    }
                }
            }
            return result
        }
        context.setObject(jsOpenWith, forKeyedSubscript: "systemOpenWith" as NSString)
        
        let jsExec: @convention(block) (String, [String]) -> JSValue? = { command, arguments in
            guard let jsDelegate = self.jsDelegate else {
                return JSValue(newPromiseRejectedWithReason: "No delegate available", in: context)
            }

            let result = JSValue(newPromiseIn: context) { resolve, reject in
                jsDelegate.jsExec(command: command, arguments: arguments) { status, output in
                    if status != 0 {
                        reject?.call(withArguments: [output])
                    } else {
                        resolve?.call(withArguments: [[status, output]])
                    }
                }
            }
            return result
        }
        context.setObject(jsExec, forKeyedSubscript: "systemExec" as NSString)
        
        let jsOpenApp: @convention(block) (String) -> JSValue? = { path in
            guard let jsDelegate = self.jsDelegate else {
                return JSValue(newPromiseRejectedWithReason: [], in: context)
            }
            let result = JSValue(newPromiseIn: context) { resolve, reject in
                jsDelegate.jsRunApp(at: path) { success, error_msg in
                    if success {
                        resolve?.call(withArguments: [])
                    } else {
                        reject?.call(withArguments: error_msg != nil ? [error_msg!] : [])
                    }
                }
            }
            return result
        }
        context.setObject(jsOpenApp, forKeyedSubscript: "systemOpenApp" as NSString)
        
        let jsCopyToClipboard: @convention(block) (String) -> JSValue? = { text in
            let r = self.jsDelegate?.jsCopyToClipboard(text: text) ?? false
            
            return JSValue(bool: r, in: context)
        }
        context.setObject(jsCopyToClipboard, forKeyedSubscript: "systemCopyToClipboard" as NSString)
        
        let encoder = JSONEncoder()
        encoder.userInfo[.exportStoredValues] = true
        
        let s: String
        if let data = try? encoder.encode(item), let t = String(data: data, encoding: .utf8), let d = try? JSONSerialization.data(withJSONObject: t, options: [.fragmentsAllowed]), let t2 = String(data: d, encoding: .utf8) {
            s = t2
        } else {
            s = "null"
        }
        
        context.evaluateScript("selectedMenuItem = JSON.parse(\(s)); Object.freeze(selectedMenuItem);")
    }
    
    /// Evaluate a Javascript.
    /// - parameters:
    ///   - code: Code to execute.
    ///   - item: Menu item that execute the code.
    ///   - extendExceptionHandler:
    ///   - settings
    ///
    /// Exposed global vars:
    /// - `templateItemIndex` (Int)
    /// - `currentItem` (Object)
    func evaluateScript(code: String, forItem item: MenuItemInfo?) throws -> JSValue? {
        guard let context = self.getJSContext() else {
            return nil
        }
        var js_exception: JSException?
        let old_exceptionHandler = context.exceptionHandler
        context.exceptionHandler = { context, exception in
            let line_num = exception?.objectForKeyedSubscript("line")?.toNumber().intValue ?? -1
            let message = exception?.toString()
            js_exception = JSException.exception(desc: message ?? "", line: line_num)
            self.jsExceptionDelegate?.onJSException(info: self, exception: message, atLine: line_num, forItem: item)
            old_exceptionHandler?(context, exception)
        }
        defer {
            context.exceptionHandler = old_exceptionHandler
        }
        context.setObject(item?.index ?? -1, forKeyedSubscript: "templateItemIndex" as NSString)
        let json = JSONEncoder()
        if let d = try? json.encode(item), let s = String(data: d, encoding: .utf8) {
            context.setObject(s, forKeyedSubscript: "_currentItem" as NSString)
            context.evaluateScript("currentItem=JSON.parse(_currentItem); delete(_currentItem);")
        } else {
            context.setObject(nil, forKeyedSubscript: "currentItem" as NSString)
        }
        let result = context.evaluateScript(code)
        
        if let js_exception = js_exception {
            throw js_exception
        }
        
        return result
    }
    
    enum JSTriggerError: Error {
        case exception(info: JSExceptionInfo)
        case jsInitError
        case invalidResult
    }
    
    /// Evaluate a Javascript of the validate trigger.
    /// - parameters:
    ///   - url: Url of the processed file.
    ///   - settings
    ///   - jsDelegate
    ///
    /// Exposed global vars:
    /// - `currentFile` (String)
    static func evaluateTriggerValidate(_ trigger: Settings.Trigger?, for url: URL, globalSettings settings: Settings, jsDelegate: JSDelegate?) throws -> Bool {
        guard let trigger = trigger, trigger.isActive else {
            return true
        }
        let code = trigger.code
        guard let context = Self.initJSContext(settings: settings, jsDelegate: jsDelegate) else {
            throw JSTriggerError.jsInitError
        }
        var exception_info: JSExceptionInfo? = nil
        context.exceptionHandler = { context, exception in
            exception_info = JSExceptionInfo(
                line: exception?.objectForKeyedSubscript("line")?.toNumber().intValue ?? -1,
                message: exception?.toString() ?? "JS Exception"
            )
            // FIXME: Self.Type
            NotificationCenter.default.post(name: .JSException, object: (Self.self, exception_info!.message, exception_info?.line, -1))
            os_log("JS Exception in the validation trigger (%{public}d): %{public}@", log: OSLog.menuGeneration, type: .error, exception_info!.line, exception_info!.message)
        }
        let u = String(data: try! JSONSerialization.data(withJSONObject: url.path, options: [.fragmentsAllowed]), encoding: .utf8)!
        os_log("Execute validation trigger for file %{private}@", log: OSLog.menuGeneration, type: .debug, url.path)
        
        let r = context.evaluateScript("(function(currentFile) { \(code) \n})(\(u))")
        if let exception_info = exception_info {
            throw JSTriggerError.exception(info: exception_info)
        }
        guard let r = r, r.isBoolean else {
            throw JSTriggerError.invalidResult
        }
        let result = r.toBool()
        if !result {
            os_log("Validation trigger require to skip the file.", log: OSLog.menuGeneration, type: .info)
        }
        
        return result
    }
    
    /// Evaluate a Javascript of the action trigger.
    /// - parameters:
    ///   - settings
    ///   - selectedItem
    ///
    /// Exposed global vars:
    /// - `currentFile` (String)
    ///
    /// - SeeAlso: self.initAction
    func evaluateTriggerAction(selectedItem: MenuItemInfo?) throws {
        guard let currentSettings = self.currentSettings, let trigger = currentSettings.triggers[.action] else {
            return
        }
        let code = trigger.code
        
        guard let context = self.getJSContext() else {
            throw JSTriggerError.jsInitError
        }
        self.initAction(context: context, selectedItem: selectedItem)
                
        var exception_info: JSExceptionInfo? = nil
        let old_handler = context.exceptionHandler
        defer {
            context.exceptionHandler = old_handler
        }
        context.exceptionHandler = { context, exception in
            exception_info = JSExceptionInfo(
                line: exception?.objectForKeyedSubscript("line")?.toNumber().intValue ?? -1,
                message: exception?.toString() ?? "JS Exception"
            )
            NotificationCenter.default.post(name: .JSException, object: (self, exception_info!.message, exception_info?.line, -1))
            os_log("JS Exception in the action trigger (%{public}d): %{public}@", log: OSLog.menuGeneration, type: .error, exception_info!.line, exception_info!.message)
        }
        os_log("Executing the action trigger…", log: OSLog.menuGeneration, type: .debug)
        let _ = context.evaluateScript("(function() { \(code) \n})()")
        if let exception_info = exception_info {
            throw JSTriggerError.exception(info: exception_info)
        }
    }
    
    /// Evaluate a Javascript of the before render trigger.
    /// - parameters:
    ///   - settings
    ///
    /// Exposed global vars:
    /// - `currentMenuItems` ([Object])
    ///
    /// - SeeAlso: self.initAction
    func evaluateTriggerBeforeRender() throws -> [Settings.MenuItem]? {
        guard let currentSettings = self.currentSettings, let trigger = currentSettings.triggers[.beforeRender], trigger.isActive else {
            return nil
        }
        let code = trigger.code
        
        guard let context = self.getJSContext() else {
            throw JSTriggerError.jsInitError
        }
        
        let encoder = JSONEncoder()
        encoder.userInfo[.exportStoredValues] = true
        if let data = try? encoder.encode(currentSettings.templates), let s = String(data: data, encoding: .utf8) {
            context.setObject(s, forKeyedSubscript: "currentMenuItemsJSONData" as NSString)
            context.evaluateScript("let currentMenuItems = JSON.parse(currentMenuItemsJSONData); delete currentMenuItemsJSONData;")
        } else {
            context.evaluateScript("let currentMenuItems = null;")
        }
                
        var exception_info: JSExceptionInfo? = nil
        let old_handler = context.exceptionHandler
        defer {
            context.exceptionHandler = old_handler
        }
        context.exceptionHandler = { context, exception in
            exception_info = JSExceptionInfo(
                line: exception?.objectForKeyedSubscript("line")?.toNumber().intValue ?? -1,
                message: exception?.toString() ?? "JS Exception"
            )
            NotificationCenter.default.post(name: .JSException, object: (self, exception_info!.message, exception_info?.line, -1))
            os_log("JS Exception in the before render trigger (%{public}d): %{public}@", log: OSLog.menuGeneration, type: .error, exception_info!.line, exception_info!.message)
        }
        os_log("Executing the before render trigger…", log: OSLog.menuGeneration, type: .debug)
        let r: JSValue! = context.evaluateScript("(function() { \(code) \n})()")
        if let exception_info = exception_info {
            throw JSTriggerError.exception(info: exception_info)
        }
        if r == nil {
            return nil
        }
        guard !r.isNull else {
            return nil
        }
        guard r.isArray, let raw_items = r.toArray() as? [[String: String]] else {
            throw JSTriggerError.invalidResult
        }
        var items: [Settings.MenuItem] = []
        for dict in raw_items {
            guard let item = Settings.MenuItem(from: dict) else {
                throw JSTriggerError.invalidResult
            }
            items.append(item)
        }
        
        return items
    }
    
    // MARK: - Placeholder support.
    
    /// Replace a placeholder with the current data.
    /// - parameters:
    ///   - placeholder: Placeholder to replace
    ///   - settings
    ///   - isFilled: Set to true when the placeholder is filled with not empty data.
    ///   - item: Current menu item.
    internal func processPlaceholder(_ placeholder: String, isFilled: inout Bool, forItem item: MenuItemInfo?) -> String {
        isFilled = false
        if placeholder.hasPrefix("[[script-inline:") {
            let code: String
            if placeholder.hasPrefix("[[script-inline:js:") {
                let function_name = String(placeholder.dropFirst(19).dropLast(2))
                if function_name.isEmpty {
                    code = ""
                } else {
                    code = "globalThis['\(function_name)']()";
                }
            } else {
                guard let c = String(placeholder.dropFirst(16).dropLast(2)).fromBase64() else {
                    isFilled = false
                    return ""
                }
                code = c
            }
            
            guard !code.isEmpty else {
                isFilled = false
                return ""
            }
            
            guard let result = try? evaluateScript(code: code, forItem: item) else {
                isFilled = false
                return ""
            }
            guard !result.isNull else {
                isFilled = false
                return ""
            }
            if !result.isString {
                self.jsExceptionDelegate?.onJSException(info: self, exception: NSLocalizedString("Inline script token must return a string value!", comment: ""), atLine: -1, forItem: item)
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
    
    /// Sanitize a text. Remove empty brackets, trim white spaces
    /// - parameters:
    ///   - text: Text to process
    ///   - allowCapitalize: Allow to capitalize the first letter.
    func purgeString(_ text: String, allowCapitalize: Bool = true) -> String {
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
        if allowCapitalize {
            // Capitalize first letter.
            text = text.capitalizingFirstLetter()
        }
        
        return text
    }
    
    func purgeAttributedString(_ text: NSMutableAttributedString, allowCapitalize: Bool) {
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
        if allowCapitalize, text.length > 0 {
            // Capitalize first letter.
            let s = text.attributedSubstring(from: NSRange(location: 0, length: 1)).string
            text.replaceCharacters(in: NSRange(location: 0, length: 1), with: s.uppercased())
        }
    }
    
    /// Check if a placeholder allow to be capitalized if at the begin of the item title.
    func placeholderAllowCapitalize(_ placeholder: String) -> Bool {
        return true
    }
    
    /// Translate the placeholders inside the template.
    /// - parameters:
    ///   - template: Template with the placeholders to replace.
    ///   - values: Values that override the standard value.
    ///   - isFilled: Set to `true` when at least one placeholder is replaced.
    ///   - item: Current processed menu item.
    func replacePlaceholders(in template: String, isFilled: inout Bool, forItem item: MenuItemInfo) -> String {
        let results = Self.splitTokens(in: template)
        
        var text = template
       
        isFilled = false
        var allowCapitalize = true
        var isPlaceholderFilled = false
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            if result.range.location == 0 {
                allowCapitalize = placeholderAllowCapitalize(placeholder)
            }
            let r = processPlaceholder(placeholder, isFilled: &isPlaceholderFilled, forItem: item)
            if isPlaceholderFilled {
                isFilled = true
            }
            text = text.replacingOccurrences(of: placeholder, with: r)
        }
        if results.isEmpty && !template.isEmpty {
            isFilled = true
        }
        
        text = purgeString(text, allowCapitalize: allowCapitalize)
        
        return text
    }
    
    /// Translate the placeholders inside the template.
    /// - parameters:
    ///   - template: Template with the placeholders to replace.
    ///   - attributes: Attributes used to format the value of placeholders.
    ///   - values: Values that override the standard value.
    ///   - isFilled: Set to `true` when at least one placeholder is replaced.
    ///   - item: Current menu item.
    func replacePlaceholders(in template: String, attributes: [NSAttributedString.Key: Any]? = nil, isFilled: inout Bool, forItem item: MenuItemInfo) -> NSMutableAttributedString {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[([^]]+)\]\]"#) else {
            return NSMutableAttributedString(string: template)
        }
        let results = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        
        let text = NSMutableAttributedString(string: template)
        
        isFilled = false
        var isPlaceholderFilled = false
        var allowCapitalize = true
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            if result.range.location == 0 {
                allowCapitalize = placeholderAllowCapitalize(placeholder)
            }
            let r = processPlaceholder(placeholder, isFilled: &isPlaceholderFilled, forItem: item)
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
        
        self.purgeAttributedString(text, allowCapitalize: allowCapitalize)
        return text
    }
    
    /// Split the placeholders inside the template.
    static func splitTokens(in template: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[([^]]+)\]\]"#) else {
            return []
        }
        let results = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        return results
    }
    
    /// Get the standard title.
    func getStandardTitle() -> String {
        var isFilled = false
        let item = standardMainItem
        let title: String = self.replacePlaceholders(in: item.menuItem.template, isFilled: &isFilled, forItem: item)
        return isFilled ? title : ""
    }
    
    internal func getImage(for name: String) -> NSImage? {
        return Self.getImage(for: name)
    }
    
    internal func createMenuItem(title: String, image: String?, representedObject item: MenuItemInfo) -> NSMenuItem {
        let mnu = NSMenuItem(title: title, action: #selector(self.fakeMenuAction(_:)), keyEquivalent: "")
        mnu.isEnabled = true
        mnu.target = self
        if !(self.globalSettings?.isIconHidden ?? false) {
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
        mnu.representedObject = item
        mnu.tag = item.index
        return mnu
    }
    
    func initSettings(withItemSettings itemSettings: Settings.FormatSettings? = nil, globalSettings settings: Settings) {
        self.currentSettings = itemSettings ?? settings.getFormatSettings(for: Self.infoType)
        self.globalSettings = settings
    }
    
    func getMenu(withItemSettings itemSettings: Settings.FormatSettings? = nil, globalSettings settings: Settings) -> NSMenu? {
        self.initSettings(withItemSettings: itemSettings, globalSettings: settings)
        guard let _ = self.currentSettings else {
            return nil
        }
        
        return self.generateMenu(image: self.getImage(for: standardMainItem.menuItem.image))
    }
    
    /// Change the tag of every menu items with an hash and return an array of hases and representedObject of the items.
    ///
    static func preprocessMenu(_ menu: NSMenu?) -> [Int: Any] {
        guard let menu = menu else {
            return [:]
        }
        var representedObjects: [Int: Any] = [:]
        
        for item in menu.items {
            if item.representedObject != nil {
                var hasher = Hasher()
                hasher.combine(item.tag)
                hasher.combine(item.title)
                hasher.combine(item.hasSubmenu)
                
                let key = hasher.finalize()
                if var info = item.representedObject as? MenuItemInfo {
                    info.tag = item.tag
                    item.representedObject = info
                    item.tag = key
                }
                representedObjects[key] = item.representedObject
            }
            if item.hasSubmenu {
                let r = preprocessMenu(item.submenu)
                for item in r {
                    representedObjects[item.key] = item.value
                }
            }
        }
        return representedObjects
    }
    
    /// Get the representedObject of menu item.
    /// - seeAlso: preprocessMenu(_:)
    static func postprocessMenuItem(_ item: NSMenuItem, from data: [Int: Any]) -> Any? {
        if item.tag != 0, let d = data[item.tag] {
            return d
        }
        
        var hasher = Hasher()
        hasher.combine(item.tag)
        hasher.combine(item.title)
        hasher.combine(item.hasSubmenu)
        
        let key = hasher.finalize()
        return data[key]
    }
    
    internal func generateMenu(image: NSImage?) -> NSMenu? {
        self.jsContext = nil // Force JSContext reset.
        
        var items = self.currentSettings?.templates ?? []
        
        if let trigger = self.currentSettings?.triggers[.beforeRender], trigger.isActive {
            // Customize the menu items with the trigger.
            if let new_items = try? self.evaluateTriggerBeforeRender() {
                items = new_items
            }
        }
        
        guard !items.isEmpty else {
            // No menu items.
            return nil
        }
        
        let menu = NSMenu(title: "")
        menu.autoenablesItems = false
        
        let use_submenu = self.globalSettings?.isInfoOnSubMenu ?? true
        
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
        
        for (i, item) in items.enumerated() {
            defer {
                isFirst = false
            }
            let info = MenuItemInfo(fileType: Self.infoType, index: i, item: item)
            if self.processSpecialMenuItem(info, inMenu: destination_sub_menu) {
                continue
            }
            
            var isFilled = false
            let s = self.replacePlaceholders(in: item.template, isFilled: &isFilled, forItem: info)
            if s.isEmpty || ((self.globalSettings?.isEmptyItemsSkipped ?? true) && !isFilled) {
                continue
            }
            if isFirst {
                isFirstFilled = true
            }
            let mnu = self.createMenuItem(title: s, image: item.image, representedObject: info)
            destination_sub_menu.addItem(mnu)
        }
        
        self.formatMainTitleMenu(mainMenu: menu, destination_sub_menu: destination_sub_menu, isFirstFilled: isFirstFilled)
        
        return menu
    }
    
    /// Generate the menu items from the output of a Javascript.
    internal func generateMenuFromScript(_ result: [Any], in submenu: NSMenu, forItem itemInfo: MenuItemInfo) -> Bool {
        guard !result.isEmpty else {
            return false
        }
        var n = 0
        for item in result {
            if let title = item as? String {
                if title == "-" {
                    submenu.addItem(NSMenuItem.separator())
                } else {
                    let mnu = self.createMenuItem(title: title, image: n == 0 ? itemInfo.menuItem.image : nil, representedObject: itemInfo)
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
                var image = item["image"] as? String
                if image == nil && n == 0 {
                    image = itemInfo.menuItem.image
                }
                var jsInfo = itemInfo
                let mnu = self.createMenuItem(title: title, image: image, representedObject: jsInfo)
                if let userInfo = item["userInfo"] as? [String: AnyHashable] {
                    for i in userInfo {
                        jsInfo.userInfo[i.key] = i.value
                    }
                }
                if let s = item["action"] as? String, let action = MenuAction(rawValue: s) {
                    jsInfo.action = action
                }
                mnu.representedObject = jsInfo
                if let b = item["checked"] as? Bool, b {
                    mnu.state = .on
                }
                if let i = item["indent"] as? Int {
                    mnu.indentationLevel = i
                }
                if let i = item["tag"] as? Int {
                    mnu.tag = i
                }
                if let s = item["tooltip"] as? String {
                    mnu.toolTip = s // Tooltip is not available from the Finder extension.
                }
                submenu.addItem(mnu)
                if let items = item["items"] as? [Any] {
                    let new_sub_menu = NSMenu()
                    _ = generateMenuFromScript(items, in: new_sub_menu, forItem: itemInfo)
                    if !new_sub_menu.items.isEmpty {
                        mnu.submenu = new_sub_menu
                    }
                }
                n += 1
            }
        }
        return n > 0
    }
    
    /// Process a menu items.
    /// - returns `true` If the menu item is processed, `false` to analize the placeholders in the template.
    internal func processSpecialMenuItem(_ item: MenuItemInfo, inMenu destination_sub_menu: NSMenu) -> Bool {
        if item.menuItem.template == "-" {
            // Generate a menu separator.
            let mnu = NSMenuItem.separator()
            mnu.tag = item.index
            mnu.representedObject = item
            destination_sub_menu.addItem(mnu)
            return true
        } else if item.menuItem.template == "[[open-settings]]" {
            let mnu = self.createMenuItem(title: NSLocalizedString("MediaInfo Settings…", tableName: "LocalizableExt", comment: ""), image: item.menuItem.image, representedObject: item)
            if let info = mnu.representedObject as? MenuItemInfo {
                var info2 = info
                info2.action = .openSettings
                mnu.representedObject = info2
            }
            destination_sub_menu.addItem(mnu)
            return true
        } else if item.menuItem.template == "[[about]]" {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
            let r = String(format: NSLocalizedString("MediaInfo %@ (%@) developed by %@…", tableName: "LocalizableExt", comment: ""), version, build, "SBAREX")
            let mnu = self.createMenuItem(title: r, image: item.menuItem.image, representedObject: item)
            if let info = mnu.representedObject as? MenuItemInfo {
                var info2 = info
                info2.action = .about
                mnu.representedObject = info2
            }
            destination_sub_menu.addItem(mnu)
            return true
        } else if item.menuItem.template.hasPrefix("[[script-global:")  {
            let code: String
            if item.menuItem.template.hasPrefix("[[script-global:js:") {
                let c = String(item.menuItem.template.dropFirst(19).dropLast(2))
                code = c + (c.isEmpty ? "" : "()")
            } else {
                guard let c = String(item.menuItem.template.dropFirst(16).dropLast(2)).fromBase64() else {
                    return false
                }
                code = c
            }
            guard !code.isEmpty else {
                return false
            }
            
            guard let result = try? evaluateScript(code: code, forItem: item) else {
                return false
            }
            
            guard !result.isNull else {
                return false
            }
            
            if !result.isArray {
                self.jsExceptionDelegate?.onJSException(info: self, exception: NSLocalizedString("Global script token must return an array with the new menu items", comment: ""), atLine: -1, forItem: item)
            }
            if let r = result.toArray() {
                return self.generateMenuFromScript(r, in: destination_sub_menu, forItem: item)
            } else if let r = result.toString(), !r.isEmpty {
                let mnu = self.createMenuItem(title: r, image: nil, representedObject: item)
                destination_sub_menu.addItem(mnu)
            } else {
                return false
            }
            return true
        } else {
            return false
        }
    }
    
    internal func formatMainTitleMenu(mainMenu menu: NSMenu, destination_sub_menu: NSMenu, isFirstFilled: Bool) {
        guard (globalSettings?.isInfoOnSubMenu ?? true) && (globalSettings?.isInfoOnMainItem ?? false) else {
            return
        }
        if (globalSettings?.useFirstItemAsMain ?? true) && isFirstFilled {
            if let item = destination_sub_menu.items.first, !item.isSeparatorItem {
                menu.items.first!.title = item.title
                if item.image != nil {
                    menu.items.first!.image = item.image
                }
                destination_sub_menu.items.remove(at: 0)
            }
        } else {
            let mainTitle = self.getStandardTitle()
            if !mainTitle.isEmpty {
                menu.items.first!.title = mainTitle
            }
        }
    }
    
    @objc internal func fakeMenuAction(_ sender: NSMenuItem) {
        print(sender)
        self.actionDelegate?.handleMenuAction(info: self, selectedMenu: sender)
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

