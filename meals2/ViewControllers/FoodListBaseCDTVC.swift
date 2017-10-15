//
//  FoodListBaseCDTVC.swift
//  meals
//
//  Created by Uwe Petersen on 14.09.15.
//  Copyright © 2015 Uwe Petersen. All rights reserved.
//
import Foundation
import UIKit
import CoreData

@objc (FoodListBaseCDTVC)  class FoodListBaseCDTVC: BaseCDTVCWithTableIndex {
    
//    var meal: Meal!
    var managedObjectContext: NSManagedObjectContext!
    
    // foodListType and FoodListSortRule which can be changed via toolbar
    var foodListType = FoodListType.Favorites
    var foodListSortRule = FoodListSortRule.NameAscending
    
    // Search controller to help us with filtering.
    var searchController = UISearchController(searchResultsController: nil) // Searchresults are displayed in this tableview
    var searchFilter = SearchFilter.BeginsWith
    


//    var sortRule = FoodListSortRule.NameAscending
    var sectionNameKeyPath: String? = nil
    
    // For restauration of toolbar of the presenting view controller (when user clicks cancel)
    var toolBarOfPresentingViewController: UIToolbar? = nil

    // Buttons for tool bar of this view controller
    var foodListButton = UIBarButtonItem()
    var sortListButton = UIBarButtonItem()
    
    // var to hide header view (that contains th foodListButton and the sorListButton
    // The header view shall be hidden initially and when the user enters letters into
    // the search field (he thus sees more entries of his list).
    // If the user scroll, the header view shall be visible
    var headerBarInitallyHidden = false // if true, header view is hidden
    
    
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
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // store tool bar of presenting view controller and set new tool bar
//        toolBarOfPresentingViewController = self.presentingViewController?.navigationController?.toolbar
//        self.presentingViewController?.navigationController?.toolbarHidden = true
        
        foodListTypeButton.title = foodListType.rawValue + " ▾"
        foodListSortRuleButton.title = foodListSortRule.rawValue + " ▾"
//        foodListButton.title = foodListType.rawValue + " ▾"
//        sortListButton.title = foodListSortRule.rawValue + " ▾"

//        toolbarItems = self.theToolbarItems()
//        self.navigationController?.setToolbarHidden(false, animated: true)
        
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        
        headerBarInitallyHidden = false

        fetchFoods()
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.navigationController?.isToolbarHidden = false
//        self.presentingViewController?.navigationController?.isToolbarHidden = false
//        if let oldToolBar = toolBarOfPresentingViewController,  let items = oldToolBar.items {
//            self.presentingViewController?.navigationController?.setToolbarItems(items, animated: false)
//        }
    }


    // Hide tableHeaderView if requested
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.headerBarInitallyHidden {
            if let tableHeaderView = self.tableView.tableHeaderView {
                self.tableView.contentOffset.y = tableHeaderView.frame.size.height - self.tableView.contentInset.top
                self.headerBarInitallyHidden = true
            }
        }
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
        let food = self.fetchedResultsController.object(at: indexPath) as! Food
        cell.textLabel!.text = food.name
        return cell
    }
    
    
    // MARK: - Navigation
    
    
    
    // MARK: - Fetched results controller
    
//    func predicatesForFetchRequest() -> NSPredicate? {
//        let nonNilPredicates = [foodList.predicate].flatMap{$0}
//        if !nonNilPredicates.isEmpty {
//            return NSCompoundPredicate(andPredicateWithSubpredicates: nonNilPredicates)
//        }
//        return nil
//    }
    
    func fetchFoods() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Food")
        
//        request.predicate = searchFilter.predicateForSearchText(self.searchController.searchBar.text)
////        request.predicate = searchFilter.predicateForMealOrRecipeIngredientsWithSearchText(self.searchController.searchBar.text)
//
//        if let predicate = predicatesForFetchRequest() {
//            request.predicate = predicate
//        }
        
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
    
    
    //MARK: - toolbar
    
    
    @IBOutlet weak var foodListTypeButton: UIBarButtonItem!
    @IBOutlet weak var foodListSortRuleButton: UIBarButtonItem!

    @IBAction func foodListTypeButtonSelected(_ sender: UIBarButtonItem) {
        let handler: ((UIAlertAction) -> Void)? = {[unowned self] action in
            self.foodListType = FoodListType(rawValue: action.title!)!     // set foodList from selected item
            self.foodListTypeButton.title = self.foodListType.rawValue + " ▾"  // set title accordingly
            self.fetchFoods()                                          // fetch foods
        }
        
        let itemTitles = [FoodListType.Favorites, FoodListType.Recipes, FoodListType.LastWeek, FoodListType.OwnEntries, FoodListType.MealIngredients, FoodListType.BLS, FoodListType.All]
            .map{$0.rawValue}
        let alertController = UIAlertController.alertControllerForLists(title: "Auswahl", message: "Welche Liste an Lebensmitteln soll angezeigt werden?",
                                                                        itemTitles: itemTitles, fromBarButtonItem: sender, handler: handler)
        
        present(alertController, animated: true) {print("Presented Alert View Controller in \(#file)")}

    }
    @IBAction func foodListSortRuleButtonSelected(_ sender: UIBarButtonItem) {
        let handler: ((UIAlertAction) -> Void)? = {[unowned self] action in
            self.foodListSortRule = FoodListSortRule(rawValue: action.title!)!  // set foodList from selected item
            self.foodListSortRuleButton.title = self.foodListSortRule.rawValue + " ▾"   // set title accordingly
            self.fetchFoods()                                           // fetch foods
        }
        
        let itemTitles = [FoodListSortRule.NameAscending, FoodListSortRule.TotalEnergyCalsDescending, FoodListSortRule.TotalCarbDescending, FoodListSortRule.TotalProteinDescending, FoodListSortRule.TotalFatDescending, FoodListSortRule.FattyAcidCholesterolDescending, FoodListSortRule.GroupThenSubGroupThenNameAscending]
            .map{$0.rawValue}
        let alertController = UIAlertController.alertControllerForLists(title: "Sortierung", message: "Wonach soll die Liste an Lebensmitteln sortiert werden?",
                                                                        itemTitles: itemTitles, fromBarButtonItem: sender, handler: handler)
        
        present(alertController, animated: true) {print("Presented Alert View Controller in \(#file)")}
    }
    
//    func theToolbarItems() -> [UIBarButtonItem] {
//        //        self.navigationController?.toolbarHidden = false
//        self.hidesBottomBarWhenPushed = false
//        foodListButton     = UIBarButtonItem(title: foodListType.rawValue + " ▾", style: UIBarButtonItemStyle.plain, target: self, action: #selector(FoodListBaseCDTVC.foodListButtonSelected(_:)))
//        sortListButton     = UIBarButtonItem(title: foodListSortRule.rawValue + " ▾", style: UIBarButtonItemStyle.plain, target: self, action: #selector(FoodListBaseCDTVC.sortListButtonSelected(_:)))
//        let flexibleSpace  = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
//
//        return [flexibleSpace, foodListButton, flexibleSpace, sortListButton, flexibleSpace]
//    }
    
    
    // MARK: - UIAlertController for foodList
    
    @objc func sortListButtonSelected(_ sender: AnyObject) {
        
//        let handler: ((UIAlertAction) -> Void)? = {[unowned self] action in
//            self.foodListSortRule = FoodListSortRule(rawValue: action.title!)!  // set foodList from selected item
//            self.sortListButton.title = self.foodListSortRule.rawValue + " ▾"   // set title accordingly
//            self.fetchFoods()                                           // fetch foods
//        }
//
//        let itemTitles = [FoodListSortRule.NameAscending, FoodListSortRule.TotalEnergyCalsDescending, FoodListSortRule.TotalCarbDescending, FoodListSortRule.TotalProteinDescending, FoodListSortRule.TotalFatDescending, FoodListSortRule.FattyAcidCholesterolDescending, FoodListSortRule.GroupThenSubGroupThenNameAscending]
//            .map{$0.rawValue}
//        let alertController = UIAlertController.alertControllerForLists(title: "Sortierung", message: "Wonach soll die Liste an Lebensmitteln sortiert werden?",
//            itemTitles: itemTitles, fromBarButtonItem: sender as? UIBarButtonItem, handler: handler)
//
//        present(alertController, animated: true) {print("Presented Alert View Controller in \(#file)")}
    }
    
    
    // MARK: - UIAlertController for sortRule
    
    @objc func foodListButtonSelected(_ sender: AnyObject) {
        
//        let handler: ((UIAlertAction) -> Void)? = {[unowned self] action in
//            self.foodListType = FoodListType(rawValue: action.title!)!     // set foodList from selected item
//            self.foodListButton.title = self.foodListType.rawValue + " ▾"  // set title accordingly
//            self.fetchFoods()                                          // fetch foods
//        }
//
//        let itemTitles = [FoodListType.Favorites, FoodListType.Recipes, FoodListType.LastWeek, FoodListType.OwnEntries, FoodListType.MealIngredients, FoodListType.BLS, FoodListType.All]
//            .map{$0.rawValue}
//        let alertController = UIAlertController.alertControllerForLists(title: "Auswahl", message: "Welche Liste an Lebensmitteln soll angezeigt werden?",
//            itemTitles: itemTitles, fromBarButtonItem: sender as? UIBarButtonItem, handler: handler)
//
//        present(alertController, animated: true) {print("Presented Alert View Controller in \(#file)")}
        
    }
}
