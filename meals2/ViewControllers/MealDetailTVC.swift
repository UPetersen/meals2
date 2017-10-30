//
//  MealDetailTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 25.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation

import UIKit
import CoreData

@objc final class MealDetailTVC: UITableViewController, UIActionSheetDelegate {
    
    var theTable: FoodDetails!
    
    var managedObjectContext: NSManagedObjectContext!
    weak var meal: Meal!
    
    override func viewWillAppear(_ animated: Bool) {
        
        // This also updates this view controller when coming back from view controller that changes food data
        self.navigationController?.isToolbarHidden = true
        loadData()
        super.viewWillAppear(animated)
    }
    
    func loadData() {
        theTable = FoodDetails(managedObjectContext: managedObjectContext, item: meal)
        self.title = "Details der Mahlzeit"
        self.tableView.reloadData()
    }
    
    
    
    //MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return theTable.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let nRows = theTable.sections[section].rows?.count {
            return nRows
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return theTable.sections[section].title
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForFooterInSection section: Int) -> String? {
        return theTable.sections[section].footer
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Meal Detail Cell", for: indexPath)
        
        if let row = theTable.sections[indexPath.section].rows?[indexPath.row] {
            cell.textLabel?.text = row.textLabel
            cell.detailTextLabel?.text = row.detailTextLabel
        }
        return cell
    }
}

