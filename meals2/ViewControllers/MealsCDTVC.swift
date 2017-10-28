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


@objc final class MealsCDTVC : BaseCDTVC {
    
    enum SegueIdentifier: String {
        case ShowFoodDetailCDTVC     = "Segue MealsCDTVC to FoodDetailCDTVC"
        case ShowAddFoodTVC          = "Segue MealsCDTVC to AddFoodTVC"
        case ShowMealDetailTVC       = "Segue MealsCDTVC to MealDetailTVC"
        case ShowMealEditTVC         = "Segue MealsCDTVC to MealEditTVC"
        case ShowFavoriteSearchCDTVC = "Segue MealsCDTVC to FavoriteSearchCDTVC"
        case ShowGeneralSearchCDTVC  = "Segue MealsCDTVC to GeneralSearchCDTVC"
    }
    
    var persistentContainer: NSPersistentContainer!
    var managedObjectContext: NSManagedObjectContext!
    
    // For speed reasons, only defaultFetchLimit meal ingredient objects are fetched
    // More data will be fetched automatically each time when the user scrolls to the end of the table view
    var defaultFetchLimit = 50                     // the number of objects normally fetched
    var defaultFetchLimitIncrement = 50            // the number of objects additionally fetched when more data is requested
    let loadMoreDataText = "Alle Daten laden ..."   // text displayed in the last cell instead of meal ingredient data
    
    weak var currentMeal: Meal!
    
    // HealthKit
    let healthManager: HealthManager = HealthManager()
    
    // Search controller to help us with filtering.
    var searchController = UISearchController(searchResultsController: nil) // Searchresults are displayed in this tableview
    var searchFilter = SearchFilter.BeginsWith

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
    

    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initializes the fetched results controller. The tableView will display a list of mealIngredients.
        managedObjectContext = persistentContainer.viewContext
        fetchMealIngredients()
        
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
        
        // Notification, to enable update of this table view from a child table view (i.e. when a food is added to a meal, this tableview changes it's content)
        NotificationCenter.default.addObserver(self, selector: #selector(MealsCDTVC.updateThisTableView(_:)), name: NSNotification.Name(rawValue: "updateMealsCDTVCNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MealsCDTVC.contextUpdated(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set the toolbar and navigation bar. Does not work properly in viewDidLoad
        navigationItem.rightBarButtonItem = self.editButtonItem
        
        setFirstMealAsCurrentMeal()
    }

    
    // MARK: - Notifications
    
    // Trial to handle updates in relevant meals via observing changes in the context that are related to meals or mealingredients or just the very meal or meal ingredient. If so, one would refetch the data and reload the table view. But this can also be handled more simply without observing the context, but with the updatedThisTableView-Notificaton
    @objc func contextUpdated(_ notification: Notification) {
        print(notification)
    }
    
    @objc func updateThisTableView(_ notification: Notification) {
//        tableView.reloadData()
        fetchMealIngredients()
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
            var totalAmount = ""
            if let amount = meal.amount {
                totalAmount = zeroMaxDigitsNumberFormatter.string(from: amount) ?? ""
            }
//            let totalAmount = zeroMaxDigitsNumberFormatter.string(from: NSNumber(value: meal.amount as Double)) ?? ""

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
        if needToFetchMoreData(for: tableView, withIndexPath: indexPath) {
            defaultFetchLimit += defaultFetchLimitIncrement
            fetchMealIngredients() 
        }
        return mealIngredientCellForTableView(tableView, atIndexPath: indexPath)
    }
    
    // Check if last cell in table view is displayed on screen and if number of fetched objects exceeds the fetch limit. If so, fetch more data
    func needToFetchMoreData(for tableView: UITableView, withIndexPath indexPath: IndexPath) -> Bool {
        if indexPath.section == tableView.numberOfSections-1 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1 {
            if let fetchedObjects = self.fetchedResultsController.fetchedObjects, fetchedObjects.count >= defaultFetchLimit-1 {
                return true
            }
//            return true
        }
        return false
    }
    
    
    func mealIngredientCellForTableView(_ tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MealIngredient Cell", for: indexPath)
        
        if let mealIngredient: MealIngredient = self.fetchedResultsController.object(at: indexPath) as? MealIngredient {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) {
            switch segueIdentifier {
            case .ShowFoodDetailCDTVC: // Cell selected, i.e. a meal ingredient: show details of the corresponding food
                debugPrint(segue.destination)
                if let viewController = segue.destination as? FoodDetailCDTVC,
                    let cell = sender as? UITableViewCell,
                    let indexPath = self.tableView.indexPath(for: cell),
                    let currentMealIngredient = self.fetchedResultsController.object(at: indexPath) as? MealIngredient,
                    let food = currentMealIngredient.food {
                        viewController.item = .isFood(food, currentMeal)
                }
            case .ShowAddFoodTVC: // Accessory button selected, i. e. a Meal ingredient: change amount of the meal ingredient
                if let viewController = segue.destination  as? AddFoodTVC,
                    let cell = sender as? UITableViewCell,
                    let indexPath = self.tableView.indexPath(for: cell),
                    let currentMealIngredient = self.fetchedResultsController.object(at: indexPath) as? MealIngredient {
                    viewController.item = .isMealIngredient(currentMealIngredient)
                }
            case .ShowFavoriteSearchCDTVC:
                if let viewController = segue.destination as? FavoriteSearchCDTVC {
                    viewController.foodListType = FoodListType.Favorites
                    viewController.meal = currentMeal
                    viewController.managedObjectContext = managedObjectContext
                }
            case .ShowGeneralSearchCDTVC:
                if let viewController = segue.destination as? GeneralSearchCDTVC {
                    viewController.foodListType = FoodListType.Favorites
                    viewController.meal = currentMeal
                    viewController.managedObjectContext = managedObjectContext
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
    
    //MARK: - toolbar (items not handled by direct segues)
    
    
    @IBAction func addButtonSelected(_ sender: UIBarButtonItem) {
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
        fetchMealIngredients()
        saveContext()
        healthManager.saveMeal(meal)
    }
    
    
    // MARK: - gesture recognizers

    @objc func tap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        self.searchController.searchBar.resignFirstResponder()
    }

    @objc func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            if let meal = mealSelectedByLongPressGestureRecognizer(longPressGestureRecognizer) {
                print("Selected meal is \(meal)")
                let alertController = UIAlertController(title: "Mahlzeit", message: "Optionen für die ausgewählte Mahlzeit.", preferredStyle: .actionSheet)
                
                alertController.addAction( UIAlertAction(title: "Löschen", style: .destructive) {[unowned self] action in self.deleteMeal(meal) })
                alertController.addAction( UIAlertAction(title: "Nährwerte anzeigen", style: .default) {[unowned self] action in self.mealDetail(meal) })
                alertController.addAction( UIAlertAction(title: "Kopieren", style: .default) {[unowned self] action in self.copyMeal(meal)} )
                alertController.addAction( UIAlertAction(title: "Ändern (Datum/Kommentar)", style: .default) {[unowned self] (action) in self.editMeal(meal) })
                alertController.addAction( UIAlertAction(title: "Health autorisieren", style: .default) {[unowned self] (action) in self.authorizeHealthKit() })
//                alertController.addAction( UIAlertAction(title: "Zu Health übertragen", style: .default) {[unowned self] (action) in self.healthManager.syncMealToHealth(meal) })
                alertController.addAction( UIAlertAction(title: "Rezept hieraus erstellen", style: .default) {[unowned self] (action) in self.createRecipe(meal) })
                alertController.addAction( UIAlertAction(title: "Zurück", style: .cancel) {action in print("Cancel Action")})
                
                
                present(alertController, animated: true) {print("Presented Alert View Controller in \(#file)")}
            }
        }
    }

    
    //MARK: - Action Sheet: Actions on the meal via long press gesture Recognizer
    
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
        _ = Recipe.fromMeal(meal, inManagedObjectContext: managedObjectContext)
    }
    
    
    func deleteMeal(_ meal: Meal) {
        // aks user if he really wants to delete the meal using an alert controller
        let alert = UIAlertController(title: "Mahlzeit löschen?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Zurück", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Löschen", style: UIAlertActionStyle.destructive) { [unowned self] (action) in
            print("Will delete the meal \(meal)")
            self.managedObjectContext.delete(meal)
            self.healthManager.deleteMeal(meal)
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
            currentMeal = newMeal
            healthManager.syncMealToHealth(newMeal)
            self.tableView.reloadData()
            self.tableView.scrollToRow(at:  IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true); // scrolls to top
        }
    }
    
    func editMeal(_ meal: Meal) {
        currentMeal = meal
        performSegue(withIdentifier: SegueIdentifier.ShowMealEditTVC.rawValue, sender: self)
    }
    
    
    /// MARK: - HealthKit
    
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
    
    

    //MARK: - fetched results controller
    
    func fetchMealIngredients() {

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MealIngredient") // old style needes for fetched results controller
        request.predicate = searchFilter.predicateForMealOrRecipeIngredientsWithSearchText(self.searchController.searchBar.text)

        // Performance optimation for reading and saving of data
        request.fetchBatchSize = 20
        request.fetchLimit = defaultFetchLimit  // Speeds up a lot, especially inital loading of this view controller, but needs care
        request.returnsObjectsAsFaults = true   // objects are only loaded, when needed/used -> faster but more frequent disk reads
//        request.includesPropertyValues = false  // Load property values only when used/needed -> faster but more frequent disk reads
//        request.includesPropertyValues = true   // usefull only, when only relevant properties are read
//        let thePropertiesToFetch = ["amount"]   // read only certain properties (others are fetched automatically on demand)
//        request.propertiesToFetch = thePropertiesToFetch
        
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
