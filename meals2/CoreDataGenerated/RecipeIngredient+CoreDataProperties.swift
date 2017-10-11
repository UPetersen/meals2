//
//  RecipeIngredient+CoreDataProperties.swift
//  meals2
//
//  Created by Uwe Petersen on 02.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//
//

import Foundation
import CoreData


extension RecipeIngredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecipeIngredient> {
        return NSFetchRequest<RecipeIngredient>(entityName: "RecipeIngredient")
    }

    @NSManaged public var amount: NSNumber?
    @NSManaged public var food: Food?
    @NSManaged public var recipe: Recipe?

}
