//
//  MealsCDTVCSearchExtension.swift
//  meals2
//
//  Created by Uwe Petersen on 14.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit

extension MealsCDTVC: UISearchResultsUpdating, UISearchBarDelegate {
    
    // MARK: - Search results updating protocol
    
    func updateSearchResults(for searchController: UISearchController) {
        self.fetchMealIngredients()
    }
    
    // MARK: - search bar delegate protocol
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0:
            searchFilter = SearchFilter.BeginsWith
        case 1:
            searchFilter = SearchFilter.Contains
        default:
            searchFilter = SearchFilter.BeginsWith
        }
        self.fetchMealIngredients()
    }
    
}
