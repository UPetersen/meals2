//
//  Nutrients.swift
//  meals
//
//  Created by Uwe Petersen on 12.06.15.
//  Copyright (c) 2015 Uwe Petersen. All rights reserved.
//

import Foundation

// Some notes:
//   @objc needed for
//      a) optional requirements (i.e. a property that may be implemented but not needs to be implemented) and
//      b) the ability to check for type conformity via "is", but
//      c) then the protocol can be adopted by classes only

/// Data type that provides the nutrients and their respecive amount contained
/// in a food, meal or recipe. Amount means relative amount (per 100 grams) for food
/// and absolute amount in the meal or recipe for meals an recipes.
protocol HasNutrients {
    
//    var dateOfCreation: Date { get }
//    var amount: Double { get }
    var dateOfCreation: NSDate? { get } // changed to NSDdate? as of iOS 11
    var amount: NSNumber? { get }       // changed to NSNumber? as of iOS 11

    /// returns the double value for the nutrient with the key key as stored.
    /// Since all nutrients have a unit property this is with respect to this unit.
    func doubleForKey(_ key: String) -> Double?
}
