//
//  FoodListTypes.swift
//  meals
//
//  Created by Uwe Petersen on 08.09.15.
//  Copyright © 2015 Uwe Petersen. All rights reserved.
//

import Foundation

enum SearchFilter: String {
    case BeginsWith = "Beginnt mit ..."
    case Contains = "Enthält ..."

//    return NSPredicate(format: "name BEGINSWITH[c] %@", searchText)
    func predicateForSearchText(_ searchText: String?) -> NSPredicate? {
        guard let searchText = searchText, !searchText.isEmpty else {
            return nil
        }
        switch self {
        case .BeginsWith:
            // Search foods where the name begins with the exact term given in the search bar text field
            return NSPredicate(format: "name BEGINSWITH[c] %@", searchText)
        case .Contains:
            // Search for foods where the name contains the words given in the search bar text field
            let wordsAndEmptyStrings: [String] = searchText.components(separatedBy: CharacterSet.whitespaces) // White space are components, too
            let predicate = NSPredicate(format: "length > 0")
            
            let words = wordsAndEmptyStrings.filter {predicate.evaluate(with: $0)}  // Now real text components only w/o the spaces
            print("The words in the search text: \(words)")
            
            // Loop over the components, build predicate for each one (word), functional way of creating an arry of predicates
            let subPredicates = words.map({word -> NSPredicate in NSPredicate(format: "name contains[c] %@", word)})
            
            return NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: subPredicates)
        }
    }

}

enum FoodListType: String {
    case Favorites = "Favoriten"
    case Recipes = "Rezepte"
    case LastWeek = "Letzte Woche"
    case MealIngredients = "Selbst gegessen"
    case OwnEntries = "Selbst eingetragen"
    case BLS = "Bundeslebensmittelschlüssel"
    case All = "Alle"
    
    // TODO: correct source completely: opulate user's own entries with a spcific source and use BLS-Source in the following for the following switch statement
    var predicate: NSPredicate? {
        switch self {
        case .All:
            return nil
        case .Favorites:
            return NSPredicate(format: "favoriteListItem != nil")
        case .Recipes:
            return NSPredicate(format: "recipe != nil")
        case .LastWeek:
            let lastWeek = Date(timeIntervalSinceNow: -86400.0*7.0)
            return NSPredicate(format: "SUBQUERY(mealIngredients, $x, $x.meal.dateOfCreation >= %@).@count != 0", lastWeek as CVarArg)
        case .OwnEntries:
            return NSPredicate(format: "source = nil")
        case .MealIngredients:
            return NSPredicate(format: "mealIngredients.@count > 0")
        case .BLS:
            return NSPredicate(format: "source != nil")
        }
    }
}

enum FoodListSortRule: String {
    
    case NameAscending = "Name"
    case TotalEnergyCalsDescending = "Kalorien"
    case TotalCarbDescending = "KH"
    case TotalProteinDescending = "Protein"
    case TotalFatDescending = "Fett"
    case GroupThenSubGroupThenNameAscending = "Gruppe"
    case FattyAcidCholesterolDescending = "Cholesterin"
    
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .NameAscending:
            return [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .TotalEnergyCalsDescending:
            return [NSSortDescriptor(key: "totalEnergyCals", ascending: false, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .TotalCarbDescending:
            return [NSSortDescriptor(key: "totalCarb", ascending: false, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .TotalProteinDescending:
            return [NSSortDescriptor(key: "totalProtein", ascending: false, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .TotalFatDescending:
            return [NSSortDescriptor(key: "totalFat", ascending: false, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .FattyAcidCholesterolDescending:
            return [NSSortDescriptor(key: "fattyAcidCholesterol", ascending: false, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        case .GroupThenSubGroupThenNameAscending:
            //            sortDescriptors = [NSSortDescriptor(key: "group.name", ascending: true, selector: "localizedCaseInsensitiveCompare:"),
            //                NSSortDescriptor(key: "subGroup.name", ascending: true, selector: "localizedCaseInsensitiveCompare:"),
            //                NSSortDescriptor(key: "name", ascending: true, selector: "localizedCaseInsensitiveCompare:")]
            //            sectionNameKeyPath = "group.name"
            
            return [NSSortDescriptor(key: "subGroup.name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
            //            sortDescriptors = [NSSortDescriptor(key: "key", ascending: true, selector: "localizedCaseInsensitiveCompare:")]
            //            sectionNameKeyPath = "key"
            
            //          Does not work this way and seems to be quite complicated. Need to use an extra (conputed?) property or some other technique
            //        case .FrequencyDescendingThenNameAscending:
            //            return [NSSortDescriptor(key: "countOfMealIngredients", ascending: false, selector: "localizedCaseInsensitiveCompare:")]
        }
    }
    
    var sectionNameKeyPath: String? {
        switch self {
        case .NameAscending:
            return "uppercaseFirstLetterOfName"
        case .TotalEnergyCalsDescending:
            return nil
        case .TotalCarbDescending:
            return nil
        case .TotalProteinDescending:
            return nil
        case .TotalFatDescending:
            return nil
        case .FattyAcidCholesterolDescending:
            return nil
        case .GroupThenSubGroupThenNameAscending:
            //            sectionNameKeyPath = "group.name"
            //            sectionNameKeyPath = "key"
            return "subGroup.name"
        }
    }
}
