//
//  FoodListListsCDTVC.swift
//  meals
//
//  Created by Uwe Petersen on 14.09.15.
//  Copyright © 2015 Uwe Petersen. All rights reserved.
//

/*
import Foundation
import UIKit
import CoreData

    @objc class FavoriteSearchCDTVC: FoodListBaseCDTVC {
//    @objc (FoodListListsCDTVC)  class FoodListListsCDTVC: FoodListBaseCDTVC {

    weak var meal: Meal!
//    var currentFood: Food!
    
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Favorite Cell", for: indexPath)
        let food = self.fetchedResultsController.object(at: indexPath) as! Food
        cell.textLabel!.text = food.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.foodListType == .Favorites ? true : false  // only in for favorites it is possible to edit rows
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // Delete favorite from list of favorite foods
            if let food = self.fetchedResultsController.object(at: indexPath) as? Food, let favorite = food.favoriteListItem {
                print("This is a Favorite food with name \(String(describing: favorite.food?.name)) and will now be deleted from the list of favorite foods. The food itself will nto be deleted from the database.")
                managedObjectContext.delete(favorite)
            }
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
*/
