//
//  FoodListListsCDTVC.swift
//  meals
//
//  Created by Uwe Petersen on 14.09.15.
//  Copyright © 2015 Uwe Petersen. All rights reserved.
//
import Foundation
import UIKit
import CoreData

@objc (FoodListListsCDTVC) final class FoodListListsCDTVC: FoodListBaseCDTVC {
    
    var meal: Meal!
//    var currentFood: Food!


    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem
        title = "Listen"
        navigationController?.isToolbarHidden = false
    }
    
    
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Favorite Cell", for: indexPath)
        let food = self.fetchedResultsController.object(at: indexPath) as! Food
        cell.textLabel!.text = food.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // Delete favorite from list of favorite foods
            let food = self.fetchedResultsController.object(at: indexPath) as! Food
            if let favorite = food.favoriteListItem {
                print("This is a Favorite food with name \(String(describing: favorite.food?.name)) and will now be deleted from the list of favorite foods. The food itself will nto be deleted from the database.")
                managedObjectContext.delete(favorite)
            }
            // 2017-10-15: removed this, cause too ease to delete a food from the database in such a simple way. Foods are to be deleted from the food view
//            } else {
//                print("This is a Food with name \(String(describing: food.name)) and the food will be deleted from the database")
//                managedObjectContext.delete(food)
//            }
        }
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "Segue NewFavoriteCDTVC to FoodDetailTVC", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
//        if segue.identifier == "Segue NewFavoriteCDTVC to FoodDetailTVC" {
//            let viewController = segue.destination as! FoodDetailCDTVC
//            let food = self.fetchedResultsController.object(at: self.tableView.indexPathForSelectedRow!) as! Food
//
//            viewController.item = .isFood(food, meal)
//        }
    }
    
}
