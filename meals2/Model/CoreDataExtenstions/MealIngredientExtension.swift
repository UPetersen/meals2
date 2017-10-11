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
    
//    override func willSave() {
//        super.willSave()
//        println("Meal ingredient will be saved")
//        if self.deleted {
//            println("Meal ingredient will be deleted")
//        }
//        if self.updated {
//            println("Meal ingredient will be updated")
//        }
//        if self.inserted {
//            println("Meal ingredient will be inserted")
//        }
//    }
//    
//    override func didChangeValueForKey(key: String) {
//        super.didChangeValueForKey(key)
//        println("Meal  ingredient did change value for key '\(key)'")
//    }
}

