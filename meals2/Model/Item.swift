//
//  Item.swift
//  meals2
//
//  Created by Uwe Petersen on 20.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import CoreData


/// The type of data that is later to be displayed in a table view. It is distinguished between food, mealIngredient or hasNutrient with corresponding fool/meal, mealingredient and hasNutrient respectively.
///
/// - isFood: type is Food. Enclosed to the food is the meal that this food might be added to, later.
/// - isMealIngredient: type is meal ingredient (which has a food and belongs to a meal). Enclosed is the meal.
/// - isHasNutrients: type is has nutrients (conforms to the HasNutrients protocol), which might be a food, meal or recipe, which is enclosed.
enum Item {
    case isFood(Food, Meal?)
    case isMealIngredient(MealIngredient)
    case isHasNutrients(HasNutrients)
}
