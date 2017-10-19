//
//  FoodListListsSearchCDTVC.swift
//  meals
//
//  Created by Uwe Petersen on 15.09.15.
//  Copyright © 2015 Uwe Petersen. All rights reserved.
//
/*
import Foundation
import UIKit
import CoreData
import HealthKit

@objc (FoodListListsSearchCDTVC) final class FoodListListsSearchCDTVC : FoodListBaseSearchCDTVC {
    
    var currentFood: Food!
    
    
    lazy var oneMaxDigitsNumberFormatter: NumberFormatter =  {() -> NumberFormatter in
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        numberFormatter.zeroSymbol = "0"
        return numberFormatter
        }()
    
    
    // Mark: - View Controller
    
    override func viewWillAppear(_ animated: Bool) {
        debugPrint("Navigation controller: \(String(describing: self.navigationController?.toolbar))")
        debugPrint("Presenting Navigation controller: \(String(describing: self.presentingViewController?.navigationController?.toolbar))")
        debugPrint("Presenting Navigation controller: \(String(describing: self.presentingViewController?.navigationController?.toolbar.isHidden))")
        
        super.viewWillAppear(animated)

        debugPrint("Navigation controller: \(String(describing: self.navigationController?.toolbar))")
        debugPrint("Presenting Navigation controller: \(String(describing: self.presentingViewController?.navigationController?.toolbar))")
        debugPrint("Presenting Navigation controller: \(String(describing: self.presentingViewController?.navigationController?.toolbar.isHidden))")
        self.presentingViewController?.navigationController?.toolbar.isHidden = false
        debugPrint("offset: \(self.tableView.contentOffset)")
        debugPrint("inset: \(self.tableView.contentInset)")
        debugPrint("bounds: \(self.tableView.bounds)")
    }
    
    // Hide tableHeaderView if requested
    
    
    // MARK: - Helper
    
    func stringForNumber (_ number: NSNumber, formatter: NumberFormatter, divisor: Double) -> String {
        return (formatter.string(from: NSNumber(value: number.doubleValue / divisor)) ?? "nan")
    }
    
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return foodCellForTableview(tableView, atIndexPath: indexPath)
    }
    
    func foodCellForTableview(_ tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
        
        // Check, if there is a dequeable cell. If not, create a new one
        let cell = createOrDequeReusableCellWithIdentifier("Food Cell", style: TableViewCellStyle)
        
        if let food: Food = self.fetchedResultsController.object(at: indexPath) as? Food {
            
            cell.textLabel!.text = food.name
            
            let formatter = oneMaxDigitsNumberFormatter
            let totalEnergyCals = Nutrient.dispStringForNutrientWithKey("totalEnergyCals", value: food.doubleForKey("totalEnergyCals"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalCarb    = Nutrient.dispStringForNutrientWithKey("totalCarb",    value: food.doubleForKey("totalCarb"),    formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalProtein = Nutrient.dispStringForNutrientWithKey("totalProtein", value: food.doubleForKey("totalProtein"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let totalFat     = Nutrient.dispStringForNutrientWithKey("totalFat",     value: food.doubleForKey("totalFat"),     formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let carbFructose = Nutrient.dispStringForNutrientWithKey("carbFructose", value: food.doubleForKey("carbFructose"), formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            let carbGlucose   = Nutrient.dispStringForNutrientWithKey("carbGlucose", value: food.doubleForKey("carbGlucose"),  formatter: formatter, inManagedObjectContext: managedObjectContext) ?? ""
            
            cell.detailTextLabel?.text = totalEnergyCals + ", " + totalCarb + " KH, " + totalProtein + " Prot., " + totalFat + " Fett, " + carbFructose + " Fruct., " + carbGlucose + " Gluc."
            cell.showsReorderControl = true
        }
        return cell
    }
    
    func formattedQuantityStringForNutrientWithKey(_ key: String, value: Double, formatter: NumberFormatter) -> String {
        
        if let nutrient = Nutrient.nutrientForKey(key, inManagedObjectContext: managedObjectContext) {
            let valueInDisplayUnits = HKQuantity(unit: nutrient.hkUnit, doubleValue: value).doubleValue(for: nutrient.hkDispUnit)
            return formatter.string(from: NSNumber(value: valueInDisplayUnits as Double))!  + " " + nutrient.hkDispUnitText
        }
        return ""
    }
    
    // Fixme: this should not be needed any more since we are using storyboards. But this is not stuff for this base view controller anyways
    func createOrDequeReusableCellWithIdentifier(_ identifier: String, style: UITableViewCellStyle) -> UITableViewCell {
        
        if let _cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: identifier) {
            return _cell
        } else {
            let cell =  UITableViewCell(style: style, reuseIdentifier: identifier)
            cell.textLabel?.numberOfLines = 0
            //            cell.detailTextLabel?.numberOfLines = 0
            return cell
        }
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Segue is performed from presentingViewController which is a MealsCDTVC, but sender is this viewController
        if let mealsCDTVC = presentingViewController as? MealsCDTVC {
            
            currentFood = self.fetchedResultsController.object(at: indexPath) as! Food
            mealsCDTVC.performSegue(withIdentifier: "Segue MealsCDTVC to FoodDetailTVC", sender: self)
            
        } else {
            fatalError("Could not perform segue to Food Details Table View Controller")
        }
    }
    
    
}
*/
