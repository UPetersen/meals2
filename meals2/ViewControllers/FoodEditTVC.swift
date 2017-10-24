//
//  FoodEditTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 23.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc final class FoodEditTVC: UITableViewController, UIActionSheetDelegate, UITextFieldDelegate {
    
    var theTable: FoodDetails!
    
    var managedObjectContext: NSManagedObjectContext!
    var meal: Meal!
    var food: Food!
    var item: Item?
    
    lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        return numberFormatter
    }()
    
    // MARK: - Initialization

    override func viewDidLoad() {
        if let item = item {
            switch item {
            case .isFood(let theFood, let theMeal):
                food = theFood
                meal = theMeal
                managedObjectContext = food.managedObjectContext
            default: break
            }
        }
        theTable = FoodDetails(managedObjectContext: managedObjectContext, item: food)
        self.title = food.name
        
        // dismiss keyboard on drag
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        
        super.viewDidLoad()
    }
    
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        
        let textField = sender
        if let cell = textField.superview?.superview as? UITableViewCell, let indexPath = self.tableView.indexPath(for: cell) {
            
            switch theTable.sections[indexPath.section].rows?[indexPath.row]  {
            case let nutrientDataRecord as NutrientDataRecord:
                if let text = textField.text {
                    if let myValue = nutrientDataRecord.nutrient.valueForDisp(text, formatter: numberFormatter) {
                        let value = NSNumber(value: myValue as Double)
                        food.setValue(value, forKey: nutrientDataRecord.nutrient.key!)
                    }
                }
            case _ as InformationDataRecord:
                let detail = textField.text
                food.setValue(detail, forKey: "name")
            default:
                break
            }
        }
    }
    
    
    //MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return theTable.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return theTable.sections[section].rows?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return theTable.sections[section].title
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return theTable.sections[section].footer
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodEditTableViewCellIdentifier", for: indexPath)
        if let foodEditTableViewCell = cell as? FoodEditTableViewCell {
            configureCell(foodEditTableViewCell, atIndexPath: indexPath)
            return foodEditTableViewCell
        }
        return cell
    }
    
    func configureCell(_ cell: FoodEditTableViewCell, atIndexPath indexPath:IndexPath) {
        if let row = theTable.sections[indexPath.section].rows?[indexPath.row] {
            
            switch theTable.sections[indexPath.section].rows?[indexPath.row] {
            case let nutrientDataRecord as NutrientDataRecord:
                if let label = nutrientDataRecord.textLabel, let dispUnit = nutrientDataRecord.nutrient.dispUnit {
                    cell.LeftDetailTextLabel.text = label  + " (\(dispUnit))"
                }
                cell.RightDetailTextField.text = food.dispStringForNutrient(nutrientDataRecord.nutrient, formatter: numberFormatter, showUnit: false)
                cell.RightDetailTextField.placeholder = nutrientDataRecord.nutrient.dispUnit
                //    func dispStringForNutrient(nutrient: Nutrient, formatter: NSNumberFormatter, showUnit: Bool = true) -> String? {
                
            case _  as InformationDataRecord:
                cell.LeftDetailTextLabel.text = row.textLabel
                cell.RightDetailTextField.text = row.detailTextLabel
                cell.RightDetailTextField.placeholder = nil
            default:
                cell.LeftDetailTextLabel.text = row.textLabel
                cell.RightDetailTextField.text = row.detailTextLabel
            }
        }
    }
    
    
    // MARK: - data entry
    
    func numberForString(_ text: String) -> NSNumber? {
        
        // There is a problem when the user backspaces a number like "1.234" to "1.23" which ist not interpreted correctly as either 1.230 or nil, depending on the method used to convert the string to a float (assuming "." beeing the grouping separator of the locale). To overcame this the "." must be replaced by "" to obtain "123" which will then be interpreted correctly as a floatvalue of 123.0
        let textWOGroupingSeparator = text.replacingOccurrences(of: numberFormatter.groupingSeparator, with: " ") // Must exist and have a value
        let aDouble : Double? = (textWOGroupingSeparator as NSString).doubleValue
        
        if aDouble != nil {
            return NSNumber(value: aDouble! as Double)
        }
        return nil
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        if let cell = textField.superview?.superview as? UITableViewCell, let indexPath = self.tableView.indexPath(for: cell) {
            
            switch theTable.sections[indexPath.section].rows?[indexPath.row]  {
            case is NutrientDataRecord:
                textField.keyboardType = .decimalPad
            default:
                textField.keyboardType = .default
            }
        }
        return true
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
