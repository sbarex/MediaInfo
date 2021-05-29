//
//  NSImage+ext.swift
//  MediaInfo
//
//  Created by Sibarex on 18/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Cocoa

extension NSImage {
    func image(withTintColor tintColor: NSColor) -> NSImage {
        guard isTemplate else {
            return self
        }
        guard let copiedImage = self.copy() as? NSImage else {
            return self
        }
        copiedImage.lockFocus()
        tintColor.set()
        let imageBounds = NSMakeRect(0, 0, copiedImage.size.width, copiedImage.size.height)
        imageBounds.fill(using: .sourceAtop)
        copiedImage.unlockFocus()
        copiedImage.isTemplate = false
        return copiedImage
    }
    
    func resized(to newSize: NSSize) -> NSImage? {
        guard self.isValid else {
            return nil
        }
        
        guard self.size != newSize else {
            return self.copy() as? NSImage
        }
        
        let image = NSImage(size: newSize)
        image.lockFocus()
        let oldSize = self.size
        self.size = newSize
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(at: .zero, from: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), operation: .copy, fraction: 1.0)
        image.unlockFocus()
        self.size = oldSize
        return image
    }
}

