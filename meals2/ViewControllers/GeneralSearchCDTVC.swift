//
//  GeneralSearchCDTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 18.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc class GeneralSearchCDTVC: FavoriteSearchCDTVC {
    
    lazy var oneMaxDigitsNumberFormatter: NumberFormatter =  {() -> NumberFormatter in
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        numberFormatter.zeroSymbol = "0"
        return numberFormatter
    }()
    
//    var originalWindowLayerSpeed: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        foodListType = FoodListType.All // start with all foods as list to search in
        foodListTypeButton.title = foodListType.rawValue + " ▾"

        title = foodListType.rawValue
        
        // FIXME: fetchFoods called twice by doing this here.
        fetchFoods()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        // Trick for raising up the keyboard, see https://stackoverflow.com/questions/27951965/cannot-set-searchbar-as-firstresponder#28527114
        DispatchQueue.main.async { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
//            // To speed up display of search bar and raising of keyboard, the transition speed was changed in the presenting view controller.
//            // Reset general view transition speed (animations) to original value used in this app
//            if let speed = self?.originalWindowLayerSpeed {
//                let app = UIApplication.shared.delegate
//                app?.window??.layer.speed = speed
//            }
        }
    }

    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralSearchCell", for: indexPath)
        
        if let food: Food = self.fetchedResultsController.object(at: indexPath) as? Food {
            cell.textLabel?.text = food.name
            
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
    

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Segue GeneralSearchCDTVC to FoodDetailCDTVC" {
            if let viewController = segue.destination as? FoodDetailCDTVC,
                let indexPath = self.tableView.indexPathForSelectedRow,
                let food = self.fetchedResultsController.object(at: indexPath) as? Food {
                viewController.item = .isFood(food, meal)
            }
        }
    }

    
}
