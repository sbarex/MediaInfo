//
//  File.DPIView
//  MediaInfoEx
//
//  Created by Sbarex on 13/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import AppKit

protocol DPIViewProtocol: AnyObject {
    func dpiView(_ dpiView: DPIView, didChage state: Bool, dpi: Int)
}

class DPIView: NSView {
    @IBOutlet weak var contentView: NSView!
 
    @objc dynamic var isEnabled = false {
        didSet {
            delegate?.dpiView(self, didChage: isEnabled, dpi: dpi)
        }
    }
    @objc dynamic var dpi: Int = 150 {
        didSet {
            delegate?.dpiView(self, didChage: isEnabled, dpi: dpi)
        }
    }
    
    weak var delegate: DPIViewProtocol?
    weak var token: TokenPrint?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)
        
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.width, .height]
    }
}
