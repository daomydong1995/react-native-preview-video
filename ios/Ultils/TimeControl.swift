//
//  TimeControl.swift
//  ImprovePerformance
//
//  Created by Beacon on 13/03/2023.
//

import UIKit

class TimeControl: UIControl {
    var trackingLocation: ((_ trackingLocation: CGPoint) -> Void)?
    var beginLocation: ((_ trackingLocation: CGPoint) -> Void)?
    var endLocation: ((_ trackingLocation: CGPoint) -> Void)?

    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let firstLocation = touch.location(in: self)
        if let trackingCallBack = beginLocation {
            trackingCallBack(firstLocation)
        }
        return true
    }
    
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        if let trackingCallBack = trackingLocation {
            trackingCallBack(location)
        }
        return super.continueTracking(touch, with: event)
    }
    
    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let location = touch?.location(in: self), let endCallBack = endLocation {
            endCallBack(location)
        }
        return
        print("end location: \(endLocation)")
    }
}
