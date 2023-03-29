//
//  RangeControlThumbLayer.swift
//  ImprovePerformance
//
//  Created by Beacon on 10/03/2023.
//

import QuartzCore
import UIKit

class RangeControlThumbLayer: CALayer {
    private let arrowHeight = CGFloat(28.0/128.0)
    private let arrowWidth = CGFloat(10.0/32.0)
    
    var isLeft = false
    var highlighted: Bool = false
    
    override func action(forKey event: String) -> CAAction? {
        if(event == "position"){  return nil }
        return super.action(forKey: event)
    }
    
    weak var rangeControl: RangeControl?
    override func draw(in ctx: CGContext) {
        if let slider = rangeControl {
            let thumbFrame = bounds
            let rectCorners: UIRectCorner = isLeft ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight]
            let path = UIBezierPath(roundedRect: thumbFrame,
                                    byRoundingCorners: rectCorners,
                                    cornerRadii: CGSize(width: 24, height:  44))
            ctx.addPath(path.cgPath)
            
            //Thumb
            ctx.setFillColor( slider.thumbColor.cgColor)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
            
            //Arrows
            let arrow = UIBezierPath()
            let center = CGPoint(x: bounds.width/2.0, y: bounds.height/2.0)
            let arrowSize = CGSize(width: bounds.width * arrowWidth/1.5, height: bounds.height * arrowHeight)
            let arrowRect = CGRect(x: center.x - arrowSize.width/2, y: center.y - arrowSize.height/2, width: arrowSize.width, height: arrowSize.height)
            
            if !isLeft {
                arrow.move(to: arrowRect.origin)
                arrow.addLine(to: CGPoint(x: center.x + arrowSize.width/2.0, y: center.y))
                arrow.move(to:  CGPoint(x: center.x + arrowSize.width/2.0, y: center.y))
                arrow.addLine(to: CGPoint(x: arrowRect.origin.x, y: arrowRect.origin.y + arrowRect.height))
            } else {
                arrow.move(to: CGPoint(x: arrowRect.origin.x + arrowSize.width, y: arrowRect.origin.y))
                arrow.addLine(to: CGPoint(x: center.x - arrowSize.width/2.0, y: center.y))
                arrow.move(to: CGPoint(x: center.x - arrowSize.width/2.0, y: center.y))
                arrow.addLine(to: CGPoint(x: arrowRect.origin.x + arrowSize.width, y: arrowRect.origin.y + arrowRect.height))
            }
            
            ctx.setLineWidth(1)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(slider.arrowColor.cgColor)
            ctx.addPath(arrow.cgPath)
            ctx.strokePath()
        }
    }
}
