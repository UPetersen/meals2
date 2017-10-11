//
//  Nutrients.swift
//  meals
//
//  Created by Uwe Petersen on 12.06.15.
//  Copyright (c) 2015 Uwe Petersen. All rights reserved.
//

import Foundation

//@objc protocol HasNutrients {
//
//}

/// Some notes:
///   @objc needed for
///      a) optional requirements (i.e. a property that may be implemented but not needs to be implemented) and
///      b) the ability to check for type conformity via "is", but
///      c) then the protocol can be adopted by classes only

/// HasNutrients should be used for meals, meal ingredients, foods, and recipes
protocol HasNutrients {
    
    var dateOfCreation: Date { get }
    var amount: Double { get }
    
    /// returns the double value for the nutrient with the key key as stored.
    /// Since all nutrients have a unit property this is with respect to this unit.
    func doubleForKey(_ key: String) -> Double?
    
}
    
protocol SomeOtherProtocolNotYetInUse {
    /// overall amount (i.e. mass) of the item
    var amount: Double { get } /// BUMMER: Food has no amount yet. Maybe this is the key to add it as property
    
    var dateOfCreation: Date { get }
    
    /// returns the double value for the nutrient in the stored unit (according to HKQuantity)
    func doubleForNutrient(_ nutrient: Nutrient) -> Double?
    
    
    /// MARK - these are just in Food yet:
    
    /// Return the value as a String in the unit specified by hkDispUnit in nutrients, e.g. "12.3 µg"
    /// If something fails, either nil or an empty unit string (e.g. "g") is returned, depending on showUnit
    func dispStringForNutrient(_ nutrient: Nutrient, formatter: NumberFormatter, showUnit: Bool) -> String?     // Umbenennen in stringWithValueAndUnit oder so ähnlich?
    
    
    
    /// Return the value as a String in the unit specified by hkDispUnit in nutrients, e.g. "12.3 µg"
    /// If something fails, either nil or an empty unit string (e.g. "g") is returned, depending on showUnit
    func dispStringForNutrientWithKey(_ key: String, formatter: NumberFormatter, showUnit: Bool) -> String?     // Umbenennen in stringWithValueAndUnit oder so ähnlich?
    
    
    // These are in Nutrient and it should be checked, if the are placed there well:
    
    /// Return the value as a String in the unit specified by hkDispUnit in nutrients, e.g. "12.3 µg"
    /// If something fails, either nil or an empty unit string (e.g. "g") is returned, depending on showUnit
    func valueForDisp(_ dispString: String, formatter: NumberFormatter) -> Double?
    
    /// Return the value as a String in the unit specified by hkDispUnit in nutrients, e.g. "12.3 µg"
    /// If something fails, either nil or an empty unit string (e.g. "g") is returned, depending on showUnit
    func dispStringForValue(_ value: Double?, formatter: NumberFormatter, showUnit: Bool) -> String?
    
    /// Return the value as a String in the unit specified by hkDispUnit in nutrients, e.g. "12.3 µg"
    /// If something fails, either nil or an empty unit string (e.g. "g") is returned, depending on showUnit
    /// Example:
    ///
//    static func dispStringForNutrientWithKey(key: String, value: Double?, formatter: NSNumberFormatter, showUnit: Bool, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> String?
    
    
    
    
    
    /// Notes to remember:
    /// Recipe not yet implemented at all, but probably pretty much the same as Meal
    
    
}
