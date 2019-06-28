//
//  ColorPalette.swift
//  PDF Annotations
//
//  Created by Junnosuke Nakamura on 6/15/19.
//  Copyright © 2019 Appkey. All rights reserved.
//

import UIKit

class ColorPalette: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        //rounded shape
        self.layer.cornerRadius = self.frame.height/2
        self.clipsToBounds = true
    }

}
