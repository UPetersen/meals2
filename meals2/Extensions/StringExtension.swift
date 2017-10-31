//
//  StringExtension.swift
//  meals
//
//  Created by Uwe Petersen on 31.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation


// New (from 2017-09-26), taken from https://stackoverflow.com/questions/39611841/swift3-xcode8-subscript-is-unavailable-cannot-subscript-string-with-a-coun
//
// For   swift 4    S W I F T 4   see below.
extension String {
    
    subscript (r: CountableClosedRange<Int>) -> String {
        get {
            let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
            return String(self[startIndex...endIndex])
        }
    }
}
// or a safer version which checks the bounds and returns nil rather than an out-of-range exception:
//extension String {
//
//    subscript (r: CountableClosedRange<Int>) -> String? {
//        get {
//            guard r.lowerBound >= 0, let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound, limitedBy: self.endIndex),
//                let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound, limitedBy: self.endIndex) else { return nil }
//            return self[startIndex...endIndex]
//        }
//    }
//}
// Swift 4 change: You need to create a new string from the result

//return String(self[startIndex...endIndex])
