//
//  Date+Extension.swift
//  FishingDaze
//
//  Created by Adrian Bolinger on 9/11/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import Foundation

extension Date {
    
    /*
     Pressing Option + Command + / at the same time above a method, variable, struct, etc. adds documentation, which is what I did below.
     */
    
    /// Returns a string formatted for the specified dateStyle and timeStyle from a given `Date` object
    ///
    /// - Parameters:
    ///   - dateStyle: Specified date format (.none, .short, .medium, .long, .full)
    ///   - timeStyle: Specified date format (.none, .short, .medium, .long, .full)
    ///
    /// Default timeStyle is .none
    /// - Returns: A string representation of a Date object
    func string(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style = .none) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        dateFormatter.locale = Locale(identifier: "en_US")
        
        return dateFormatter.string(from: self)
    }
}
