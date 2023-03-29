//
//  UIViewExtension.swift
//  ImprovePerformance
//
//  Created by Beacon on 10/03/2023.
//

import UIKit

extension UIView {
    func borderRounded() {
        self.layer.cornerRadius = self.frame.size.height/2
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.clear.cgColor
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
}
