//
//  SearchFilter.swift
//  meals2
//
//  Created by Uwe Petersen on 14.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation

/// Search filter for searches in database
///
/// - BeginsWith: Searches for foods/ingredients whose name begin with the search text, e.g. "Ei" will list "Eier" but not "Speiseeis"
/// - Contains: Searchs for foods/ingredients whose name contains the search text, e.g. "Ei" will list both, "Eier" and "Speiseis".
enum SearchFilter: String {
    case BeginsWith = "Beginnt mit ..."
    case Contains = "Enthält ..."
    
    //    return NSPredicate(format: "name BEGINSWITH[c] %@", searchText)
    /// returns predicate for search text and corresponding selected scope bar item.
    ///
    /// - Parameter searchText: the search text of the search bar
    /// - Returns: a predicate for the fetch request 
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
    
    func predicateForMealOrRecipeIngredientsWithSearchText(_ searchText: String?) -> NSPredicate? {
        guard let searchText = searchText, !searchText.isEmpty else {
            return nil
        }
        switch self {
        case .BeginsWith:
            // Search foods where the name begins with the exact term given in the search bar text field
            return NSPredicate(format: "food.name BEGINSWITH[c] %@", searchText)
        case .Contains:
            // Search for foods where the name contains the words given in the search bar text field
            let wordsAndEmptyStrings: [String] = searchText.components(separatedBy: CharacterSet.whitespaces) // White space are components, too
            let predicate = NSPredicate(format: "length > 0")
            
            let words = wordsAndEmptyStrings.filter {predicate.evaluate(with: $0)}  // Now real text components only w/o the spaces
            print("The words in the search text: \(words)")
            
            // Loop over the components, build predicate for each one (word), functional way of creating an arry of predicates
            let subPredicates = words.map({word -> NSPredicate in NSPredicate(format: "food.name contains[c] %@", word)})
            
            return NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: subPredicates)
        }
    }
    
}
