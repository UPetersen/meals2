//
//  FavoriteSearchCDTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 18.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc class FavoriteSearchCDTVC: BaseSearchCDTVC {
    
    weak var meal: Meal!
    //    var currentFood: Food!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFoods()
    }
    
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteSearchCell", for: indexPath)
        let food = self.fetchedResultsController.object(at: indexPath) as! Food
        cell.textLabel!.text = food.name
        return cell
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Segue FavoriteSearchCDTVC to FoodDetailCDTVC" {
            if let viewController = segue.destination as? FoodDetailCDTVC,
                let indexPath = self.tableView.indexPathForSelectedRow,
                let food = self.fetchedResultsController.object(at: indexPath) as? Food {
                viewController.item = .isFood(food, meal)
            }
        }
    }
    
}
