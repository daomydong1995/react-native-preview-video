//
//  RangeControlTrackLayer.swift
//  ImprovePerformance
//
//  Created by Beacon on 10/03/2023.
//

import QuartzCore
import UIKit

class RangeControlTrackLayer: CALayer {
    weak var rangeControl: RangeControl?
    override func action(forKey event: String) -> CAAction? {
        if(event == "position" || event == "contents"){ return nil }
        return super.action(forKey: event)
    }
    
    override func draw(in ctx: CGContext) {
        if let slider = rangeControl {
            //Tack
            let rectTrack = CGRect(x: slider.thumbWidth, y: slider.margin, width: bounds.width - 2*slider.thumbWidth, height: bounds.height - slider.margin*2)
            let path = UIBezierPath(rect: rectTrack)
            
            let lowerValuePosition = CGFloat(slider.positionForValue(slider.lowValue))
            let upperValuePosition = CGFloat(slider.positionForValue(slider.upValue))
            //Cut rect
            let rect = CGRect(x: lowerValuePosition - slider.thumbWidth/2.0 , y: slider.margin, width: upperValuePosition - lowerValuePosition + slider.thumbWidth, height: bounds.height - slider.margin*2 )
            
            let cutout = UIBezierPath(rect: rect)
            path.append(cutout.reversing())
            ctx.addPath(path.cgPath)
            
            // Fill the track
            ctx.setFillColor( slider.trackColor.cgColor)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            
            //Frame borders
            let border = CGRect(x: lowerValuePosition - slider.thumbWidth/2.0, y: 0, width: upperValuePosition - lowerValuePosition , height: bounds.height)
            let borderPath = UIBezierPath(rect: border)
            
            let borderCut = CGRect(x: lowerValuePosition - slider.thumbWidth/2.0, y: slider.margin, width: upperValuePosition - lowerValuePosition , height: bounds.height - slider.margin*2)
            let borderCutPath = UIBezierPath(rect: borderCut)
            
            borderPath.append(borderCutPath.reversing())
            ctx.setFillColor(slider.thumbColor.cgColor)
            ctx.addPath(borderPath.cgPath)
            ctx.fillPath()
            
        }
    }
}
