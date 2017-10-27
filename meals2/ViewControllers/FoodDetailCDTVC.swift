//
//  FoodDetailCDTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 20.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc class FoodDetailCDTVC: UITableViewController, UIActionSheetDelegate {
    
    var viewModel: FoodDetails! // the view model vor this view controller
    
    enum SegueIdentifier: String {
        case ShowAdddFoodTVC   = "Segue FoodDetailTVC to AddFoodTVC"
        case ShowFoodEditTVC   = "Segue FoodDetailTVC to FoodEditTVC"
        case ShowRecipeEditTVC = "Segue FoodDetailTVC to RecipeEditTVC"
    }
    
    var managedObjectContext: NSManagedObjectContext!
    @objc var meal: Meal!
    var food: Food!
    var item: Item?
    var newFood: Food!
    
    override func viewWillAppear(_ animated: Bool) {
        if let item = item {
            switch item {
            case .isFood(let theFood, let theMeal):
                food = theFood
                meal = theMeal
                managedObjectContext = food.managedObjectContext
            default: break
            }
        }
        loadData() // must be done here, if undo is selected in one of the follwing view controllers
        super.viewWillAppear(animated)
    }
    
    
    // MARK: - Load view model
    
    /// This also updates this view controller when coming back from view controllers that changes food data
    func loadData() {
        viewModel = FoodDetails(managedObjectContext: managedObjectContext, item: food)
        self.title = food.name
        self.tableView.reloadData()
    }
    
    
    // MARK: - UITableViewDelegate methods for automatic row heights
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(44.0)
    }
    
    
    
    //MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let nRows = viewModel.sections[section].rows?.count {
            return nRows
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].title
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footer
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Food Detail Cell", for: indexPath)
        
        if let row = viewModel.sections[indexPath.section].rows?[indexPath.row] {
            cell.textLabel?.text = row.textLabel
            cell.detailTextLabel?.text = row.detailTextLabel
        }
        return cell
    }
    
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) {
            switch segueIdentifier {
            case .ShowAdddFoodTVC:
                if let viewController = segue.destination as? AddFoodTVC {
                    viewController.item = .isFood(food, meal)
                } else {
                    fatalError("target view controller is not of desired class")
                }
            case .ShowFoodEditTVC:
                //                if let viewController = segue.destinationViewController.contentViewController as? NewOrChangeFood { // uses CS195P extension by Paul Hegarty
                if let viewController = segue.destination as? FoodEditTVC { // uses CS195P extension by Paul Hegarty
                    managedObjectContext.undoManager = UndoManager()
                    managedObjectContext.undoManager?.beginUndoGrouping()
                    //                    viewController.item = .IsFood(food, meal)
                    viewController.item = .isFood(newFood, meal)
                } else {
                    fatalError("target view controller is not of desired class")
                }
            case .ShowRecipeEditTVC:
                if let viewController = segue.destination as? RecipeEditTVC {
                    print("Prepare for segue for RecipeFormTVC with recipe \(String(describing: food.recipe))")
                    viewController.recipe = food.recipe
                    viewController.managedObjectContext = managedObjectContext
                }
            }
        } else {
            fatalError("Segue \(String(describing: segue.identifier))" + " not yet handled")
        }
    }
    
    @IBAction func saveAndUnwindFromFoodEditTVC(_ sender: UIStoryboardSegue)
    {
        if let sourceViewController = sender.source as? FoodEditTVC {
            managedObjectContext.undoManager?.endUndoGrouping()
            managedObjectContext.undoManager?.removeAllActions()
            food = sourceViewController.food
            print("Unwinded with save for source \(sourceViewController)")
        }
    }
    
    @IBAction func undoAndUnwindFromFoodEditTVC(_ sender: UIStoryboardSegue)
    {
        if let sourceViewController = sender.source as? FoodEditTVC {
            managedObjectContext.undoManager?.endUndoGrouping()
            managedObjectContext.undo()
            print("Unwinded with undo for source \(sourceViewController)")
        }
    }
    
    
    // MARK: - Action Sheet for Action Button (left button)
    
    @IBAction func actionButtonSelected(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Lebensmittel", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alertController.addAction( UIAlertAction(title: "Löschen", style: .destructive) {[unowned self] action in self.deleteFoodAction()} )
        alertController.addAction( UIAlertAction(title: "Neu", style: .default) {[unowned self] action in self.newFoodAction()} )
        alertController.addAction( UIAlertAction(title: "Kopieren", style: .default) {[unowned self] action in self.copyFoodAction()} )
        alertController.addAction( UIAlertAction(title: "Ändern", style: .default) {[unowned self] (action) in self.changeFoodAction() })
        if food.recipe != nil { // recipe actions only for recipes
            alertController.addAction( UIAlertAction(title: "Rezept: ändern", style: .default) {[unowned self] (action) in self.recipeDetail()})
        }
        alertController.addAction( UIAlertAction(title: "Zu Favoriten hinzufügen", style: .default) {[unowned self] (action) in self.addFoodToFavoritesAction() })
        alertController.addAction( UIAlertAction(title: "Zurück", style: .cancel) {(action) in print("Cancel Action")})
        
        present(alertController, animated: true) {print("Presented Alert View Controller in \(#file)")}
    }
    
    func changeFoodAction() {
        newFood = food
        performSegue(withIdentifier: SegueIdentifier.ShowFoodEditTVC.rawValue, sender: self)
    }
    
    func newFoodAction() {
        //        food = Food.newFood(inManagedObjectContext: managedObjectContext)
        newFood = Food.newFood(inManagedObjectContext: managedObjectContext)
        loadData()
        saveContext()
        performSegue(withIdentifier: SegueIdentifier.ShowFoodEditTVC.rawValue, sender: self)
    }
    
    func copyFoodAction() {
        //        food  = Food.fromFood(food, inManagedObjectContext: managedObjectContext)
        newFood  = Food.fromFood(food, inManagedObjectContext: managedObjectContext)
        loadData()
        performSegue(withIdentifier: SegueIdentifier.ShowFoodEditTVC.rawValue, sender: self)
    }
    
    func recipeDetail() {
        if food.recipe != nil {
            performSegue(withIdentifier: SegueIdentifier.ShowRecipeEditTVC.rawValue, sender: self)
        } else {
            let alert = UIAlertController(title: "Lebensmittel ist kein Rezept", message: "Dieses Lebensmittel ist kein Rezept und es können daher auch keine Rezeptdaten geändert werden", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Delete Food Action
    func deleteFoodAction() {
        if food.mealIngredients != nil && food.mealIngredients!.count > 0 {
            askUserToDeleteFood() // ask user, since the food is part of at least one meal
        } else {
            deleteFoodAndPopViewController()
        }
    }
    
    func askUserToDeleteFood() {
        let uniqueMeals = Set( food.mealIngredients!.flatMap{($0 as AnyObject).meal} )
        
        let alert = UIAlertController(title: "Lebensmittel löschen?", message: "Lebensmittel ist \(food.mealIngredients!.count) mal Bestandteil von \(uniqueMeals.count) Mahlzeit(en) und wird aus diesen gelöscht.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Zurück", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Löschen", style: UIAlertActionStyle.destructive) { [unowned self] (action) in self.deleteFoodAndPopViewController() })
        present(alert, animated: true, completion: nil)
    }
    
    func deleteFoodAndPopViewController() {
        food.managedObjectContext?.delete(food)
        navigationController?.popViewController(animated: true)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // Add Favorite Action
    func addFoodToFavoritesAction() { // Adds the food to the list of favorite foods (if not already on that list)
        food.addToFavorites(managedObjectContext: managedObjectContext)
    }
    
    // MARK: - Action for Add Button (right button)
    
    @IBAction func addButtonSelected(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: SegueIdentifier.ShowAdddFoodTVC.rawValue, sender: self)
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
