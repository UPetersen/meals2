//
//  SearchCDTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 18.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//
/*
import Foundation
import UIKit
import CoreData

@objc class SearchCDTVC: FoodListListsCDTVC {
    
    
    
    
    lazy var oneMaxDigitsNumberFormatter: NumberFormatter =  {() -> NumberFormatter in
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        numberFormatter.zeroSymbol = "0"
        return numberFormatter
    }()
    
    
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
}
*/
