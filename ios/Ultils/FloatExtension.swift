//
//  FloatExtension.swift
//  ImprovePerformance
//
//  Created by Beacon on 09/03/2023.
//

import Foundation

extension Float {
    /*
     * Truncate to places
     * Example: places = 0 --> (0.5 -> 1), (0.4 -> 0)
     *
     */
    func truncate(places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded()/divisor
    }
    
    func roundDown(places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded(.down)/divisor
    }
}
