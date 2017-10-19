//
//  FoodListBaseCDTVC.swift
//  meals
//
//  Created by Uwe Petersen on 14.09.15.
//  Copyright © 2015 Uwe Petersen. All rights reserved.
//

/*
import Foundation
import UIKit
import CoreData

@objc (FoodListBaseCDTVC)  class FoodListBaseCDTVC: BaseCDTVCWithTableIndex {
    
//    var meal: Meal!
    var managedObjectContext: NSManagedObjectContext!
    
    // Search controller to help us with filtering.
    var searchController = UISearchController(searchResultsController: nil) // Searchresults are displayed in this tableview
    var searchFilter = SearchFilter.BeginsWith
    
    // for fetched results controller
    var sectionNameKeyPath: String? = nil
    
    // For restauration of toolbar of the presenting view controller (when user clicks cancel)
    var toolBarOfPresentingViewController: UIToolbar? = nil

    // foodListType and FoodListSortRule which can be changed via toolbar
    var foodListType = FoodListType.Favorites
    var foodListSortRule = FoodListSortRule.NameAscending
    
    // Buttons for toolbar
    @IBOutlet weak var foodListTypeButton: UIBarButtonItem!
    @IBOutlet weak var foodListSortRuleButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Lebensmittel suchen", comment: "")
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = [SearchFilter.BeginsWith.rawValue, SearchFilter.Contains.rawValue]
        definesPresentationContext = true
        navigationItem.searchController = searchController // iOS 11: searchController tied to navigationItem
        //        tableView.tableHeaderView = searchController.searchBar // iOS 10 and lower, not adressed any more
        
        fetchFoods()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        title = titleFor(foodListType: foodListType, foodListSortRule: foodListSortRule)
        
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Favorite Cell", for: indexPath)
        let food = self.fetchedResultsController.object(at: indexPath) as? Food
        cell.textLabel?.text = food?.name
        return cell
    }
    
    
    // MARK: - Navigation
    
    
    
    // MARK: - Fetched results controller
    
    func fetchFoods() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Food")
        
        let predicates = [foodListType.predicate, searchFilter.predicateForSearchText(self.searchController.searchBar.text)].flatMap{$0}
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.sortDescriptors = foodListSortRule.sortDescriptors
        request.fetchBatchSize = 10
        
        // TODO: avoid the need of the following lines and fix the error with the "Ä" in the name
        sectionNameKeyPath = foodListSortRule.sectionNameKeyPath
        if foodListSortRule == FoodListSortRule.NameAscending && (foodListType == FoodListType.All || foodListType == FoodListType.BLS) {
            sectionNameKeyPath = nil
        }
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
        
        debugPrint("Fetched \(String(describing: self.fetchedResultsController.fetchedObjects?.count)) objects.")
    }
    
    
    //MARK: - toolbar and alert controller for foodListType and foodListSortRule
    
    @IBAction func foodListTypeButtonSelected(_ sender: UIBarButtonItem) {
        let handler: ((UIAlertAction) -> Void)? = {[unowned self] action in
            self.foodListType = FoodListType(rawValue: action.title!)!         // set foodList from selected item
            self.foodListTypeButton.title = self.foodListType.rawValue + " ▾"  // set title accordingly
            self.fetchFoods()                                                  // fetch foods
            self.title = self.titleFor(foodListType: self.foodListType, foodListSortRule: self.foodListSortRule)
            
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
            self.title = self.titleFor(foodListType: self.foodListType, foodListSortRule: self.foodListSortRule)
        }
        
        let itemTitles = [FoodListSortRule.NameAscending, FoodListSortRule.TotalEnergyCalsDescending, FoodListSortRule.TotalCarbDescending, FoodListSortRule.TotalProteinDescending, FoodListSortRule.TotalFatDescending, FoodListSortRule.FattyAcidCholesterolDescending, FoodListSortRule.GroupThenSubGroupThenNameAscending]
            .map{$0.rawValue}
        let alertController = UIAlertController.alertControllerForLists(title: "Sortierung", message: "Wonach soll die Auswahl an Lebensmitteln sortiert werden?",
                                                                        itemTitles: itemTitles, fromBarButtonItem: sender, handler: handler)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - helper stuff
    func titleFor(foodListType: FoodListType, foodListSortRule: FoodListSortRule) -> String {
        return self.foodListType.rawValue + " (\(foodListSortRule.rawValue))"
    }
    
}
*/
