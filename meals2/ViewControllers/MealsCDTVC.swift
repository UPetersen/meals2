//
//  MealsCDTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 08.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import HealthKit


enum Item {
    case isFood(Food, Meal?)
    case isMealIngredient(MealIngredient)
    case isHasNutrients(HasNutrients)
}

@objc (MealsCDTVC) final class MealsCDTVC : BaseCDTVC {
    
    enum SegueIdentifier: String {
        case ShowFoodDetailTVC      = "Segue MealsCDTVC to FoodDetailTVC"
        case ShowAddFoodTVC         = "Segue MealsCDTVC to AddFoodTVC"
        case ShowMealFormTVC        = "Segue MealsCDTVC to MealFormTVC"
        case ShowMealDetails        = "Segue MealsCDTVC to MealDetailTVC"
        case ShowFoodListListsCDTVC  = "Segue MealsCDTVC to FoodListListsCDTVC"
    }
    
    var persistentContainer: NSPersistentContainer!
    var managedObjectContext: NSManagedObjectContext!
    
    // For speed reasons, only defaultFetchLimit meal ingredient objects are fetched and the last cell displays the loadMoreDataText text
    var defaultFetchLimit = 200                      // the number of objects normally fetched
    let loadMoreDataText = "Alle Daten laden ..."   // text displayed in the last cell instead of meal ingredient data
    
    var currentMeal: Meal!
    var currentMealIngredient: MealIngredient!
    
    // HealthKit
    let healthManager: HealthManager = HealthManager()
    
    // Search controller to help us with filtering.
//    var searchController: UISearchController!
    
    // Secondary search results table view.
//    var resultsTableController: MealsCDTVCResultController!
    
    lazy var calsNumberFormatter: NumberFormatter =  {() -> NumberFormatter in
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.none
        numberFormatter.zeroSymbol = "0"
        return numberFormatter
    }()
    
    lazy var zeroMaxDigitsNumberFormatter: NumberFormatter =  {() -> NumberFormatter in
//        print("I am in the zero...NumberFormatter")
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.none
        numberFormatter.zeroSymbol = "0"
        return numberFormatter
    }()
    
    lazy var oneMaxDigitsNumberFormatter: NumberFormatter =  {() -> NumberFormatter in
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        numberFormatter.zeroSymbol = "0"
        return numberFormatter
    }()
    
    lazy var dateFormatter: DateFormatter = {() -> DateFormatter in
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d. MMM yyyy, HH:mm 'Uhr'"
        return dateFormatter
    }()
    

    // Mark: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initializes the fetched results controller. The tableView will display a list of mealIngredients.
        managedObjectContext = persistentContainer.viewContext
        fetchAllMealIngredients()
        
        // Code for adding searchBar
//        configureNewSearchController()
        
        // tapRecognizer, to display a menu for the meal seleted by a long press
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MealsCDTVC.longPress(_:)))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MealsCDTVC.updateThisTableView(_:)), name: NSNotification.Name(rawValue: "updateMealsCDTVCNotification"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // Set the toolbar and navigation bar. Does not work properly in viewDidLoad
        navigationItem.rightBarButtonItem = self.editButtonItem
        
        toolbarItems = self.theToolbarItems()
        //        navigationController?.toolbarItems = self.theToolbarItems()
        self.navigationController?.isToolbarHidden = false
        
        //        navigationController?.hidesBarsOnSwipe = true
        
        //        tableView.reloadData()
        fetchAllMealIngredients()
        setFirstMealAsCurrentMeal()
        
//        searchController.searchBar.showsScopeBar = true // 2017-09-25 test
    }
    
    
    // MARK: - UISearchController
    
//    func configureNewSearchController() {
//
//        // Create the search results view controller and use it for the `UISearchController`.
//        struct StoryboardConstants {
//            // The identifier string that corresponds to the `SearchResultsViewController`'s view controller defined in the main storyboard.
//            static let identifier = "SearchResultsViewControllerStoryboardIdentifier"
//        }
//        let searchResultsController = storyboard!.instantiateViewController(withIdentifier: StoryboardConstants.identifier) as! FoodListListsSearchCDTVC
//        //        let searchResultsController = navigationController?.storyboard?.instantiateViewControllerWithIdentifier(StoryboardConstants.identifier) as! SearchResultsViewController
//
//        // Create the search controller and make it perform the results updating.
//        searchController = UISearchController(searchResultsController: searchResultsController)
//        searchResultsController.managedObjectContext = managedObjectContext
//
//        searchController.searchResultsUpdater = searchResultsController
//        searchController.hidesNavigationBarDuringPresentation = false  // 2017-09-23: set from true to false to work on iOS 11
//
//        /*
//         Configure the search controller's search bar. For more information on
//         how to configure search bars, see the "Search Bar" group under "Search".
//         */
//        //        searchController.searchBar.searchBarStyle = .Minimal
//        searchController.searchBar.delegate = searchResultsController // needed to be notified when scope buttons changed
//        searchController.searchBar.sizeToFit()
//        searchController.searchBar.placeholder = NSLocalizedString("Lebensmittel suchen", comment: "")
//        searchController.searchBar.showsScopeBar = true  // 2017-09-25 test
//        searchController.searchBar.scopeButtonTitles = [SearchFilter.BeginsWith.rawValue, SearchFilter.Contains.rawValue]
//
//
//        // Include the search bar within the navigation bar.
//        //        navigationItem.titleView = searchController.searchBar
//        tableView.tableHeaderView = searchController.searchBar
//
//        // Search is now just presenting a view controller. As such, normal view controller
//        // presentation semantics apply. Namely that presentation will walk up the view controller
//        // hierarchy until it finds the root view controller or one that defines a presentation context.
//        definesPresentationContext = true // Sonst leere weiße Fläche unter searchBar
//    }
    

    
    // Uwi, 2015-09-11: these methods seem not to be needed
    //    func segmentedControlInSearchBar(searchBar: UISearchBar) -> UISegmentedControl? {
    //        return segmentedControlInViewHierarchy(view: searchBar)
    //    }
    //
    //    func segmentedControlInViewHierarchy(view view: UIView) -> UISegmentedControl? {
    //        if view is UISegmentedControl {
    //            return view as? UISegmentedControl
    //        }
    //        for subview in view.subviews {
    //            if let segmentedControl = self.segmentedControlInViewHierarchy(view: subview as UIView) { // recursion
    //                return segmentedControl
    //            }
    //        }
    //        return nil
    //    }
    //
    //    func setSegmentWidthsForSegmentedControl(segmentedControl: UISegmentedControl, width: Double) {
    //        for var index = 0; index < segmentedControl.numberOfSegments; ++index {
    //            segmentedControl.setWidth(CGFloat(width), forSegmentAtIndex: index)
    //        }
    //    }
    //
    
    // MARK: - Helper stuff: Notifications
    
    @objc func updateThisTableView(_ notification: Notification) {
        tableView.reloadData()
    }
    
    
    // MARK: - UITableViewDelegate methods for automatic row heights
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        //        return UITableViewAutomaticDimension
        return CGFloat(44)
    }
    
    // MARK: - UITableView colors for headers, footers and cells
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        // backgrond color for current meal (that is the first section)
        if indexPath.section == 0 {
            cell.backgroundColor = UIColor.clear
        } else {
            cell.backgroundColor = UIColor(white: 0.96, alpha: 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        // Headerview color and font
        view.tintColor = UIColor.gray
        let headerView = view as! UITableViewHeaderFooterView
        headerView.textLabel?.textColor = UIColor.white
        headerView.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(14))
        headerView.textLabel?.textAlignment = NSTextAlignment.center
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        // Footerview color and font
        view.tintColor = UIColor.gray
        let footerView = view as! UITableViewHeaderFooterView
        footerView.textLabel?.textColor = UIColor.white
        footerView.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(17))
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if let sectionInfo: NSFetchedResultsSectionInfo = self.fetchedResultsController.sections?[section] {
            if let mealIngredient: MealIngredient = sectionInfo.objects?.first as? MealIngredient,
                let date = mealIngredient.meal?.dateOfCreation as Date? {
                return dateFormatter.string(from: date)
            }
        }
        return super.tableView(tableView, titleForHeaderInSection: section) // For all other cases (including nil cases)
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        // Get the meal from the first mealIngredient (i.e. the first object in the section)
        if let mealIngredient: MealIngredient = self.fetchedResultsController.sections?[section].objects?.first as? MealIngredient, let meal: Meal = mealIngredient.meal {
            
            let totalEnergyCals = Nutrient.dispStringForNutrientWithKey("totalEnergyCals", value: meal.doubleForKey("totalEnergyCals"), formatter: calsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalCarb    = Nutrient.dispStringForNutrientWithKey("totalCarb",    value: meal.doubleForKey("totalCarb"),    formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalProtein = Nutrient.dispStringForNutrientWithKey("totalProtein", value: meal.doubleForKey("totalProtein"), formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalFat     = Nutrient.dispStringForNutrientWithKey("totalFat",     value: meal.doubleForKey("totalFat"),     formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let carbFructose = Nutrient.dispStringForNutrientWithKey("carbFructose", value: meal.doubleForKey("carbFructose"), formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let carbGlucose   = Nutrient.dispStringForNutrientWithKey("carbGlucose", value: meal.doubleForKey("carbGlucose"),  formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            
            let totalAmount = zeroMaxDigitsNumberFormatter.string(from: NSNumber(value: meal.amount as Double)) ?? ""
            
            return totalEnergyCals + ", " + totalCarb + " KH, " + totalProtein + " Prot., " + totalFat + " Fett, " + carbFructose + " F, " + carbGlucose + " G, " + totalAmount + " g insg."
        }
        return nil
    }
    
    func stringForNumber (_ number: NSNumber, formatter: NumberFormatter, divisor: Double) -> String {
        return (formatter.string(from: NSNumber(value: number.doubleValue / divisor)) ?? "nan")
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    /// Move a mealIngredient from one meal (i.e. section) to another meal (section)
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if let mealIngredient = self.fetchedResultsController.object(at: sourceIndexPath) as? MealIngredient, let oldMeal = mealIngredient.meal {

            if let destinationSectionInfo = self.fetchedResultsController.sections?[destinationIndexPath.section], let newMeal = (destinationSectionInfo.objects?.first as? MealIngredient)?.meal {
                
                mealIngredient.meal = newMeal
                healthManager.syncMealToHealth(newMeal)
                
                if oldMeal.ingredients != nil && oldMeal.ingredients!.count == 0 {
                    healthManager.deleteMeal(oldMeal)
                    managedObjectContext.delete(oldMeal) // delete the old meal, if it has no more meal ingredients
                    // Set new current meal, since the deleted meal might have been the current meal (easyest way ist just to set it, even if current meal was not deleted)
                    setFirstMealAsCurrentMeal()
                } else {
                    healthManager.syncMealToHealth(oldMeal)
                }
            }
        }
    }
    
    func setFirstMealAsCurrentMeal() {
        // Set the newest meal as current meal
        currentMeal =  Meal.fetchNewestMeal(managedObjectContext: managedObjectContext)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            if let mealIngredient = self.fetchedResultsController.object(at: indexPath) as? MealIngredient, let meal = mealIngredient.meal {
                if meal.ingredients!.count <= 1 {
                    // The meal ingredient's meal has just this last meal ingredient, thus delete the whole meal, the meal ingredient is automatically deleted via the cascade functionality of core data
                    healthManager.deleteMeal(meal)
                    managedObjectContext.delete(meal)
                    currentMeal =  Meal.fetchNewestMeal(managedObjectContext: managedObjectContext)
                } else {
                    // The meal ingredient's meal has more than just this meal ingredient, so just delete this meal ingredient and let the meal and the other meal ingredients persist
                    managedObjectContext.delete(mealIngredient)
                    healthManager.syncMealToHealth(meal)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return mealIngredientCellForTableView(tableView, atIndexPath: indexPath)
    }
    
    
    func mealIngredientCellForTableView(_ tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MealIngredient Cell", for: indexPath)
        
        // Falls letzte Zelle in letzter section: Display "Weitere Daten laden ..."
        if isLastCellInTableView(tableView, forIndexPath: indexPath) {
            cell.textLabel!.text = loadMoreDataText
            cell.detailTextLabel!.text = " "
            //            cell.accessoryType = UITableViewCellAccessoryType.None
            
        } else if let mealIngredient: MealIngredient = self.fetchedResultsController.object(at: indexPath) as? MealIngredient {
            cell.textLabel?.text = mealIngredient.food?.name
            
            let amountString:  String = stringForNumber(mealIngredient.amount!, formatter: oneMaxDigitsNumberFormatter, divisor: 1.0)
            
            let formatter = oneMaxDigitsNumberFormatter
            let totalEnergyCals = Nutrient.dispStringForNutrientWithKey("totalEnergyCals", value: mealIngredient.doubleForKey("totalEnergyCals"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalCarb    = Nutrient.dispStringForNutrientWithKey("totalCarb",    value: mealIngredient.doubleForKey("totalCarb"),    formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalProtein = Nutrient.dispStringForNutrientWithKey("totalProtein", value: mealIngredient.doubleForKey("totalProtein"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalFat     = Nutrient.dispStringForNutrientWithKey("totalFat",     value: mealIngredient.doubleForKey("totalFat"),     formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let carbFructose = Nutrient.dispStringForNutrientWithKey("carbFructose", value: mealIngredient.doubleForKey("carbFructose"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let carbGlucose  = Nutrient.dispStringForNutrientWithKey("carbGlucose", value: mealIngredient.doubleForKey("carbGlucose"),  formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            
            cell.detailTextLabel?.text = amountString + " g, " + totalEnergyCals + ", " + totalCarb + " KH, " + totalProtein + " Prot., " + totalFat + " Fett, " + carbFructose + " Fruct., " + carbGlucose + " Gluc."
            
            cell.showsReorderControl = true
        }
        return cell
    }
    
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        currentMealIngredient = self.fetchedResultsController.object(at: indexPath) as! MealIngredient
        performSegue(withIdentifier: SegueIdentifier.ShowAddFoodTVC.rawValue, sender: self)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // If last cell of tableView is selected and there are more cells, refetch table with all the data
        if isLastCellInTableView(tableView, forIndexPath: indexPath) && defaultFetchLimit != 0 {
            defaultFetchLimit = 0
            fetchAllMealIngredients()
            return
        } else {
            
            currentMealIngredient = self.fetchedResultsController.object(at: indexPath) as! MealIngredient
            performSegue(withIdentifier: SegueIdentifier.ShowFoodDetailTVC.rawValue, sender: self)
        }
    }
    
    func isLastCellInTableView(_ tableView: UITableView, forIndexPath indexPath: IndexPath) -> Bool {
        if indexPath.section == tableView.numberOfSections-1 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1 {
            return true
        }
        return false
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) {
//            switch segueIdentifier {
//            case .ShowFoodDetailTVC:
//                if let viewController = segue.destination  as? FoodDetailCDTVC {
//                    let myFood:Food
//                    if sender is FoodListListsSearchCDTVC {
//                        myFood = (sender as! FoodListListsSearchCDTVC).currentFood  // food selected in list of search results
//                    } else {
//                        myFood = currentMealIngredient.food  // food selectet in list of mealIngredients
//                    }
//                    viewController.item = .isFood(myFood, currentMeal)
//                }
//            case .ShowAddFoodTVC:
//                if let viewController = segue.destination  as? AmountSettingTVC { // Change amount of meal ingredient
//                    viewController.item = .isMealIngredient(currentMealIngredient)
//                }
//            case .ShowFoodListListsCDTVC:
//                if let viewController = segue.destination as? FoodListListsCDTVC {
//                    viewController.foodList = FoodListType.Favorites
//                    viewController.meal = currentMeal
//                    viewController.managedObjectContext = managedObjectContext
//                }
//            case .ShowMealFormTVC:
//                break
//            case .ShowMealDetails:
//                if let viewController = segue.destination as? MealDetailTVC {
//                    viewController.meal = currentMeal
//                    viewController.managedObjectContext = managedObjectContext
//                }
//            }
        } else {
            fatalError("Invalid segue identifier: \(String(describing: segue.identifier))")
        }
    }
    
    //MARK: - Fetchted results controller
    
    func fetchAllMealIngredients() {
        fetchMealIngredientsForPredicate(nil)
    }
    
    func fetchMealIngredientsForPredicate(_ predicate: NSPredicate?) {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MealIngredient")
//        let request = MealIngredient.fetchRequest()
        if predicate != nil {
            request.predicate = predicate
        }
        request.fetchBatchSize = 100
        request.includesPropertyValues = false
        request.returnsObjectsAsFaults = true
//        request.returnsObjectsAsFaults = false  // Speeds up a little bit in our case
        request.fetchLimit = defaultFetchLimit                 // Speeds up a lot, especially inital loading of this view controller, but needs care
        request.sortDescriptors = [
            NSSortDescriptor(key: "meal.dateOfCreation", ascending: false),
            NSSortDescriptor(key: "food.name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        
        
        self.saveContext() // Unfortunately only works with saving before fetching, see https://stackoverflow.com/questions/42071379/core-data-warning-when-saving-child-moc
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "meal.dateOfCreationAsString", cacheName: nil)

        // Make the newest meal the currentMeal (the one and only, to which foods are added)
        if let mealIngredient = self.fetchedResultsController.fetchedObjects?.first as? MealIngredient {
            currentMeal = mealIngredient.meal
            print("Did set current meal.")
        } else {
            currentMeal = nil
            print("Fetched zero objects and result is zero or nil.")
            print("Did set current meal to nil.")
        }
    }
    
    //MARK: - toolbar
    
    func theToolbarItems() -> [UIBarButtonItem] {
        //        self.navigationController?.toolbarHidden = false
        self.hidesBottomBarWhenPushed = false
        let favoriteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.bookmarks, target: self, action: #selector(MealsCDTVC.toolbarFavoriteButtonSelected))
        let flexibleSpace  = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        let fixedSpace     = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: self, action: nil)
        fixedSpace.width = 30
        //        let listButton     = UIBarButtonItem(title: "Listen", style: UIBarButtonItemStyle.Plain, target: self, action: "toolbarListButtonSelected")
        let addButton      = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(MealsCDTVC.toolbarAddButtonSelected))
        
        return [fixedSpace, favoriteButton, flexibleSpace, addButton, fixedSpace]
    }
    
    @objc func toolbarFavoriteButtonSelected() {
        print("Favorite Button selected")
        performSegue(withIdentifier: SegueIdentifier.ShowFoodListListsCDTVC.rawValue, sender: self)
    }
    
    //    func toolbarListButtonSelected() {
    //        print("List button selected")
    //        performSegueWithIdentifier(SegueIdentifier.ShowFoodListListsCDTVC.rawValue, sender: self)
    //    }
    
    @objc func toolbarAddButtonSelected() {
        print("Add Button selected")
        // Create a new Meal
        let meal = Meal(context: managedObjectContext)
        
        // Create one dummy food as a MealIngreident and add it to the meal
        let mealIngredient = MealIngredient(context: managedObjectContext)
        let dummyFood:Food? = Food.foodForNameContainingString("Knäckebrot", inMangedObjectContext: managedObjectContext)
        
        if dummyFood != nil {
            mealIngredient.food = dummyFood!
            mealIngredient.amount = 0
            mealIngredient.meal = meal
        }
        currentMeal = meal
        fetchAllMealIngredients()
        saveContext()
    }
    
    
    
    //MARK: - Action Sheet: Actions on the meal via long press gesture Recognizer
    
    @objc func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            
            if let meal = mealSelectedByLongPressGestureRecognizer(longPressGestureRecognizer) {
                
                print("Selected meal is \(meal)")
                
                let alertController = UIAlertController(title: "Mahlzeit", message: "Diese Mahlzeit bearbeiten", preferredStyle: .actionSheet)
                
                alertController.addAction( UIAlertAction(title: "Löschen", style: .destructive) {[unowned self] action in self.deleteMeal(meal) })
                alertController.addAction( UIAlertAction(title: "Nährwerte", style: .default) {[unowned self] action in self.mealDetail(meal) })
                alertController.addAction( UIAlertAction(title: "Kopieren", style: .default) {[unowned self] action in self.copyMeal(meal)} )
                alertController.addAction( UIAlertAction(title: "Ändern", style: .default) {[unowned self] (action) in self.editMeal(meal) })
                alertController.addAction( UIAlertAction(title: "HealthKit autorisieren", style: .default) {[unowned self] (action) in self.authorizeHealthKit() })
                alertController.addAction( UIAlertAction(title: "Zu Health übertragen", style: .default) {[unowned self] (action) in self.syncToHealth(meal) })
                alertController.addAction( UIAlertAction(title: "Alle Mahlzeiten zu Health übertragen", style: .default) {[unowned self] (action) in self.syncAllmealsToHealthKit() })
                alertController.addAction( UIAlertAction(title: "Mahlzeit nach Datum lesen", style: .default) {[unowned self] (action) in self.syncMealFromHealthKit(meal) })
                alertController.addAction( UIAlertAction(title: "Rezept hieraus", style: .default) {[unowned self] (action) in self.createRecipe(meal) })
                alertController.addAction( UIAlertAction(title: "Zurück", style: .cancel) {action in print("Cancel Action")})
                
                // For iPad only: must be popover and have a presentation controller
                alertController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen  // for iPad only
                alertController.popoverPresentationController?.sourceView = self.view
                alertController.popoverPresentationController?.sourceRect = CGRect(origin: longPressGestureRecognizer.location(in: longPressGestureRecognizer.view), size: CGSize(width: 1, height: 1))
                
                present(alertController, animated: true) {print("Presented Alert View Controller in \(#file)")}
            }
        }
    }
    
    func mealSelectedByLongPressGestureRecognizer(_ longPressGestureRecognizer: UIGestureRecognizer) -> Meal? {
        let touchPoint = longPressGestureRecognizer.location(in: self.view)
        if let indexPath = tableView.indexPathForRow(at: touchPoint) {
            print("IndexPath ist: \(indexPath)")
            if let mealIngredient = self.fetchedResultsController.object(at: indexPath) as? MealIngredient {
                print("Meal: \(String(describing: mealIngredient.meal))")
                return mealIngredient.meal
            }
        }
        return nil
    }
    
    func createRecipe(_ meal: Meal) {
        //        print("All recipes so far:")
        //        Recipe.fetchAllRecipes(managedObjectContext: managedObjectContext)
        //            .map{print("A recipe: \($0)")}
        
        _ = Recipe.fromMeal(meal, inManagedObjectContext: managedObjectContext)
        
        //        print("All recipes after having created a new one:")
        //        Recipe.fetchAllRecipes(managedObjectContext: managedObjectContext)
        //            .map{print("A recipe: \($0)")}
    }
    
    
    func deleteMeal(_ meal: Meal) {
        // aks user if he really wants to delete the meal using an alert controller
        let alert = UIAlertController(title: "Mahlzeit löschen?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Zurück", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Löschen", style: UIAlertActionStyle.destructive) { [unowned self] (action) in
            print("Will delete the meal \(meal)")
            self.managedObjectContext.delete(meal)})
        present(alert, animated: true, completion: nil)
    }
    
    func mealDetail(_ meal: Meal) {
        currentMeal = meal
        performSegue(withIdentifier: SegueIdentifier.ShowMealDetails.rawValue, sender: self)
    }
    
    func copyMeal(_ meal: Meal) {
        print("Will copy the meal \(meal) and make it the current meal")
        if let newMeal = Meal.fromMeal(meal, inManagedObjectContext: managedObjectContext) {
            currentMeal = newMeal
        }
    }
    
    func editMeal(_ meal: Meal) {
        currentMeal = meal
        performSegue(withIdentifier: SegueIdentifier.ShowMealFormTVC.rawValue, sender: self)
    }
    
    
    /// MARK: - HealthKit
    
    func syncToHealth(_ meal: Meal) {
        debugPrint("Deleting any old meal entries from health store")
        healthManager.deleteMeal(meal)
        debugPrint("Saving meal to health store ...")
        healthManager.saveMeal(meal)
        debugPrint("... finished saving meal to core data")
    }
    
    
    func authorizeHealthKit() {
        healthManager.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                print("HealthKit authorization received.")
            }
            else {
                print("HealthKit authorization denied!")
                if error != nil {
                    print("\(String(describing: error))")
                }
            }
        }
    }
    
    func syncAllmealsToHealthKit() {
        if let meals = Meal.fetchAllMeals(managedObjectContext: managedObjectContext) {
            for meal in meals {
                self.syncToHealth(meal)
            }
        }
    }
    
    func syncMealFromHealthKit(_ meal: Meal) {
        
        //        healthManager.syncMealFromHealthKit(meal)
        
        var dictionary = [String: Double?]()
        var energyConsumed: Double?
        var carbohydrates: Double?
        var protein: Double?
        var fatTotal: Double?
        
        // completion handler needed to get results back to main thread
        healthManager.readNutrientData(meal.dateOfCreation! as Date, completion: { (foodCorrelation , error) -> Void in
            
            if( error != nil ) {
                print("Error reading a meal from HealthKit Store: \(String(describing: error?.localizedDescription))")
                return;
            }
            
            // 3. Format the weight to display it on the screen
            if let foodCorrelation = foodCorrelation {
                for object in foodCorrelation.objects {
                    if let quantitySample = object as? HKQuantitySample {
                        switch quantitySample.quantityType {
                        case HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!:
                            energyConsumed = quantitySample.quantity.doubleValue(for: HKUnit.kilocalorie())
                            print("Energy: \(String(describing: energyConsumed)) in kcal")
                        case HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!:
                            carbohydrates = quantitySample.quantity.doubleValue(for: HKUnit.gram())
                        case HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!:
                            protein = quantitySample.quantity.doubleValue(for: HKUnit.gram())
                        case HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!:
                            fatTotal = quantitySample.quantity.doubleValue(for: HKUnit.gram())
                        default:
                            break
                        }
                        
                        print("Quantity Sample start data is \(quantitySample.startDate) and end date ist \(quantitySample.endDate)")
                    }
                }
            }
            
            print("The food correlation has the following metadata: \(String(describing: foodCorrelation?.metadata))")
            
            // 4. Update UI in the main thread (Nothing to update here)
            DispatchQueue.main.async(execute: { () -> Void in
                print("In the main queue")
                dictionary = ["energyConsumed": energyConsumed, "carbohydrates": carbohydrates, "protein": protein, "fatTotal": fatTotal]
                print("The dictionary in meals: \(String(describing: dictionary))")
            });
        });
        print("The dictionary in meals: \(String(describing: dictionary))")
    }
    
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }
    
}
