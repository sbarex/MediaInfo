//
//  ScriptViewController.swift
//  MediaInfoEx
//
//  Created by Sbarex on 08/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import AppKit

class ScriptViewController: NSViewController {
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    var action: ((TokenScript?)->Void)? = nil
    
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
    
    var token: TokenScript? {
        didSet {
            textView?.string = token?.code ?? ""
        }
    }
    
    @IBAction func handleSave(_ sender: Any) {
        token?.code = textView.string
        self.action?(token)
        self.dismiss(self)
    }
    
    @IBAction func handleWordWrap(_ sender: Any) {
        self.wordWrap = !self.wordWrap
    }
    
    @IBAction func addInlineTemplate(_ sender: Any) {
        let code = """
(function() {
    /*
    The inline script code must return a string (or null) value.
    
    Global variables:
    - `fileData`: The properties of current file.
    - `templateItemIndex`: Zero based index of the current processed menu item template.
    - `currentItem`: Object of current processed menu item template.
    - `settings`: Application settings.
    
    */

    // console.log(fileData);
    
    // Return the text to be used inside the menu item.
    return "title";
})();

"""
        setCode(code)
    }
    
    @IBAction func addIGlobalTemplate(_ sender: Any) {
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
      - tag (Int).
      - checked (Boolean)
      - enabled (Boolean)
      - indent (Int, between 0 - 15)
      - userInfo ([String: Any]): Custom user info
      - action (String)
      - items (Array of menu items): A list of submenu items.

    Global variables:
    - `fileData`: The properties of current file.
    - `templateItemIndex`: Zero based index of the current processed menu item template.
    - `currentItem`: Object of current processed menu item template.
    - `settings`: Application settings.
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
    
    @IBAction func addActionTemplate(_ sender: Any) {
        let code = """
/*
Global variables:
- `fileData`: The properties of current file.
- `settings`: Application settings.
- `selectedMenuItem`: Properties of the chosen menu item:
    - index (Int): index inside the template
    - menuItem
        - image (String)
        - template (String)
    - action (String)
    - userInfo ([String: Any])

Available commands:
- systemOpen(file): open the `file` path winth the defalt app.
- systemOpenWith(file, app): open the `file` path winth the `app` path.
- systemOpenApp(path): open the application at `path`.
- systemExec(command, [arguments]): execute the `command` with the list of `arguments`.

*/

systemOpen(fileData.filePath);

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
        self.textView.string = token?.code ?? ""
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
