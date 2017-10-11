//
//  Meal+CoreDataProperties.swift
//  meals2
//
//  Created by Uwe Petersen on 08.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//
//

import Foundation
import CoreData


extension Meal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meal> {
        return NSFetchRequest<Meal>(entityName: "Meal")
    }

    @NSManaged public var comment: String?
    @NSManaged public var dateOfCreation: NSDate?
//    @NSManaged public var dateOfCreationAsString: String? // This property is created as computed property in an extension.
    @NSManaged public var dateOfLastModification: NSDate?
    @NSManaged public var ingredients: NSSet?

}

// MARK: Generated accessors for ingredients
extension Meal {

    @objc(addIngredientsObject:)
    @NSManaged public func addToIngredients(_ value: MealIngredient)

    @objc(removeIngredientsObject:)
    @NSManaged public func removeFromIngredients(_ value: MealIngredient)

    @objc(addIngredients:)
    @NSManaged public func addToIngredients(_ values: NSSet)

    @objc(removeIngredients:)
    @NSManaged public func removeFromIngredients(_ values: NSSet)

}
