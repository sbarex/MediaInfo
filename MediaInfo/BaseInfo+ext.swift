//
//  BaseInfo+ext.swift
//  MediaInfoEx
//
//  Created by Sbarex on 12/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation
import AppKit

extension BaseInfo {
    static func replacePlaceholderFake(_ placeholder: String, settings: Settings, forItem item: MenuItemInfo?) -> String {
        let r: String
        if placeholder.hasPrefix("[[script-global:") {
            r = "<global script>"
        } else if placeholder.hasPrefix("[[script-inline:") {
            r = "<inline script>"
        } else if placeholder.hasPrefix("[[script-action:") {
            r = "<action script>"
        } else if placeholder.hasPrefix("[[open-with:") {
            guard let path = String(placeholder.dropFirst(12).dropLast(2)).fromBase64(), !path.isEmpty else {
                return "<open with>"
            }
            r = "<open with: \(path)>"
        } else if placeholder.hasPrefix("[[open-with-default]]") {
            r = "<open with default app>"
        } else if placeholder == "[[about]]" {
            r = "<about…>"
        } else if placeholder == "[[clipboard]]" {
            r = "<copy path to the clipboard…>"
        } else {
            r = "<" + placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "[]")) + ">"
        }
        
        return r
    }
    
    static func replacePlaceholdersFake(in template: String, settings: Settings, attributes: [NSAttributedString.Key: Any]? = nil, forItem item: MenuItemInfo) -> NSMutableAttributedString {
        let results = splitTokens(in: template)
        guard !results.isEmpty else {
            return NSMutableAttributedString(string: template)
        }
        
        let text = NSMutableAttributedString(string: template)
        
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r = replacePlaceholderFake(placeholder, settings: settings, forItem: item)
            
            guard r != placeholder else {
                continue
            }
            while text.mutableString.contains(placeholder) {
                let range = text.mutableString.range(of: placeholder)
                text.replaceCharacters(in: range, with: NSAttributedString(string: r, attributes: attributes))
            }
        }
        
        return text
    }
    
    func replacePlaceholdersFake(in template: String, settings: Settings, attributes: [NSAttributedString.Key: Any]? = nil, forItem item: MenuItemInfo) -> NSMutableAttributedString {
        let results = Self.splitTokens(in: template)
        guard !results.isEmpty else {
            return NSMutableAttributedString(string: template)
        }
        
        let text = NSMutableAttributedString(string: template)
        
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r: String
            if placeholder.hasPrefix("[[script-") {
                var isGlobal = false
                var isInline = false
                var isAction = false
                if placeholder.hasPrefix("[[script-global:") {
                    r = "<" + NSLocalizedString("Global script", comment: "") + ">"
                    isGlobal = true
                } else if placeholder.hasPrefix("[[script-action:") {
                    r = "<" + NSLocalizedString("Action script", comment: "") + ">"
                    isAction = true
                } else  {
                    r = "<" + NSLocalizedString("Inline script", comment: "") + ">"
                    isInline = true
                }
                if let code = String(placeholder.dropFirst(16).dropLast(2)).fromBase64(), !code.isEmpty {
                    // Evaluate the code to check execution error.
                    do {
                        if isAction {
                            self.initAction(context: self.getJSContext(with: settings), selectedItem: nil, settings: settings)
                        }
                        
                        if let result = try evaluateScript(code: code, forItem: item, settings: settings) {
                            if isGlobal && result.isArray {
                                var check: (([Any])->Void)! = nil
                                check = { result in
                                    for jsItem in result {
                                        guard let jsItem = jsItem as? [String: AnyHashable] else {
                                            continue
                                        }
                                        if let s = jsItem["action"] as? String, let action = MenuAction(rawValue: s) {
                                            let userInfo = jsItem["userInfo"] as? [String: AnyHashable] ?? [:]
                                            switch action {
                                            case .openWith:
                                                if (userInfo["application"] as? String ?? "").isEmpty {
                                                    self.jsExceptionDelegate?.onJSException(info: self, exception: NSLocalizedString("Missing application path. Define the userInfo.application value with the full path of the application to use to open the file.", comment: ""), atLine: -1, forItem: item)
                                                }
                                            case .custom:
                                                guard let code = userInfo["code"] as? String else {
                                                    self.jsExceptionDelegate?.onJSException(info: self, exception: NSLocalizedString("Missing action name. Define the userInfo.code value with the name of the function to call. ", comment: ""), atLine: -1, forItem: item)
                                                    break
                                                }
                                                let r = try? self.evaluateScript(code: "typeof globalThis['\(code)']", forItem: item, settings: settings)
                                                let typeof = r?.toString() ?? ""
                                                if typeof != "function" {
                                                    self.jsExceptionDelegate?.onJSException(info: self, exception: String(format: NSLocalizedString("The custom action will invoke the code `%@` but is not a global function name (%@). Define the userInfo.code value with the name of the function to call.", comment: ""), code, typeof), atLine: -1, forItem: item)
                                                }
                                            default: break
                                            }
                                        }
                                        if let items = jsItem["items"] as? [Any] {
                                            check(items)
                                        }
                                    }
                                }
                                check(result.toArray()!)
                            }
                                
                            if isGlobal && !result.isArray && !result.isNull && !result.isString {
                                self.jsExceptionDelegate?.onJSException(info: self, exception: NSLocalizedString("Global script token must return an array!", comment: ""), atLine: -1, forItem: item)
                            }
                            if isInline && !result.isString && !result.isNull {
                                self.jsExceptionDelegate?.onJSException(info: self, exception: NSLocalizedString("Inline script token must return a string value!", comment: ""), atLine: -1, forItem: item)
                            }
                        }
                    } catch {
                        
                    }
                }
            } else if placeholder.hasPrefix("[[open-with:") {
                guard let path = String(placeholder.dropFirst(12).dropLast(2)).fromBase64(), !path.isEmpty else {
                    return NSMutableAttributedString(string: NSLocalizedString("Open with…", comment: ""), attributes: attributes)
                }
                let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                r = NSLocalizedString(String(format: NSLocalizedString("Open with %@…", comment: ""), name), comment: "")
            } else if placeholder.hasPrefix("[[open-with-default]]") {
                if let me = self as? FileInfo, let url = NSWorkspace.shared.urlForApplication(toOpen: me.file) {
                    let name = URL(fileURLWithPath: url.path).deletingPathExtension().lastPathComponent
                    r = NSLocalizedString(String(format: NSLocalizedString("Open with %@…", comment: ""), name), comment: "")
                } else {
                    r = NSLocalizedString("Open…", comment: "")
                }
            } else if placeholder.hasPrefix("[[open-settings]]") {
                r = NSLocalizedString("MediaInfo Settings…", tableName: "LocalizableExt", comment: "")
            } else if placeholder.hasPrefix("[[about]]") {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
                r = String(format: NSLocalizedString("MediaInfo %@ (%@) developed by %@…", tableName: "LocalizableExt", comment: ""), version, build, "SBAREX")
            } else {
                r = Self.replacePlaceholderFake(placeholder, settings: settings, forItem: item)
            }
            guard r != placeholder else {
                continue
            }
            while text.mutableString.contains(placeholder) {
                let range = text.mutableString.range(of: placeholder)
                text.replaceCharacters(in: range, with: NSAttributedString(string: r, attributes: attributes))
            }
        }
        
        return text
    }
    
    @objc func getScriptInfo(token: TokenScript)-> String {
        return ""
    }
}

extension ImageInfo {
    @objc override func getScriptInfo(token: TokenScript) -> String {
        if !token.code.hasPrefix("/* no-metadata */") {
            return NSLocalizedString("If the script does not need the metadata it is recommended to insert the comment /* no-metadata */ as the first line to speed up the generation of the menu.", comment: "")
        } else {
            return super.getScriptInfo(token: token)
        }
    }
}


extension BaseOfficeInfo {
    @objc override func getScriptInfo(token: TokenScript) -> String {
        if !token.code.hasPrefix("/* no-deep-scan */") {
            return NSLocalizedString("If the script does not need the metadata it is recommended to insert the comment /* no-deep-scan */ as the first line to speed up the generation of the menu.", comment: "")
        } else {
            return super.getScriptInfo(token: token)
        }
    }
}
