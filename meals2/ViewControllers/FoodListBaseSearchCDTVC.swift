//
//  FoodListBaseSearchCDTVC.swift
//  meals
//
//  This VC enhances the FoodListBaseCDTVC by adding a search bar and adjusting the fetch request 
//  accordingly (it's predicate to be correct)
//
//  Created by Uwe Petersen on 15.09.15.
//  Copyright © 2015 Uwe Petersen. All rights reserved.
//
/*
import Foundation
import UIKit
import CoreData

@objc (FoodListBaseSearchCDTVC)  class FoodListBaseSearchCDTVC : FoodListBaseCDTVC, UISearchControllerDelegate {
//    @objc (FoodListBaseSearchCDTVC)  class FoodListBaseSearchCDTVC : FoodListBaseCDTVC, UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate {

    // Buttons for tool bar
    
//    var searchFilter = SearchFilter.BeginsWith
    var searchText: String? = nil
    
    
    // Mark: - View Controller
    
    override func viewWillAppear(_ animated: Bool) {

        // Initially show all foods, sorted by name ascending
        foodList = FoodListType.All
        sortList = FoodListSortRule.NameAscending
        
        // Show table view, even when user has not typed anything into the search field (needs
        // also to be called in updateSearchResultsForSearchController). Otherwhise one would
        // see the dimmed background of the presenting view controller.
        self.tableView.isHidden = false
        
        // dismiss keyboard when the user scrolls in the view
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        
        super.viewWillAppear(animated)
        
        self.presentingViewController?.navigationController?.isToolbarHidden = true
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    
//    override func viewDidDisappear(animated: Bool) {
//        //        debugPrint(self.navigationController?.viewControllers)
//        //        debugPrint(self.presentingViewController)
//        //        debugPrint(self.toolbarItems)
//        debugPrint(self.toolbarItems)
//        debugPrint(self.toolBarOfPresentingViewController)
//        debugPrint(self.presentingViewController?.toolbarItems)
//        debugPrint(self.presentingViewController?.navigationController?.toolbarHidden)
//        (self.presentingViewController as? MealsCDTVC)?.setToolbarItems((self.presentingViewController as? MealsCDTVC)?.theToolbarItems(), animated: true)
//        (self.presentingViewController as? MealsCDTVC)?.navigationController?.toolbar.hidden = false
//        debugPrint(self.toolbarItems)
//        debugPrint(self.toolBarOfPresentingViewController)
//        debugPrint(self.presentingViewController?.toolbarItems)
//        debugPrint(self.presentingViewController?.navigationController?.toolbarHidden)
//    }
    
    
    //MARK: - UISearchResultsUpdating Protcol
    
    override func updateSearchResults(for searchController: UISearchController) {
        print("In updateSearchResultsForSearchController, yet to be filled")
        print("Der Text: \(String(describing: searchController.searchBar.text))")
        
        searchText = searchController.searchBar.text
        fetchFoods()
        self.tableView.isHidden = false
        
        // hide table header view with foodListButton and sortListButton
        self.headerBarInitallyHidden = false
        
    }
    
    
    // MARK: - UISearchBar Delegate Protocoll
    
    
    override func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0:
            searchFilter = SearchFilter.BeginsWith
        case 1:
            searchFilter = SearchFilter.Contains
        default:
            searchFilter = SearchFilter.BeginsWith
        }
        fetchFoods()
    }
    
    
    // MARK: - Fetched results controller
    
    override func predicatesForFetchRequest() -> NSPredicate? {
        let nonNilPredicates = [foodList.predicate, searchFilter.predicateForSearchText(searchText)].flatMap{$0}
        if !nonNilPredicates.isEmpty {
            return NSCompoundPredicate(andPredicateWithSubpredicates: nonNilPredicates)
        }
        return nil
    }
    
}
*/
