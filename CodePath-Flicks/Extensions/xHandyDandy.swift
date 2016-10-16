//
//  xUIColor.swift
//  tippy
//
//  Created by Ernest on 9/20/16.
//  Copyright © 2016 Purpleblue Pty Ltd. All rights reserved.
//

import UIKit

extension Double {
    
    func formatWithDecimalPlaces(decimalPlaces: Int) -> Double {
        let formattedString = String(format: "%.\(decimalPlaces)f", self) as String
        return Double(formattedString)!
    }
    
}
