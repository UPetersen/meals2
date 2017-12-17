//
//  BaseSearchCDTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 18.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc class BaseSearchCDTVC : BaseCDTVCWithTableIndex, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    var managedObjectContext: NSManagedObjectContext!
    
    // Search controller to help us with filtering.
    var searchController = UISearchController(searchResultsController: nil) // Searchresults are displayed in this tableview
    var searchFilter = SearchFilter.BeginsWith
    var searchText: String? = nil
    
    // for fetched results controller
    var sectionNameKeyPath: String? = nil
    
    // foodListType and FoodListSortRule which can be changed via toolbar
    var foodListType = FoodListType.Favorites
    var foodListSortRule = FoodListSortRule.NameAscending
    // Buttons for toolbar
    @IBOutlet weak var foodListTypeButton: UIBarButtonItem!
    @IBOutlet weak var foodListSortRuleButton: UIBarButtonItem!
    

    
    // Mark: - View Controller
    

    // MARK: - Search results updating protocol
    
    func updateSearchResults(for searchController: UISearchController) {
        self.fetchFoods()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Lebensmittel suchen", comment: "")
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = [SearchFilter.BeginsWith.rawValue, SearchFilter.Contains.rawValue]
        definesPresentationContext = true
        navigationItem.searchController = searchController // iOS 11: searchController tied to navigationItem
        //        tableView.tableHeaderView = searchController.searchBar // iOS 10 and lower, not adressed any more
        
        
        // configure toolbar buttons
        foodListTypeButton.title = foodListType.rawValue + " ▾"
        foodListSortRuleButton.title = foodListSortRule.rawValue + " ▾"
        
        // display edit button only for favorites (to let user delete food out of list of favorites)
        if foodListType == .Favorites {
            self.navigationItem.rightBarButtonItem = self.editButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = nil
            self.setEditing(true, animated: true)
        }
        
        // title shows food list type and in braces the sort rule, e.g. "Favoriten (Name)"
        self.title = self.foodListType.rawValue
        
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
    }
    

    // MARK: - UITableViewDelegate (for automatic row heights)
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.foodListType == .Favorites ? true : false  // only in for favorites it is possible to edit rows
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // Delete favorite from list of favorite foods
            if let food = self.fetchedResultsController.object(at: indexPath) as? Food, let favorite = food.favoriteListItem {
                print("This is a Favorite food with name \(String(describing: favorite.food?.name)) and will now be deleted from the list of favorite foods. The food itself will nto be deleted from the database.")
                managedObjectContext.delete(favorite)
            }
        }
    }
    
    
    // MARK: - UISearchBar Delegate Protocoll
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0:
            searchFilter = SearchFilter.BeginsWith
        case 1:
            searchFilter = SearchFilter.Contains
        default:
            searchFilter = SearchFilter.BeginsWith
        }
        self.fetchFoods()
    }
    

    //MARK: - toolbar items and alert controller for foodListType and foodListSortRule
    
    @IBAction func doneButtonSelected(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func foodListTypeButtonSelected(_ sender: UIBarButtonItem) {
        let handler: ((UIAlertAction) -> Void)? = {[unowned self] action in
            self.foodListType = FoodListType(rawValue: action.title!)!         // set foodList from selected item
            self.foodListTypeButton.title = self.foodListType.rawValue + " ▾"  // set title accordingly
            self.fetchFoods()                                                  // fetch foods
            self.title = self.foodListType.rawValue
            
            // edit button only for favorites
            if self.foodListType == .Favorites {
                self.navigationItem.rightBarButtonItem = self.editButtonItem
            } else {
                self.navigationItem.rightBarButtonItem = nil
                self.setEditing(false, animated: true)
            }
        }
        
        let itemTitles = [FoodListType.Favorites, FoodListType.Recipes, FoodListType.LastWeek, FoodListType.OwnEntries, FoodListType.MealIngredients, FoodListType.BLS, FoodListType.All]
            .map{$0.rawValue}
        let alertController = UIAlertController.alertControllerForLists(title: "Auswahl", message: "Welche Auswahl an Lebensmitteln soll angezeigt bzw. genutzt werden?",
                                                                        itemTitles: itemTitles, fromBarButtonItem: sender, handler: handler)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func foodListSortRuleButtonSelected(_ sender: UIBarButtonItem) {
        let handler: ((UIAlertAction) -> Void)? = {[unowned self] action in
            self.foodListSortRule = FoodListSortRule(rawValue: action.title!)!  // set foodList from selected item
            self.foodListSortRuleButton.title = self.foodListSortRule.rawValue + " ▾"   // set title accordingly
            self.fetchFoods()                                           // fetch foods
            self.title = self.foodListType.rawValue
        }
        
        let itemTitles = [FoodListSortRule.NameAscending, FoodListSortRule.TotalEnergyCalsDescending, FoodListSortRule.TotalCarbDescending, FoodListSortRule.TotalProteinDescending, FoodListSortRule.TotalFatDescending, FoodListSortRule.FattyAcidCholesterolDescending, FoodListSortRule.GroupThenSubGroupThenNameAscending]
            .map{$0.rawValue}
        let alertController = UIAlertController.alertControllerForLists(title: "Sortierung", message: "Wonach soll die Auswahl an Lebensmitteln sortiert werden? Größte Werte werden zuerst angezeigt.",
                                                                        itemTitles: itemTitles, fromBarButtonItem: sender, handler: handler)
        
        present(alertController, animated: true, completion: nil)
    }
        
    
    // MARK: - Fetched results controller
    
    func fetchFoods() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Food")
        
        let predicates = [foodListType.predicate, searchFilter.predicateForSearchText(self.searchController.searchBar.text)].flatMap{$0}
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.sortDescriptors = foodListSortRule.sortDescriptors

        // Performance optimation for reading and saving of data
        request.fetchBatchSize = 10
        request.returnsObjectsAsFaults = true   // objects are only loaded, when needed/used -> faster but more frequent disk reads
        request.includesPropertyValues = true   // usefull only, when only relevant properties are read
        let propertiesToFetch = ["name", "group", "totalEnergyCals", "totalCarb", "totalProtein", "totalFat", "carbFructose", "carbGlucose"]   // read only certain properties (others are fetched automatically on demand)
        request.propertiesToFetch = propertiesToFetch

        
        // TODO: avoid the need of the following lines and fix the error with the "Ä" in the name
        sectionNameKeyPath = foodListSortRule.sectionNameKeyPath
        if foodListSortRule == FoodListSortRule.NameAscending && (foodListType == FoodListType.All || foodListType == FoodListType.BLS) {
            sectionNameKeyPath = nil
        }
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
        
        debugPrint("Fetched \(String(describing: self.fetchedResultsController.fetchedObjects?.count)) objects.")
    }
    
    
    // MARK: - Fetched results controller
    
    func predicatesForFetchRequest() -> NSPredicate? {
        let nonNilPredicates = [foodListType.predicate, searchFilter.predicateForSearchText(searchText)].flatMap{$0}
        if !nonNilPredicates.isEmpty {
            return NSCompoundPredicate(andPredicateWithSubpredicates: nonNilPredicates)
        }
        return nil
    }
    
}
