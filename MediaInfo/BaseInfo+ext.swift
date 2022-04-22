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
            r = "<"+NSLocalizedString("Global script", comment: "")+">"
        } else if placeholder.hasPrefix("[[script-inline:") {
            r = "<"+NSLocalizedString("Inline script", comment: "")+">"
        } else if placeholder.hasPrefix("[[open-with:") {
            guard let path = String(placeholder.dropFirst(12).dropLast(2)).fromBase64(), !path.isEmpty else {
                return NSLocalizedString("Open with…", comment: "")
            }
            r = String(format: NSLocalizedString("Open with %@…", comment: ""), path)
        } else if placeholder == "[[open-with-default]]" || placeholder == "[[open]]" {
            r = NSLocalizedString("Open with the default app", comment: "")
        } else if placeholder == "[[about]]" {
            r = NSLocalizedString("About…", comment: "")
        } else if placeholder == "[[clipboard]]" {
            r = NSLocalizedString("Copy path to the clipboard", tableName: "LocalizableExt", comment: "")
        } else if placeholder == "[[uti]]" {
            r = NSLocalizedString("Uniform Type Identifier", comment: "")
        } else if placeholder == "[[uti-conforms]]" {
            r = "<"+NSLocalizedString("Uniform Type Identifier conformances", comment: "")+">"
        } else if placeholder == "[[files]]" {
            r = "<"+NSLocalizedString("Files submenu", comment: "")+">"
        } else if placeholder == "[[files-with-icon]]" {
            r = "<"+NSLocalizedString("Files submenu (with icons)", comment: "")+">"
        } else if placeholder == "[[files-plain]]" {
            r = "<"+NSLocalizedString("Plain files submenu", comment: "")+">"
        } else if placeholder == "[[files-plain-with-icon]]" {
            r = "<"+NSLocalizedString("Plain files submenu (with icons)", comment: "")+">"
        } else if placeholder == "[[ext-attributes]]" {
            r = "<"+NSLocalizedString("Extended Attributes", tableName: "LocalizableExt", comment: "")+">"
        } else if placeholder == "[[file-modes:acl]]" {
            r = "- rw- r-- r-- <\(NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: ""))>"
        } else if placeholder == "[[file-modes:ext-attrs]]" {
            r = "- rw- r-- r-- <\(NSLocalizedString("Extended Attributes", tableName: "LocalizableExt", comment: ""))>"
        } else if placeholder == "[[file-modes:acl:ext-attrs]]" {
            r = "- rw- r-- r-- <\(NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: ""))> & <\(NSLocalizedString("Extended Attributes", tableName: "LocalizableExt", comment: ""))>"
        } else if placeholder == "[[acl]]" {
            r = "<- rw- r-- r-->"
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
                if placeholder.hasPrefix("[[script-global:") {
                    r = "<" + NSLocalizedString("Global script", comment: "") + ">"
                    isGlobal = true
                } else  {
                    r = "<" + NSLocalizedString("Inline script", comment: "") + ">"
                    isInline = true
                }
                if let code = String(placeholder.dropFirst(16).dropLast(2)).fromBase64(), !code.isEmpty {
                    // Evaluate the code to check execution error.
                    do {
                        if let result = try evaluateScript(code: code, forItem: item) {
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
                                                let r = try? self.evaluateScript(code: "typeof globalThis['\(code)']", forItem: item)
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
                r = String(format: NSLocalizedString("Open with %@…", comment: ""), name)
            } else if placeholder == "[[open-with-default]]" || placeholder == "[[open]]" {
                if let me = self as? FileInfo, let url = NSWorkspace.shared.urlForApplication(toOpen: me.file) {
                    let name = URL(fileURLWithPath: url.path).deletingPathExtension().lastPathComponent
                    r = String(format: NSLocalizedString("Open with %@…", comment: ""), name)
                } else {
                    r = NSLocalizedString("Open…", comment: "")
                }
            } else if placeholder == "[[open-settings]]" {
                r = NSLocalizedString("MediaInfo Settings…", tableName: "LocalizableExt", comment: "")
            } else if placeholder == "[[about]]" {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
                r = String(format: NSLocalizedString("MediaInfo %@ (%@) developed by %@…", tableName: "LocalizableExt", comment: ""), version, build, "SBAREX")
            } else if placeholder.hasPrefix("[[acl]]"), let me = self as? FileInfo {
                r = "<\(me.getFormattedMode(withExtra: true, withACL: false))>"
            } else if placeholder == "[[file-modes:acl]]", let me = self as? FileInfo {
                r = "\(me.getFormattedMode(withExtra: true, withACL: false)) <\(NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: ""))>"
            } else if placeholder == "[[file-modes:ext-attrs]]", let me = self as? FileInfo {
                r = "\(me.getFormattedMode(withExtra: false, withACL: true)) <\(NSLocalizedString("Extended Attributes", tableName: "LocalizableExt", comment: ""))>"
            } else if placeholder == "[[file-modes:acl:ext-attrs]]", let me = self as? FileInfo {
                r = "\(me.getFormattedMode(withExtra: false, withACL: false)) <\(NSLocalizedString("Access Control List", tableName: "LocalizableExt", comment: ""))> & <\(NSLocalizedString("Extended Attributes", tableName: "LocalizableExt", comment: ""))>"
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
        return NSLocalizedString("If the script needs to access the metadata you need to insert the comment /* require-metadata */ as the first line. This can slow down menu generation.", comment: "")
    }
}


extension BaseOfficeInfo {
    @objc override func getScriptInfo(token: TokenScript) -> String {
        return NSLocalizedString("If the script needs to access the metadata you need to insert the comment /* require-deep-scan */ as the first line. This can slow down menu generation.", comment: "")
    }
}


extension FolderInfo {
    @objc override func getScriptInfo(token: TokenScript) -> String {
        return NSLocalizedString("If the script needs to access to the full size with metadata you need to insert the comment /* require-full-scan */ as the first line. This can slow down menu generation. If the script only need to access to the total number of files or to the total file size (without medatata), you need to insert the comment /* require-fast-scan */ as the first line. ", comment: "")
    }
}

class FakeFileInfo: FileInfo {
    init(file: URL, fileSize: Int64, fileSizeFull: Int64, fileCreationDate: Date?, fileModificationDate: Date?, fileAccessDate: Date?, uti: String, utiConformsToType: [String]) {
        super.init(file: file)
        
        self.file = file
        self.fileSize = fileSize
        self.fileSizeFull = fileSizeFull
        self.fileCreationDate = fileCreationDate
        self.fileModificationDate = fileModificationDate
        self.fileAccessDate = fileAccessDate
        self.uti = uti
        self.utiConformsToType = utiConformsToType
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
