//
//  MealIngredientExtension.swift
//  meals
//
//  Created by Uwe Petersen on 31.03.15.
//  Copyright (c) 2015 Uwe Petersen. All rights reserved.
//

import Foundation
import CoreData

extension MealIngredient {
    
    /// Return the Content of the nutrient with the key key as double
    func doubleForKey(_ key: String) -> Double? {
        if let foodValue = (self.food?.value(forKey: key) as? NSNumber)?.doubleValue {
            return foodValue * (self.amount?.doubleValue)! / 100.0 // per 100 g
        }
        return nil
    }
    
    override public var description: String {
        return String("Mealingredient: \(String(describing: self.amount)) g of \(String(describing: self.food?.name))")
    }
}

