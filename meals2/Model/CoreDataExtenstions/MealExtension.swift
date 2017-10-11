//
//  MealExtension.swift
//  bLS
//
//  Created by Uwe Petersen on 21.12.14.
//  Copyright (c) 2014 Uwe Petersen. All rights reserved.
//

import Foundation
import CoreData
import HealthKit

var dateOfCreationAsString_: String? = nil


extension Meal {
    
    public override func awakeFromInsert() {
        
        // Set date automatically when object ist created
        super.awakeFromInsert()
        self.dateOfCreation = Date() as NSDate
        self.dateOfLastModification = Date() as NSDate
    }
    
//    override public func didChange(_ changeKind: NSKeyValueChange, valuesAt indexes: IndexSet, forKey key: String) {
//        print("Meal did change the following: ")
//        print("\(changeKind)")
//        print("\(indexes)")
//        print("\(key)")
//    }
    
    
    // FIXME: hier mit weak und unowned experimentieren, für die $0
    /// sum of the content of one nutrient (e.g. "totalCarb") in a meal. Thus one has to sum over all (meal) ingredients
    /// Example: (sum [totalCarb content of each ingredient] / 100)
    func doubleForKey(_ key: String) -> Double? {        
//        let quantity = (self.ingredients.allObjects as! [MealIngredient])  // convert NSSet to [AnyObject] (via .allObjects) and then to [MealIngredient]
//            .filter {$0.food.valueForKeyPath(key) is NSNumber}             // valueForKeyPath returns AnyObject, thus check if it is of type NSNumber, and use only these
//            .map   {($0.food.valueForKeyPath(key) as! NSNumber).doubleValue / 100.0 * $0.amount.doubleValue} // Convert to NSNumber and then Double and multiply with amount of this ingredient
//            .reduce (0) {$0 + $1}                                          // sum up the doubles of all meal ingredients
//        return quantity
        
        let quantities = (self.ingredients!.allObjects as! [MealIngredient])  // convert NSSet to [AnyObject] (via .allObjects) and then to [MealIngredient]
            .filter {$0.food?.value(forKeyPath: key) is NSNumber}             // valueForKeyPath returns AnyObject, thus check if it is of type NSNumber, and use only these
            .map   {($0.food?.value(forKeyPath: key) as! NSNumber).doubleValue / 100.0 * ($0.amount?.doubleValue)!} // Convert to NSNumber and then Double and multiply with amount of this ingredient
        
        // sum up the values of all meal ingredients or return nil if no ingredients values where availabel (i.e. all foods had no entry for this nutrient)
        if quantities.isEmpty {
            return nil
        } else {
            return quantities.reduce(0.0, +)
        }
    }
    
    func doubleForNutrient(_ nutrient: Nutrient) -> Double? {
        return self.doubleForKey(nutrient.key!)
    }
    
    func hasFood(_ food: Food) -> Bool {
        for mealIngredient in self.ingredients?.allObjects as! [MealIngredient] {
            if mealIngredient.food == food {
                return true
            }
        }
        return false
    }
    
    
    // MARK: - transient property stuff for section headers (must be strings, take from transient property which is calculated from persistent date property)

    // TO MAKE THIS WORK: uncommented the property (@unmanaged) in the file generated by core data. Now this property is taken from here instead of the database.

    @objc dynamic var dateOfCreationAsString: String {
        get {
            // Create the section identifier on demand. This is also a transient property in the core data database. Although, this seems to work without the transient property, too
            self.willAccessValue(forKey: "dateOfCreationAsString")
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss'"
            //        formatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
            let stringToReturn = formatter.string(from: self.dateOfCreation! as Date)
            
            self.didAccessValue(forKey: "dateOfCreationAsString")
            
            return stringToReturn
        }
    }
    

    /// Fetches all meals from the core data database.
    class func fetchAllMeals(managedObjectContext context: NSManagedObjectContext) -> [Meal]? {
        
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateOfCreation", ascending: false)]

        do {
            let meals = try context.fetch(request)
            return meals
        } catch {
            print("Error fetching all meals: \(error)")
        }
        return nil
    }
    
    
    /// Fetches the newest meal from the core data database.
    class func fetchNewestMeal(managedObjectContext context: NSManagedObjectContext) -> Meal? {

        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateOfCreation", ascending: false)]
        
        do {
            let meals = try context.fetch(request)
            return meals.first
        } catch {
            print("Error fetching newest meal: \(error)")
        }
        return nil
    }
    
    /// Overall amount of all meal ingredients in gram
    var amount: Double {
        return ingredients!.allObjects
            .filter{$0 is MealIngredient}
            .map {$0 as! MealIngredient}
            .map {$0.amount!.doubleValue}
            .reduce(0.0, +)
    }
    
    
    /// Creates a new meal by from the given meal.The new meal will have the same meal ingredients and that is it.
    /// Everything else will be as with a new meal. Since meal ingredients are unique to a meal, the have to be
    /// created newly from the ones of the given meal.
    class func fromMeal(_ meal: Meal, inManagedObjectContext context: NSManagedObjectContext) -> Meal? {
        let newMeal = Meal(context: context)
        // copy meal ingredients (a meal ingredient can have only one meal, thus new meal ingredients have to be created)
        if let mealIngredients = meal.ingredients?.allObjects as? [MealIngredient] {
            for mealingredient in mealIngredients {
                let newMealIngredient = MealIngredient(context: context)
                newMealIngredient.food = mealingredient.food
                newMealIngredient.amount = mealingredient.amount
                newMealIngredient.meal = newMeal
            }
        }
        return newMeal
    }
}
