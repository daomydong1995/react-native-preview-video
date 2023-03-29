//
//  UiColorExtension.swift
//  ImprovePerformance
//
//  Created by Beacon on 10/03/2023.
//

import UIKit
extension UIColor {
    // Custom color
    convenience init(hex: Int,alpha: CGFloat = 1) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: alpha)
    }
    
    func navBarImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize.init(width: 1, height: 88))
        guard let ctx = UIGraphicsGetCurrentContext() else { return UIImage() }
        self.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 88))
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()
        return image
    }
}
