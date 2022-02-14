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
    
    The global `fileData` contains the current info properties.
    The global `fileData.templateItemIndex` is the zero based index of the current processed template menu item.
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
    The global script code must return an array (or null) of menu items.

    Each element of the array can be:
    - a plain string (the title of the menu item)
    - a dash ("-") to insert a separator
    - an object with these properties:
      - title (String, *required*): The menu item title
      - image (String): The image of the menu item.
      - tag (Int)
      - checked (Boolean)
      - enabled (Boolean)
      - indent (Int between 0 - 15)
      - items (Array of menu items): A list of submenu items.

    The global `fileData` contains the current info properties.
    The global `fileData.templateItemIndex` is the zero based index of the current processed template menu item.
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

extension ScriptViewController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        menu.item(withTag: 1)?.state = wordWrap ? .on : .off
    }
}
