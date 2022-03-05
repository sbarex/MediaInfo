//
//  ItemsEditorController.swift
//  MediaInfoEx
//
//  Created by Sbarex on 26/02/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

import AppKit

class ItemsEditorController: NSViewController {
    @IBOutlet weak var itemsView: MenuTableView!
    var initView: ((ItemsEditorController)->Void)?
    var onSave: ((ItemsEditorController)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initView?(self)
    }
    
    override func viewWillAppear() {
        self.view.window?.titlebarAppearsTransparent = true
        if #available(macOS 11.0, *) {
            self.view.window?.titlebarSeparatorStyle = .none
            self.view.window?.toolbarStyle = .unified
        }
        super.viewWillAppear()
    }
    
    @IBAction func handleDone(_ sender: Any) {
        onSave?(self)
        self.dismiss(sender)
    }
}
