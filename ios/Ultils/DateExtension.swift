//
//  DateExtension.swift
//  ImprovePerformance
//
//  Created by Beacon on 09/03/2023.
//

import Foundation
extension Date {
    func stringFromDate(format: String) -> String {
        let formatter = DateFormatter.init()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}
