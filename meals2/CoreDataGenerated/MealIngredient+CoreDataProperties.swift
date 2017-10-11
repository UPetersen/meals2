//
//  MealIngredient+CoreDataProperties.swift
//  meals2
//
//  Created by Uwe Petersen on 08.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//
//

import Foundation
import CoreData


extension MealIngredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MealIngredient> {
        return NSFetchRequest<MealIngredient>(entityName: "MealIngredient")
    }

    @NSManaged public var amount: NSNumber?
    @NSManaged public var food: Food?
    @NSManaged public var meal: Meal?

}
