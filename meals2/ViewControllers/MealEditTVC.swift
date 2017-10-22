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
    var meal: Meal!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = meal.comment
        datePicker.date = meal.dateOfCreation! as Date
        
        // dismiss keyboard on drag
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Update the MealsCDTVC, i.e. reload the data
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateMealsCDTVCNotification"), object: nil)
//        if let viewController = self.navigationController?.viewControllers.first as? MealsCDTVC {
//            viewController.tableView.reloadData()
//        }
    }
    
    // TextView delegate (delegate itself set in storyboards)
    func textViewDidChange(_ textView: UITextView) {
        meal.comment = textView.text
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        meal.dateOfCreation = sender.date as NSDate
    }
}

