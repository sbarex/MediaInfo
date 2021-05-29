//
//  TableCellView.swift
//  MediaInfoEx
//
//  Created by sbarex on 15/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

class ImageMenuCellView: NSTableCellView {
    struct Image {
        let name: String
        let title: String
        let color: Bool
        lazy var image: NSImage? = {
            guard !name.isEmpty else {
                return NSImage(named: "no-image")?.resized(to: NSSize(width: 16, height: 16))
            }
            var name = self.name
            if name == "page" || name == "bleed" || name == "artbox" || name == "pdf" {
                name += "_v"
            }
            let img = NSImage(named: name)?.resized(to: NSSize(width: 16, height: 16))
            img?.isTemplate = !color
            return img
        }()
        
        init(name: String, title: String, color: Bool = false) {
            self.name = name
            self.title = title
            self.color = color
        }
        
        static func separator() -> Image {
            return Image(name: "-", title: "-")
        }
    }
    
    static let images: [Image] = [
        Image(name: "", title: "No image", color: true),
        Image.separator(),
        Image(name: "image", title: "Image"),
        Image(name: "video", title: "Video"),
        Image(name: "audio", title: "Audio"),
        Image(name: "txt", title: "Subtitle"),
        Image(name: "pdf", title: "PDF"),
        
        Image.separator(),
        Image(name: "aspectratio", title: "Aspect ratio"),
        Image(name: "size", title: "File size"),
        Image(name: "print", title: "Printer"),
        Image(name: "person", title: "Person"),
        
        Image.separator(),
        Image(name: "color", title: "Color"),
        Image(name: "color_bw", title: "Black and White"),
        Image(name: "color_gray", title: "Gray scale", color: true),
        Image(name: "color_rgb", title: "RGB color", color: true),
        Image(name: "color_cmyk", title: "CMYK color", color: true),
        Image(name: "color_lab", title: "CIE Lab color", color: true),
        
        Image.separator(),
        Image(name: "page", title: "PDF page"),
        Image(name: "pages", title: "PDF number of pages"),
        Image(name: "page", title: "PDF media box"),
        Image(name: "bleed", title: "PDF bleed box"),
        Image(name: "crop", title: "PDF trim box"),
        Image(name: "artbox", title: "PDF art box"),
        Image(name: "shield", title: "PDF security"),
    ]
    
    @IBOutlet weak var popupButton: NSPopUpButton!
    
    var image: String = "image" {
        didSet {
            if let index = Self.images.firstIndex(where: { $0.name == image }) {
                self.popupButton.selectItem(at: index)
            } else {
                self.popupButton.selectItem(at: 0)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    private func initialize() {
        popupButton.removeAllItems()
        
        for var image in Self.images {
            if image.name == "-" {
                popupButton.menu?.addItem(NSMenuItem.separator())
            } else {
                let item = NSMenuItem(title: image.title, action: nil, keyEquivalent: "")
                item.image = image.image
                popupButton.menu?.addItem(item)
            }
        }
    }
}

class TokenMenuCellView: NSTableCellView {
    @IBOutlet weak var tokenField: NSTokenField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    private func initialize() {
        tokenField.tokenizingCharacterSet = CharacterSet(charactersIn: "\t")
    }
}
