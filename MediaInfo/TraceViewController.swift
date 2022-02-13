//
//  TraceViewController.swift
//  MediaInfoEx
//
//  Created by Sbarex on 12/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import AppKit
import JavaScriptCore

class TraceViewController: NSViewController {
    @IBOutlet weak var textView: NSTextView!
    
    @IBAction func doReset(_ sender: Any) {
        textView.string = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.string = ""
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleJSConsole(_:)), name: .JSConsole, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleJSException(_:)), name: .JSException, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .JSConsole, object: nil)
        NotificationCenter.default.removeObserver(self, name: .JSException, object: nil)
    }
    
    internal func appendInfoHead(_ info: BaseInfo, level: String, itemIndex index: Int) {
        let d: String
        if #available(macOS 12.0, *) {
            d = Date().formatted(.iso8601)
        } else {
            d = "\(Date().timeIntervalSince1970)"
        }
        let color: NSColor
        if level == "error" {
            color = .systemRed
        } else if level == "warn" {
            color = .systemOrange
        } else if level == "info" {
            color = .secondaryLabelColor
        } else if level == "debug" {
            color = .tertiaryLabelColor
        } else {
            color = .secondaryLabelColor
        }
        textView.textStorage?.append(NSAttributedString(string: "(\(d)) \(info) [mnu \(index)]:\n", attributes: [.foregroundColor: color]))
    }
    
    @objc func handleJSConsole(_ notification : Notification) {
        guard let info = notification.object as? (BaseInfo, String, AnyHashable) else {
            return
        }
        let index = info.0.jsContext?.objectForKeyedSubscript("menuItemIndex").toNumber().intValue ?? -1
        
        let labelAttributes: [NSAttributedString.Key: AnyHashable] = [.foregroundColor: NSColor.labelColor]
        
        appendInfoHead(info.0, level: info.1, itemIndex: index)
        
        print("JSConsole \(info.0) [\(info.1) for menu item \(index)]: ", terminator: "")
        if let objects = info.2 as? [AnyHashable] {
            for object in objects {
                if JSONSerialization.isValidJSONObject(object), let data = try? JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed, .prettyPrinted, .sortedKeys]), let s = String(data: data, encoding: .utf8) {
                    print(s, terminator: " ")
                    textView.textStorage?.append(NSAttributedString(string: "\(s) ", attributes: labelAttributes))
                } else {
                    print(object, terminator: " ")
                    textView.textStorage?.append(NSAttributedString(string: "\(object) ", attributes: labelAttributes))
                }
            }
        } else {
            if JSONSerialization.isValidJSONObject(info.2), let data = try? JSONSerialization.data(withJSONObject: info.2, options: [.fragmentsAllowed, .prettyPrinted, .sortedKeys]), let s = String(data: data, encoding: .utf8) {
                print(s, terminator: "")
                textView.textStorage?.append(NSAttributedString(string: "\(s)", attributes: labelAttributes))
            } else {
                print(info.2, terminator: "")
                textView.textStorage?.append(NSAttributedString(string: "\(info.2)", attributes: labelAttributes))
            }
        }
        
        textView.textStorage?.append(NSAttributedString(string: "\n", attributes: [.foregroundColor: NSColor.labelColor]))
        print("\n")
        
        textView.scrollToEndOfDocument(nil)
    }
    
    @objc func handleJSException(_ notification : Notification) {
        guard let info = notification.object as? (BaseInfo, String?, Int, Int) else {
            return
        }
        
        // let index = info.0.jsContext?.objectForKeyedSubscript("menuItemIndex").toNumber().intValue ?? -1
        
        appendInfoHead(info.0, level: "error", itemIndex: info.3)
        
        textView.textStorage?.append(NSAttributedString(string: "Exception at line \(info.2):", attributes: [.foregroundColor: NSColor.systemRed]))
        textView.textStorage?.append(NSAttributedString(string: "\(info.1 ?? "")\n", attributes: [.foregroundColor: NSColor.labelColor]))
        
        textView.scrollToEndOfDocument(nil)
    }
}
