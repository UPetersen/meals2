//
//  MealEditTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 22.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

/// View controller to edit meal attributes, i.e. date (dateOfCreation) and comment
class MealEditTVC: UITableViewController, UITextViewDelegate {

    var managedObjectContext: NSManagedObjectContext!
    weak var meal: Meal!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = meal.comment
        datePicker.date = meal.dateOfCreation! as Date
        
        // dismiss keyboard on drag
        self.tableView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Update the MealsCDTVC, i.e. reload the data
        meal.dateOfLastModification = NSDate()
        HealthManager.synchronize(meal, withSynchronisationMode: .update)
        saveContext(managedObjectContext: managedObjectContext)
    }
    
    // TextView delegate (delegate itself set in storyboards)
    func textViewDidChange(_ textView: UITextView) {
        meal.comment = textView.text
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        meal.dateOfCreation = sender.date as NSDate
    }
    
    
    // MARK: - Core data support
    
    func saveContext (managedObjectContext context: NSManagedObjectContext) {
        let moc = context
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

