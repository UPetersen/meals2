//
//  Meals2CDTVC.swift
//  meals
//
//  Created by Uwe Petersen on 31.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//
import Foundation

import UIKit
import CoreData
import HealthKit


@objc (MealsCDTVC) final class MealsCDTVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // Core Data
    var psContainer: NSPersistentContainer!
    var managedObjectContext: NSManagedObjectContext!
    // For speed reasons, only defaultFetchLimit meal ingredient objects are fetched
    // More data will be fetched automatically each time when the user scrolls to the end of the table view
    var defaultFetchLimit = 50                     // the number of objects normally fetched
    var defaultFetchLimitIncrement = 50            // the number of objects additionally fetched when more data is requested (user scrolls to end of table)
    
    // meal variable needed for actions on a meal.
    weak var currentMeal: Meal! // ingredients are added to this meal
    
    // HealthKit
    let healthManager: HealthManager = HealthManager()
    
    // Search controller to help us with filtering
    var searchController = UISearchController(searchResultsController: nil) // Searchresults are displayed in this tableview
    var searchFilter = SearchFilter.BeginsWith
    var shortPredicate: NSPredicate?
    let sortDescriptor = NSSortDescriptor(key: "food.name", ascending: true) // sort ingredients by their food name
    
    // Formatters
    lazy var calsNumberFormatter: NumberFormatter =  {() -> NumberFormatter in
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.none
        numberFormatter.zeroSymbol = "0"
        return numberFormatter
    }()
    
    lazy var zeroMaxDigitsNumberFormatter: NumberFormatter =  {() -> NumberFormatter in
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
    
    // Segues
    enum SegueIdentifier: String {
        case ShowFoodDetailCDTVC     = "Segue MealsCDTVC to FoodDetailCDTVC"
        case ShowAddFoodTVC          = "Segue MealsCDTVC to AddFoodTVC"
        case ShowMealDetailTVC       = "Segue MealsCDTVC to MealDetailTVC"
        case ShowMealEditTVC         = "Segue MealsCDTVC to MealEditTVC"
        case ShowFavoriteSearchCDTVC = "Segue MealsCDTVC to FavoriteSearchCDTVC"
        case ShowGeneralSearchCDTVC  = "Segue MealsCDTVC to GeneralSearchCDTVC"
    }
    
    // View model
    struct NutrionText {
        var text: String?
        var detailText: String?
    }
    struct Section {
        let rows: [MealIngredient]?
        let meal: Meal?
    }
    var sections: [Section]?
    
    // MARK: - Fetched results controller
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        set {
            
            // Set new value for var _fetchedResultsController if not yet set or if new value differs from old value
            if  _fetchedResultsController == nil || _fetchedResultsController! != newValue {
                
                _fetchedResultsController = newValue;
                _fetchedResultsController!.delegate = self
                
                do {
                    try _fetchedResultsController!.performFetch()
                    print("\(#file), \(#function):")
                    print("   Successfully fetched \(String(describing: _fetchedResultsController?.fetchedObjects?.count)) objects for entity name \(String(describing: _fetchedResultsController?.fetchRequest.entityName)) and predicate \(String(describing: _fetchedResultsController?.fetchRequest.predicate)).")
                } catch let error as NSError {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    print("Unresolved error \(error), \(error.userInfo)")
                    print("Perform fetch failed. ")
                    print("FetchedResultsController is: \(String(describing: _fetchedResultsController?.description))")
                    abort()
                }
            }
        }
        get {
            if _fetchedResultsController == nil {
                print("This should not have happened: getter of fetchedResultsController called before initalized via its setter. ")
                fatalError()
            }
            return _fetchedResultsController!
        }
    }
    
    
    // MARK: - view controller initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initializes the fetched results controller. The tableView will display a list of mealIngredients.
        managedObjectContext = psContainer.viewContext
        fetchMeals()
        
        // set automatic row heights (could also be handled via tableView delegate
        tableView.estimatedRowHeight = CGFloat(44)
        tableView.rowHeight = UITableViewAutomaticDimension
        
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
        
        // long pressure recognizer, to display a menu for the meal seleted by a long press
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MealsCDTVC.longPress(_:)))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        // tap recognizer, to withdraw the keyboard when user taps somewhere outside
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(MealsCDTVC.tap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapRecognizer)
        
        // dismiss keyboard on drag
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set the toolbar and navigation bar. Does not work properly in viewDidLoad
        navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    
    // MARK: - UITableView delegate
    
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
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = UIColor.white
            headerView.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(14))
            headerView.textLabel?.textAlignment = NSTextAlignment.center
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // Footerview color and font
        view.tintColor = UIColor.gray
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textColor = UIColor.white
            footerView.textLabel?.font = UIFont.systemFont(ofSize: CGFloat(17))
        }
    }
    
    
    // MARK: - UITableView data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let meal = mealFor(section: section), let date = meal.dateOfCreation as Date? {
            return dateFormatter.string(from: date)
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let meal = mealFor(section: section) {
            let totalEnergyCals = Nutrient.dispStringForNutrientWithKey("totalEnergyCals", value: meal.doubleForKey("totalEnergyCals"), formatter: calsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalCarb    = Nutrient.dispStringForNutrientWithKey("totalCarb",    value: meal.doubleForKey("totalCarb"),    formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalProtein = Nutrient.dispStringForNutrientWithKey("totalProtein", value: meal.doubleForKey("totalProtein"), formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalFat     = Nutrient.dispStringForNutrientWithKey("totalFat",     value: meal.doubleForKey("totalFat"),     formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let carbFructose = Nutrient.dispStringForNutrientWithKey("carbFructose", value: meal.doubleForKey("carbFructose"), formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            let carbGlucose   = Nutrient.dispStringForNutrientWithKey("carbGlucose", value: meal.doubleForKey("carbGlucose"),  formatter: zeroMaxDigitsNumberFormatter, inManagedObjectContext: managedObjectContext) ?? ""
            var totalAmount = ""
            if let amount = meal.amount {
                totalAmount = zeroMaxDigitsNumberFormatter.string(from: amount) ?? ""
            }
            return totalEnergyCals + ", " + totalCarb + " KH, " + totalProtein + " Prot., " + totalFat + " Fett, " + carbFructose + " F, " + carbGlucose + " G, " + totalAmount + " g insg."
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let meal = fetchedResultsController.object(at: IndexPath(row: section, section: 0)) as? Meal, let mealIngredients = meal.ingredients {
            if let predicate = shortPredicate {
                let filteredeMealIngredients = mealIngredients.filtered(using: predicate)
                return filteredeMealIngredients.count
            } else {
                // In case of empty meal display an empty cell, thus increase by one
                if mealIngredients.count == 0 {
                    return 1
                }
                return mealIngredients.count
            }
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if let mealIngredient = mealIngredientFor(indexPath: indexPath) {
            // meal with meal ingredients
            let nutrionText = contentFor(mealIngredient: mealIngredient)
            cell = tableView.dequeueReusableCell(withIdentifier: "MealIngredient Cell", for: indexPath)
            cell.textLabel?.text = nutrionText.text
            cell.detailTextLabel?.text = nutrionText.detailText
            
        } else {
            // Empty meal without meal ingredients. Display placeholder cell
            cell = tableView.dequeueReusableCell(withIdentifier: "Empty Meal Cell", for: indexPath)
        }
        
        // Fetch another batch of data if user scrolled to end of table (i.e. title for header for last section requested).
        if indexPath.section >= defaultFetchLimit - 1 {
            defaultFetchLimit += defaultFetchLimitIncrement
            fetchMeals()
        }
        return cell
    }
    
    // The (one and only one empty) cell of an empty meal shall not show a reorder control.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if mealIngredientFor(indexPath: indexPath) == nil {
            return false // empty meal: has only placeholder cell which shall not be moved
        }
        if searchController.isActive {
            return false
        }
        return true // all other cells are meal ingredients and are okay to move
    }
    
    // Move a mealIngredient from one meal (i.e. section) to another meal (section)
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let mealIngredient = mealIngredientFor(indexPath: sourceIndexPath),
            let oldMeal = mealIngredient.meal,
            let newMeal = mealFor(section: destinationIndexPath.section) {
            print("BEFORE MOVE")
            print("Source meal:")
            print(oldMeal.description)
            print("Destiantion meal: ")
            print(newMeal.description)

            mealIngredient.meal = newMeal
            newMeal.dateOfLastModification = NSDate()
            oldMeal.dateOfLastModification = NSDate()
            healthManager.synchronize(newMeal, withSynchronisationMode: .update)
            healthManager.synchronize(oldMeal, withSynchronisationMode: .update) // old meal may have no ingredients and will be an empty meal then

            print("AFTER MOVE")
            print("Source meal:")
            print(oldMeal.description)
            print("Destiantion meal: ")
            print(newMeal.description)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            if let meal = mealFor(section: indexPath.section) {
                if let count = meal.ingredients?.count, count > 1 {
                    // The meal has more than just the meal ingredient that shall be deleted, so delete the meal ingredient and let the meal and the other meal ingredients persist
                    if let mealIngredient = mealIngredientFor(indexPath: indexPath) {
                        managedObjectContext.delete(mealIngredient)
                        healthManager.synchronize(meal, withSynchronisationMode: .update)
                    }
                } else {
                    // The meal has non ingredient at all or only the one ingredient that shall be deleted, thus delete the whole meal.
                    healthManager.synchronize(meal, withSynchronisationMode: .delete)
                    managedObjectContext.delete(meal)
                }
            }
        }
    }
    
    
    // MARK: - Helpers for UITableView data source
    
    func stringForNumber (_ number: NSNumber, formatter: NumberFormatter, divisor: Double) -> String {
        return (formatter.string(from: NSNumber(value: number.doubleValue / divisor)) ?? "nan")
    }
    
    // Check if last cell in table view is displayed on screen and if number of fetched objects exceeds the fetch limit. If so, fetch more data
    func needToFetchMoreData(for tableView: UITableView, withIndexPath indexPath: IndexPath) -> Bool {
        if indexPath.section == tableView.numberOfSections-1 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1 {
            if let fetchedObjects = self.fetchedResultsController.fetchedObjects, fetchedObjects.count >= defaultFetchLimit-1 {
                return true
            }
        }
        return false
    }
    
    func contentFor(mealIngredient: MealIngredient) -> NutrionText {
        
        let amountString:  String = stringForNumber(mealIngredient.amount!, formatter: oneMaxDigitsNumberFormatter, divisor: 1.0)
        
        let formatter = oneMaxDigitsNumberFormatter
        let totalEnergyCals = Nutrient.dispStringForNutrientWithKey("totalEnergyCals", value: mealIngredient.doubleForKey("totalEnergyCals"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
        let totalCarb    = Nutrient.dispStringForNutrientWithKey("totalCarb",    value: mealIngredient.doubleForKey("totalCarb"),    formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
        let totalProtein = Nutrient.dispStringForNutrientWithKey("totalProtein", value: mealIngredient.doubleForKey("totalProtein"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
        let totalFat     = Nutrient.dispStringForNutrientWithKey("totalFat",     value: mealIngredient.doubleForKey("totalFat"),     formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
        let carbFructose = Nutrient.dispStringForNutrientWithKey("carbFructose", value: mealIngredient.doubleForKey("carbFructose"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
        let carbGlucose  = Nutrient.dispStringForNutrientWithKey("carbGlucose", value: mealIngredient.doubleForKey("carbGlucose"),  formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
        
        return NutrionText(text: mealIngredient.food?.name,
                           detailText: amountString + " g, " + totalEnergyCals + ", " + totalCarb + " KH, " + totalProtein + " Prot., " + totalFat + " Fett, " + carbFructose + " Fruct., " + carbGlucose + " Gluc."
        )
    }

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) {
            switch segueIdentifier {
            case .ShowFoodDetailCDTVC:
                // Cell selected, i.e. a meal ingredient: show details of the corresponding food,
                // possibly add this food later to newest meal
                if let viewController = segue.destination as? FoodDetailCDTVC,
                    let cell = sender as? UITableViewCell,
                    let indexPath = self.tableView.indexPath(for: cell),
                    let mealIngredient = mealIngredientFor(indexPath: indexPath),
                    let food = mealIngredient.food,
                    let meal = Meal.fetchNewestMeal(managedObjectContext: managedObjectContext) {
                    viewController.item = .isFood(food, meal)
                }
            case .ShowAddFoodTVC: // Accessory button selected, i. e. a Meal ingredient: change amount of the meal ingredient
                if let viewController = segue.destination  as? AddFoodTVC,
                    let cell = sender as? UITableViewCell,
                    let indexPath = self.tableView.indexPath(for: cell),
                    let mealIngredient = mealIngredientFor(indexPath: indexPath) {
                    viewController.item = .isMealIngredient(mealIngredient)
                }
            case .ShowFavoriteSearchCDTVC:
                if let viewController = segue.destination as? FavoriteSearchCDTVC  {
                    viewController.foodListType = FoodListType.Favorites
                    viewController.managedObjectContext = managedObjectContext
                    if let meal = Meal.fetchNewestMeal(managedObjectContext: managedObjectContext) {
                        viewController.meal = meal
                    }
                }
            case .ShowGeneralSearchCDTVC:
                if let viewController = segue.destination as? GeneralSearchCDTVC {
                    viewController.foodListType = FoodListType.Favorites // must be favorites, I don't understand why, yet.
                    viewController.managedObjectContext = managedObjectContext
                    if let meal = Meal.fetchNewestMeal(managedObjectContext: managedObjectContext) {
                        viewController.meal = meal
                    }
                }
            case .ShowMealEditTVC:
                if let viewController = segue.destination as? MealEditTVC {
                    viewController.meal = currentMeal
                    viewController.managedObjectContext = managedObjectContext
                    viewController.healthManager = healthManager
                }
            case .ShowMealDetailTVC:
                if let viewController = segue.destination as? MealDetailTVC {
                    viewController.meal = currentMeal
                    viewController.managedObjectContext = managedObjectContext
                }
            }
        }
    }
    
    // MARK: - toolbar (items not handled by direct segues)
    
    
    @IBAction func addButtonSelected(_ sender: UIBarButtonItem) {
        // Create a new Meal
        let meal = Meal(context: managedObjectContext)
        fetchMeals()
        saveContext() // Needed for synchronisation with health with URI of managed object
        healthManager.synchronize(meal, withSynchronisationMode: .save)
    }
    
    
    // MARK: - gesture recognizers
    
    @objc func tap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        self.searchController.searchBar.resignFirstResponder()
    }
    
    @objc func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            if let meal = mealSelectedByLongPressGestureRecognizer(longPressGestureRecognizer) {
                present(alertControllerForMeal(meal: meal), animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: - meal options menu (alert action sheet) for swipe and long press
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = contextualMealOptionsAction(forRowAtIndexPath: indexPath)
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func contextualMealOptionsAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Mahlzeit-Optionen") {  [unowned self]  (contextaction: UIContextualAction, sourceView: UIView, completionHandler:  (Bool) -> Void) in
            print("Starting up Meal menu")
            if let meal = self.mealFor(section: indexPath.section) {
                self.present(self.alertControllerForMeal(meal: meal), animated: true, completion: nil)
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
        return action
    }
    
    func alertControllerForMeal(meal: Meal) -> UIAlertController {
        let alertController = UIAlertController(title: "Mahlzeit", message: "Optionen für die ausgewählte Mahlzeit.", preferredStyle: .actionSheet)
        alertController.addAction( UIAlertAction(title: "Löschen", style: .destructive) {[unowned self] action in self.deleteMeal(meal) })
        alertController.addAction( UIAlertAction(title: "Nährwerte anzeigen", style: .default) {[unowned self] action in self.mealDetail(meal) })
        alertController.addAction( UIAlertAction(title: "Kopieren", style: .default) {[unowned self] action in self.copyMeal(meal)} )
        alertController.addAction( UIAlertAction(title: "Ändern (Datum/Kommentar)", style: .default) {[unowned self] (action) in self.editMeal(meal) })
        alertController.addAction( UIAlertAction(title: "Health autorisieren", style: .default) {[unowned self] (action) in self.authorizeHealthKit() })
        alertController.addAction( UIAlertAction(title: "Rezept hieraus erstellen", style: .default) {[unowned self] (action) in self.createRecipe(meal) })
        alertController.addAction( UIAlertAction(title: "Zurück", style: .cancel) {action in print("Cancel Action")})
        return alertController
    }
    
    
    // MARK: - Actions on the meal via long press gesture Recognizer
    
    func mealSelectedByLongPressGestureRecognizer(_ longPressGestureRecognizer: UIGestureRecognizer) -> Meal? {
        let touchPoint = longPressGestureRecognizer.location(in: self.view)
        if let indexPath = tableView.indexPathForRow(at: touchPoint) {
            return mealFor(section: indexPath.section)
        }
        return nil
    }
    
    func deleteMeal(_ meal: Meal) {
        // aks user if he really wants to delete the meal using an alert controller
        let alert = UIAlertController(title: "Mahlzeit löschen?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Zurück", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Löschen", style: UIAlertActionStyle.destructive) { [unowned self] (action) in
            print("Will delete the meal \(meal)")
            self.managedObjectContext.delete(meal)
            self.healthManager.synchronize(meal, withSynchronisationMode: .delete)
        })
        present(alert, animated: true, completion: nil)
    }
    
    func mealDetail(_ meal: Meal) {
        currentMeal = meal
        performSegue(withIdentifier: SegueIdentifier.ShowMealDetailTVC.rawValue, sender: self)
    }
    
    func copyMeal(_ meal: Meal) {
        print("Will copy the meal \(meal) and make it the current meal")
        if let newMeal = Meal.fromMeal(meal, inManagedObjectContext: managedObjectContext) {
            saveContext() // Needed for synchronisation with health with URI of managed object
            healthManager.synchronize(newMeal, withSynchronisationMode: .save)
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true); // scrolls to top
        }
    }
    
    func editMeal(_ meal: Meal) {
        currentMeal = meal
        performSegue(withIdentifier: SegueIdentifier.ShowMealEditTVC.rawValue, sender: self)
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
    
    func createRecipe(_ meal: Meal) {
        _ = Recipe.fromMeal(meal, inManagedObjectContext: managedObjectContext)
    }
    
    
    
    // MARK: - fetched results controller and helpers
    
    /// Fetches meals from database using a fetchedResultsController.
    ///
    /// - Warning:
    /// The objects of the fetchedResultsController is an array of meals (i.e. the rows). There are no sections.
    /// In the tableView constructed thereof, there will be one section for each meal and the rows of these sections will contain the meal ingredients.
    /// So BEWARE when construction the tableView and using data from the fetchedResultsController, since the index paths have different meanings:
    /// ````
    /// +--------------------------+----------------------------------+
    /// | fetchedResultsController |             tableView            |
    /// |--------------------------+----------------------------------+
    /// |    sections: none        |                                  |
    /// |    rows:     meals --------> sections: meals                |
    /// |                          |   rows: ingredients of the meals |
    /// + -------------------------+----------------------------------+
    /// ````
    /// - Important:
    /// The fetchedResultsController observes changes of meals, that includes adding, deletion and movement of their ingredients, but not changes in the amount of a meal ingredient. To automatically have this handled by the fetchedResultsController the dateOfLastModification of a meal is updated whenever the amount of a mealIngredient is changed. This is an importand convention. The change of properties of a meal ingredient's food is not automatically handled and does not fire the fetchedResultsController.
    func fetchMeals() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Meal")
        
        // Predicates: one for 
        request.predicate = searchFilter.predicateForMealsWithIngredientsWithSearchText(self.searchController.searchBar.text)
        shortPredicate = searchFilter.shortPredicateForMealsWithIngredientsWithSearchText(searchController.searchBar.text)

        // Performance optimation for reading and saving of data
        request.fetchBatchSize = 50
        request.fetchLimit = defaultFetchLimit  // Speeds up a lot, especially inital loading of this view controller, but needs care
        request.returnsObjectsAsFaults = true   // objects are only loaded, when needed/used -> faster but more frequent disk reads
        request.includesPropertyValues = true   // usefull only, when only relevant properties are read
        request.propertiesToFetch = ["dateOfCreation"] // read only certain properties (others are fetched automatically on demand)
        request.relationshipKeyPathsForPrefetching = ["ingredients", "food"]
//        request.relationshipKeyPathsForPrefetching = ["ingredients.amount", "ingredients.food.name",  "ingredients.food.totalEnergyCals", "ingredients.food.totalCarb", "ingredients.food.totalProtein", "ingredients.food.totalFat", "ingredients.food.carbFructose", "ingredients.food.carbGlucose"]
        request.sortDescriptors = [NSSortDescriptor(key: "dateOfCreation", ascending: false)]
        
        self.saveContext() // Unfortunately only works with saving before fetching, see https://stackoverflow.com/questions/42071379/core-data-warning-when-saving-child-moc
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Populate the view model
        updateSections()
        tableView.reloadData()
    }
    
    func updateSections() {
        sections = nil // reset the view model
        if let meals = fetchedResultsController.fetchedObjects as? [Meal] {
            sections = [Section]()
            for meal in meals {
                if let section = sectionForMeal(meal: meal, sortDescriptor: sortDescriptor, predicate: shortPredicate) {
                    sections?.append(section)
                }
            }
        }
    }
    
    func updateSectionAt(section: Int) {
        if let meal = mealFor(section: section), let theSection = sectionForMeal(meal: meal, sortDescriptor: sortDescriptor, predicate: shortPredicate)  {
            sections?[section] = theSection
        }
    }
    
    func sectionForMeal(meal: Meal, sortDescriptor: NSSortDescriptor, predicate: NSPredicate?) -> Section? {
        if let mealIngredients = meal.ingredients {
            // Meal has meal ingredients.
            var filteredAndSortedMealIngredients = mealIngredients
            // Filter if a predicate is given (text in searchbar), which needs NSSet.
            if let predicate = shortPredicate {
                filteredAndSortedMealIngredients = mealIngredients.filtered(using: predicate) as NSSet
            }
            // Sort thereafter and store in view model
            if let filteredAndSortedMealIngredients = filteredAndSortedMealIngredients.sortedArray(using: [sortDescriptor]) as? [MealIngredient] {
                return Section(rows: filteredAndSortedMealIngredients, meal: meal)
            }
        } else {
            // Meal is empty (i.e. has no meal ingredients). Store in view model
            return Section(rows: nil, meal: meal)
        }
        return nil
    }
    
    
    // MARK: - fetchedResultsController delegate
    
        // Changes in the model (i.e. the fetchedResultsController) are reported here. Use this information to change the view model respectively.
    // BEWARE: the fetched results controller returns zero sections and n rows for n meals. From this the tableView is generated with
    // these meal rows as sections.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .delete: // meal deleted
            if let indexPath = indexPath, let _ = mealFor(section: indexPath.row) {
                sections?.remove(at: indexPath.row)
            }
        case .insert: // new meal created, called once for this new meal
            if let indexPath = newIndexPath, let meal = mealFor(section: indexPath.row),
                let section = sectionForMeal(meal: meal, sortDescriptor: sortDescriptor, predicate: shortPredicate) {
                sections?.insert(section, at: indexPath.row)
            }
        case .move: // meal moved due to change of dateOfCreation
            if let indexPath = indexPath, let _ = mealFor(section: indexPath.row) {
                updateSectionAt(section: indexPath.row)
            }
            if let indexPath = newIndexPath, let _ = mealFor(section: indexPath.row) {
                updateSectionAt(section: indexPath.row)
            }
        case .update: // meal changed, i.e. new, moved or removed ingredient or changed comment or changed dateOfLastModification (called twice in case of a move of a meal ingredients, since two meals are affected by this operation)
            if let indexPath = indexPath {
                updateSectionAt(section: indexPath.row)
            }
        }
    }

    // When all changes of fetchedResultsController are done and the view model (sections) are changed respectively: reload the tableView.
    // Thus, meal (section) headers and footers are recalculated and displayed
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }

    
    // MARK: - Helpers
    
    /// Meal from fetchedResultsController.
    /// - Warning
    ///   IndexPath is the index path for the fetched results controller (zero sections, n rows that represent the meals),
    ///   not for the table view (n sections for the meals and therein rows for the respective meal ingredients).
    ///
    /// - Parameter indexPath: IndexPath of the fetchedResultsController (zero sections, n rows that represent the meals).
    /// - Returns: The meal if one exists or nil.
    func  mealFor(indexPath: IndexPath) -> Meal? {
        if let count = fetchedResultsController.fetchedObjects?.count,
            let meal = fetchedResultsController.fetchedObjects?[indexPath.section] as? Meal,
            indexPath.section < count {
            return meal
        }
        return nil
    }
    
    /// Meal from fetchedResultsController for a section of the table view.
    /// - Warning
    ///   Section is the section of the tableview (n sections for the meals and therein rows for their meal ingredients)
    ///  which actually corresponds to a row of the fetched results controller (zero sections, n rows that represent the meals).
    ///
    /// - Parameter section: Section of the table view (n sections for the meals and therein rows for the respective meal ingredients).
    /// - Returns: The meal if one exists or nil.
    func mealFor(section: Int) -> Meal? {
        if let count = fetchedResultsController.fetchedObjects?.count,
            let meal = fetchedResultsController.fetchedObjects?[section] as? Meal,
            section < count {
            return meal
        }
        return nil
//        if let sections = sections {
//            return sections[section].meal
//        }
//        return nil
    }
    
    /// Meal ingredient for index path of table view.
    ///
    /// - Parameter indexPath: Index path of table view (n sections for the meals and therein rows for the respective meal ingredients).
    /// - Returns: The meal ingredient if one exists or nil.
    func mealIngredientFor(indexPath: IndexPath) -> MealIngredient? {
        if let sections = sections {
            if let mealIngredients = sections[indexPath.section].rows {
                if mealIngredients.count == 0 {
                    return nil
                } else {
                    if let meal = mealIngredients.first?.meal {
                        print(meal.description)
                    }
                    return mealIngredients[indexPath.row]
                }
            }
        }
        return nil
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


// MARK: - Search extension

extension MealsCDTVC: UISearchResultsUpdating, UISearchBarDelegate {
    
    
    // MARK: - Search results updating protocol
    
    func updateSearchResults(for searchController: UISearchController) {
        self.fetchMeals()
    }
    
    
    // MARK: - search bar delegate protocol
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true) // no editing in search mode 
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch selectedScope {
        case 0:
            searchFilter = SearchFilter.BeginsWith
        case 1:
            searchFilter = SearchFilter.Contains
        default:
            searchFilter = SearchFilter.BeginsWith
        }
        self.fetchMeals()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true); // scrolls to top
    }

}

