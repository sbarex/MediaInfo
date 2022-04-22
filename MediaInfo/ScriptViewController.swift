//
//  ScriptViewController.swift
//  MediaInfoEx
//
//  Created by Sbarex on 08/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import AppKit

class ScriptViewController: NSViewController {
    enum ScriptMode: Int {
        case inline
        case global
        case validate
        case beforeRender
        case action
    }
    
    static func editCode(_ code: String, mode: ScriptMode, action: @escaping (String)->Void) {
        guard let vc = NSStoryboard.main?.instantiateController(withIdentifier: "ScriptEditorController") as? ScriptViewController else {
            return
        }
        vc.code = code
        vc.action = action
        vc.mode = mode
        
        NSApplication.shared.keyWindow?.contentViewController?.presentAsModalWindow(vc)
    }
    
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var templateButton: NSPopUpButton!
    @IBOutlet weak var imageMenu: NSMenu!
    
    var mode: ScriptMode = .inline
    var action: ((String)->Void)? = nil
    
    var wordWrap: Bool = true {
        didSet {
            guard oldValue != wordWrap else { return }
            if wordWrap {
                /// Matching width is also important here.
                let sz1 = self.scrollView.contentSize
                self.textView.frame = CGRect(x: 0, y: 0, width: sz1.width, height: 0)
                self.textView.textContainer!.containerSize = CGSize(width: sz1.width, height: CGFloat.greatestFiniteMagnitude)
                self.textView.textContainer!.widthTracksTextView = true
            } else {
                self.textView.textContainer!.widthTracksTextView = false
                self.textView.textContainer!.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            }
        }
    }
    
    var code: String? {
        didSet {
            textView?.string = code ?? ""
        }
    }
    
    @IBAction func handleSave(_ sender: Any) {
        self.action?(self.textView.string)
        self.dismiss(self)
    }
    
    @IBAction func handleWordWrap(_ sender: Any) {
        self.wordWrap = !self.wordWrap
    }
    
    func getGlobalVars() -> [String] {
        switch mode {
        case .inline, .global:
            return [
                "- `fileData`: The properties of the current file.",
                "- `templateItemIndex`: Zero based index of the current processed menu item template.",
                "- `currentItem`: Object of current processed menu item template.",
                "- `settings`: Application settings.",
            ]
        case .validate:
            return [
                "- `currentFile`: Path of the the file to be processed."
            ]
        case .beforeRender:
            return [
                "- `fileData`: The properties of the current file.",
                "- `settings`: Application settings.",
                "- `currentMenuItems`: Array of the menu item templates",
            ]
        case .action:
            return [
                "- `fileData`: The properties of current file.",
                "- `settings`: Application settings.",
"""
- `selectedMenuItem`: Properties of the chosen menu item:
    - index (Int): index inside the template
    - menuItem
        - image (String)
        - template (String)
    - action (String)
    - userInfo ([String: Any])
"""
            ]
        }
    }
    
    func getGlobalCommands() -> [String] {
        switch mode {
        case .inline, .global, .validate, .beforeRender:
            return ["- systemExecSync(command, [arguments]): execute the `command` with the list of `arguments` and wait for it to complete."]
        case .action:
            return [
                "- systemOpen(file): open the `file` path winth the defalt app.",
                "- systemOpenWith(file, app): open the `file` path winth the `app` path.",
                "- systemOpenApp(path): open the application at `path`.",
                "- systemExec(command, [arguments]): execute the `command` with the list of `arguments`.",
                "- systemExecSync(command, [arguments]): execute the `command` with the list of `arguments` and wait for it to complete.",
            ]
        }
    }
    
    @IBAction func addInlineTemplate(_ sender: Any) {
        let code = """
(function() {
/*
The inline script code must return a string (or null) value.

Global variables:
\(self.getGlobalVars().joined(separator: "\n"))

Available command:
\(self.getGlobalCommands().joined(separator: "\n"))

*/

    // console.log(fileData);
    
    // Return the text to be used inside the menu item.
    return "title";
})();

"""
        setCode(code)
    }
    
    @IBAction func addGlobalTemplate(_ sender: Any) {
        let code = """
(function() {
/*
The global script code must return an array of menu items (or null).

Each element of the array can be:
- A plain string (the title of the menu item).
- A dash ("-") to insert a separator.
- An object with these properties:
  - title (String, *required*): The menu item title.
  - image (String): The image of the menu item.
  - tag (Int)
  - checked (Boolean)
  - enabled (Boolean)
  - indent (Int, between 0 - 15)
  - userInfo ([String: Any]): Custom user info.
  - action (String)
  - items (Array of menu items): A list of submenu items.

Global variables:
\(self.getGlobalVars().joined(separator: "\n"))

Available command:
\(self.getGlobalCommands().joined(separator: "\n"))

*/

    // console.log(fileData); // fileData contains the current info properties.

    // Return the list of menu items.
    return [
        "simple plain title",
        "-", // Add a menu item separator.
        {
            title: "complete menu title",
            image: "no-image",
            items: []
        }
    ];
})();

"""
        setCode(code)
    }
    
    @IBAction func addValidateTriggerTemplate(_ sender: Any) {
        let code = """
/*
Global variables:
\(self.getGlobalVars().joined(separator: "\n"))

Available commands:
\(self.getGlobalCommands().joined(separator: "\n"))

*/

// return currentFile.indexOf("test") < 0; // Skip file with "test" in the path.

return true; // return false to abort the menu generation.

"""
        setCode(code)
    }
    
    @IBAction func addActionTriggerTemplate(_ sender: Any) {
        let code = """
/*
Global variables:
\(self.getGlobalVars().joined(separator: "\n"))

Available commands:
\(self.getGlobalCommands().joined(separator: "\n"))
*/

systemOpen(fileData.filePath);

"""
        setCode(code)
    }
    
    @IBAction func addBeforeRenderTriggerTemplate(_ sender: Any) {
        let code = """
/*
Global variables:
\(self.getGlobalVars().joined(separator: "\n"))

Available commands:
\(self.getGlobalCommands().joined(separator: "\n"))

Return null or `currentMenuItems` to mantain the current items, otherwise return an array of templates: {image: "image-name", template: "List of placeholders"}.
*/

return [{image:"image", template: "[[file-name]]: [[filesize]]"}];

"""
        setCode(code)
    }
        
    func setCode(_ code: String) {
        if !self.textView.string.isEmpty {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Are you sure to replace the current script code?", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("Replace", comment: "")).keyEquivalent = "\r"
            alert.addButton(withTitle: "Cancel").keyEquivalent = "\u{1b}"
            guard alert.runModal() == .alertFirstButtonReturn else {
                return
            }
        }
        self.textView.string = code
    }
    
    override func viewDidLoad() {
        self.textView.isAutomaticQuoteSubstitutionEnabled = false
        self.textView.isAutomaticLinkDetectionEnabled = false
        self.textView.isAutomaticLinkDetectionEnabled = false
        self.textView.isAutomaticTextCompletionEnabled = false
        self.textView.isAutomaticTextReplacementEnabled = false
        self.textView.isAutomaticDashSubstitutionEnabled = false
        self.textView.isAutomaticSpellingCorrectionEnabled = false
        self.textView.string = code ?? ""
        
        if let menu = templateButton.menu {
            while menu.items.count > 4 {
                menu.removeItem(at: menu.items.count - 1)
            }
            switch mode {
            case .inline:
                menu.addItem(withTitle: NSLocalizedString("Inline code template", comment: ""), action: #selector(self.addInlineTemplate(_:)), keyEquivalent: "")
                if self.textView.string.isEmpty {
                    self.addInlineTemplate(self)
                }
            case .global:
                menu.addItem(withTitle: NSLocalizedString("Global code template", comment: ""), action: #selector(self.addGlobalTemplate(_:)), keyEquivalent: "")
                if self.textView.string.isEmpty {
                    self.addGlobalTemplate(self)
                }
            case .validate:
                menu.addItem(withTitle: NSLocalizedString("Validate trigger template", comment: ""), action: #selector(self.addValidateTriggerTemplate(_:)), keyEquivalent: "")
                if self.textView.string.isEmpty {
                    self.addValidateTriggerTemplate(self)
                }
            case .beforeRender:
                menu.addItem(withTitle: NSLocalizedString("Before render trigger template", comment: ""), action: #selector(self.addBeforeRenderTriggerTemplate(_:)), keyEquivalent: "")
                if self.textView.string.isEmpty {
                    self.addBeforeRenderTriggerTemplate(self)
                }
            case .action:
                menu.addItem(withTitle: NSLocalizedString("Action trigger template", comment: ""), action: #selector(self.addActionTriggerTemplate(_:)), keyEquivalent: "")
                if self.textView.string.isEmpty {
                    self.addActionTriggerTemplate(self)
                }
            }
        }
        for var image in MenuItemEditor.images {
            if image.name == "-" {
                imageMenu.addItem(NSMenuItem.separator())
            } else {
                let item = NSMenuItem(title: image.title, action: #selector(self.handleImageMenu(_:)), keyEquivalent: "")
                item.indentationLevel = image.indent
                item.image = image.image
                item.representedObject = image.name
                imageMenu.addItem(item)
            }
        }
    }
    
    @IBAction func handleImageMenu(_ sender: NSMenuItem) {
        self.textView.insertText("\"\(sender.representedObject as? String ?? "")\"", replacementRange: self.textView.selectedRange())
    }
}

// MARK: - NSTextViewDelegate
extension ScriptViewController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertTab(_:)) {
            textView.insertText("    ", replacementRange: textView.rangeForUserTextChange)
            return true
        } else {
            return false
        }
    }
}

// MARK: - NSMenuDelegate
extension ScriptViewController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        menu.item(withTag: 1)?.state = wordWrap ? .on : .off
    }
}
