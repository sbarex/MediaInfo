//
//  BaseInfo+ext.swift
//  MediaInfoEx
//
//  Created by Sbarex on 12/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import Foundation

extension BaseInfo {
    static func replacePlaceholderFake(_ placeholder: String, settings: Settings, forItem itemIndex: Int) -> String {
        let r: String
        if placeholder.hasPrefix("[[script-global:") || placeholder.hasPrefix("[[script-inline:") {
            if placeholder.hasPrefix("[[script-global:") {
                r = "<global script>"
            } else {
                r = "<inline script>"
            }
        } else {
            r = "<" + placeholder.trimmingCharacters(in: CharacterSet(charactersIn: "[]")) + ">"
        }
        
        return r
    }
    
    static func replacePlaceholdersFake(in template: String, settings: Settings, attributes: [NSAttributedString.Key: Any]? = nil, forItem itemIndex: Int) -> NSMutableAttributedString {
        let results = splitTokens(in: template)
        guard !results.isEmpty else {
            return NSMutableAttributedString(string: template)
        }
        
        let text = NSMutableAttributedString(string: template)
        
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r = replacePlaceholderFake(placeholder, settings: settings, forItem: itemIndex)
            
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
    
    func replacePlaceholdersFake(in template: String, settings: Settings, attributes: [NSAttributedString.Key: Any]? = nil, forItem itemIndex: Int) -> NSMutableAttributedString {
        let results = Self.splitTokens(in: template)
        guard !results.isEmpty else {
            return NSMutableAttributedString(string: template)
        }
        
        let text = NSMutableAttributedString(string: template)
        
        for result in results {
            let placeholder = String(template[Range(result.range, in: template)!])
            let r: String
            if placeholder.hasPrefix("[[script-global:") || placeholder.hasPrefix("[[script-inline:") {
                
                let isGlobal = placeholder.hasPrefix("[[script-global:")
                if isGlobal {
                    r = "<global script>"
                } else {
                    r = "<inline script>"
                }
                if let code = String(placeholder.dropFirst(16).dropLast(2)).fromBase64(), !code.isEmpty {
                    // Evaluate the code to check execution error.
                    do {
                        if let result = try evaluateScript(code: code, forItem: itemIndex) {
                            if isGlobal {
                                if !result.isArray && !result.isNull {
                                    self.jsDelegate?.onJSException(info: self, exception: "Global script token must return an array!", atLine: -1, forItemAtIndex: itemIndex)
                                }
                            } else {
                                if !result.isString && !result.isNull {
                                    self.jsDelegate?.onJSException(info: self, exception: "Inline script token must return a string value!", atLine: -1, forItemAtIndex: itemIndex)
                                }
                            }
                        }
                    } catch {
                        
                    }
                }
            } else {
                r = Self.replacePlaceholderFake(placeholder, settings: settings, forItem: itemIndex)
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
