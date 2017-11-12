//
//  AddFoodTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 21.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

final class AddFoodTVC: UITableViewController, UITextFieldDelegate {
    
    let MAX_AMOUNT_IN_GRAMS = 9999.0
    
    var managedObjectContext: NSManagedObjectContext!
    weak var food: Food!
    var item: Item?
    
    var amountInGrams: Double = Double(10)
    
    lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.groupingSeparator = "" // no thousands separator
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        return formatter
    }()
    
    override func viewDidLoad() {
        if let item = item {
            switch item {
            case .isMealIngredient(let theMealIngredient):
                food = theMealIngredient.food
                amountInGrams = theMealIngredient.amount?.doubleValue ?? 0.0
                managedObjectContext = theMealIngredient.managedObjectContext
                title = "Menge ändern"
            case .isFood(let theFood, _):
                food = theFood
                managedObjectContext = food.managedObjectContext
                amountInGrams = 0
                title = "Lebensmittel hinzufügen"
            default: break
            }
        }
        self.tableView.backgroundColor = UIColor(red: 239.0, green:239.0, blue:244.0, alpha:1.0)
        
        // Save button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(AddFoodTVC.saveButtonSelected))
        
        // Dismiss keyboard on drag
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag

        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
        super.viewWillAppear(animated)
    }
    
    
    //MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1, 2:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell = UITableViewCell()
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "Food Name Cell", for: indexPath)
            cell.textLabel?.text = food.name
        case 1:  // The cell with textField, slider and stepper
            if let theCell = tableView.dequeueReusableCell(withIdentifier: "Amount Cell", for: indexPath) as? AmountSettingTableViewCell {
                addTargetsToCell(theCell)
                configureSliderAndStepperForCell(theCell)
                configureCell(theCell: theCell)
                cell = theCell
            }
        case 2:
            let theCell = tableView.dequeueReusableCell(withIdentifier: "Serving Size Cell", for: indexPath)
            cell = theCell
            cell.textLabel?.text = food.name
            cell.detailTextLabel?.text = "12 g"
        default:
            fatalError("Could not find an appropriate cell in cellForRowAtIndexPath of AddFoodTVC. Aborting program.")
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            return 125.0
        default:
            return 44.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 11.0
        default:
            return 22.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 11.0
        case 1:
            return 44.0
        default:
            return 22.0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "PORTION"
        case 2:
            return "VORDEFINIERTE PORTIONEN"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2:
            return "Mehrfach drücken für mehrere Portionen"
        default:
            return ""
        }
    }
    
    //MARK: - Navigation from here on
    
    @objc func saveButtonSelected() {
        
        if let item = item {
            switch item {
            case .isMealIngredient(let theMealIngredient):
                // This is the case where the amount of a meal ingredient was changed by the user and has now to be stored properly
                // convert to milligrams and store
                theMealIngredient.amount = NSNumber(value: self.amountInGrams as Double)
                theMealIngredient.meal?.dateOfLastModification = NSDate()
                
                // Save and sync to HealthKit
                saveContextAndsyncToHealthKit(theMealIngredient.meal!)
                
                // Jump (i.e. pop) to parent controller
                self.navigationController?.popViewController(animated: true)
                
            case .isFood( _, let theMeal):
                // This is the case, where a food was selected, an amount set for this food and now a meal ingredient has to be created from this food
                if let theMealIngredient = NSEntityDescription.insertNewObject(forEntityName: "MealIngredient", into: managedObjectContext) as? MealIngredient {
                    theMealIngredient.food = food
                    theMealIngredient.amount = NSNumber(value: amountInGrams as Double)
                    if theMeal != nil {
                        theMealIngredient.meal = theMeal!
                    } else { // create new meal if there are no meals existent, yet, and tie this food to it as meal ingredient
                        theMealIngredient.meal = Meal(context: managedObjectContext)
                    }
                    if let meal = theMealIngredient.meal {
                        meal.dateOfLastModification = NSDate()
                        // Save and sync to HealthKit
                        saveContextAndsyncToHealthKit(meal)
                    }
                    
                    // Jump back (i.e. pop) two view controllers (that's kind of the grand parent view controller)
                    if let viewControllers = self.navigationController?.viewControllers {
                        print("View controllers: \(viewControllers)")
                        let index: Int = viewControllers.count - 3;
                        self.navigationController?.popToViewController(viewControllers[index], animated: true)
                    }
                }
            default: break
            }
        }
    }
    
    
    
    //MARK: - target action stuff for amountSettingTableViewCell with textField, slider and stepper
    
    
    @objc func amountTextFieldEditingChanged(sender: UITextField) {
        
        guard let aNumber = numberFormatter.number(from: sender.text!) else {
            return
        }
        self.amountInGrams = Double(truncating: aNumber)
//        updateAmountSettingTableViewCell()
    }
    
    @objc func sliderValueChanged(sender:UISlider) {
        self.amountInGrams = round(Double(sender.value))
        updateAmountSettingTableViewCell()
    }
    
    
    @objc func sliderTouchUpInside(sender:UISlider) {
        // Whenever the user ends dragging, switch back to continuous mode (if it was not set already)
        sender.isContinuous = true
        updateAmountSettingTableViewCell()
    }
    
    @objc func sliderTouchUpOutside(sender:UISlider) {
        // Whenever the user ends dragging, switch back to continuous mode (if it was not set already)
        sender.isContinuous = true
        updateAmountSettingTableViewCell()
    }
    
    @objc func stepperValueChanged(sender:UIStepper) {
        // rounded values only and less than maximum allowed value
        if round(sender.value) > MAX_AMOUNT_IN_GRAMS {
            sender.value = Double(MAX_AMOUNT_IN_GRAMS)
        } else {
            sender.value = round(sender.value)
        }
        self.amountInGrams = Double(sender.value)
        updateAmountSettingTableViewCell()
    }
    
    
    
    func saveContextAndsyncToHealthKit(_ meal: Meal) {
        saveContext()
        let healthManager = HealthManager()
        healthManager.syncMealToHealth(meal)
    }
    
    
    //MARK: - cell configuration
    
    func updateAmountSettingTableViewCell() {
        let indexPath = IndexPath(row: 0, section: 1) // IndexPath to where the amount was entered
        
        //            let indexPath = NSIndexPath(forRow: 0, inSection: 1)
        
        if let theCell = self.tableView.cellForRow(at: indexPath) as? AmountSettingTableViewCell {
            configureCell(theCell: theCell)
        }
    }
    
    
    
    func configureSliderAndStepperForCell(_ theCell: AmountSettingTableViewCell) {
        theCell.slider.minimumValue = 0.0
        theCell.stepper.maximumValue = CDouble(MAX_AMOUNT_IN_GRAMS) // to be called before value is set (otherwhise, value is capped to standard maximum of 100)
    }
    
    func configureCell(theCell: AmountSettingTableViewCell) {
        
        theCell.amountTextField.text = self.numberFormatter.string(from: NSNumber(value: self.amountInGrams))
        
        theCell.slider.minimumValue = 0.0
        theCell.slider.value = CFloat(self.amountInGrams)
        adjustSliderMaximumValueIfNecessary(theCell.slider)
        theCell.slider.value = CFloat(self.amountInGrams)   // must be called again, to redraw slider position, afer slider.maximum was changed
        
        theCell.stepper.maximumValue = CDouble(MAX_AMOUNT_IN_GRAMS) // to be called before value is set (otherwhise, value is capped to standard maximum of 100)
        theCell.stepper.value = Double(self.amountInGrams)
    }
    
    
    
    
    func addTargetsToCell(_ theCell: AmountSettingTableViewCell) {
        // needed to adjust maximum value of slider when slider hits the right boundary
        // (I don't know how to do this properly with SwiftBond and think it is too complicated and using ordinary target action is more simple)
        theCell.slider.addTarget(self, action: #selector(AddFoodTVC.sliderTouchUpInside), for: UIControlEvents.touchUpInside)
        
        // Add target-action for textfield, slider and stepper
        theCell.amountTextField.addTarget(self, action: #selector(AddFoodTVC.amountTextFieldEditingChanged), for: UIControlEvents.editingChanged)
        theCell.slider.addTarget(self, action: #selector(AddFoodTVC.sliderValueChanged), for: UIControlEvents.valueChanged)
        theCell.slider.addTarget(self, action: #selector(AddFoodTVC.sliderTouchUpOutside), for: UIControlEvents.touchUpOutside)
        theCell.slider.addTarget(self, action: #selector(AddFoodTVC.sliderTouchUpInside), for: UIControlEvents.touchUpInside)
        theCell.stepper.addTarget(self, action: #selector(AddFoodTVC.stepperValueChanged), for: UIControlEvents.valueChanged)
    }
    
    //MARK: - slider maximum value adjustment
    
    //        @objc func sliderTouchUpInside(_ sender: UISlider) {
    //        // Whenever the user ends dragging, switch back to continuous mode (if it was not set already)
    //        sender.isContinuous = true
    //        adjustSliderMaximumValueIfNecessary(sender)
    //    }
    
    func adjustSliderMaximumValueIfNecessary(_ slider: UISlider) {
        //        println("adjust slider maximum if necessary from: (\(slider.minimumValue), \(slider.value), \(slider.dynValue.value), \(slider.maximumValue))")
        // Adjustment of maximum value shall occur, if
        //    a) slider hits the maximum (i.e. the right border) or
        //    b) slider hits the minimum (i.e. the left border)
        if slider.value >= slider.maximumValue || slider.value <= slider.minimumValue {
            //        if slider.value >= slider.maximumValue || slider.value <= slider.minimumValue {
            
            calculateAndSetSliderMaximumValue(slider: slider)
            //            if slider.value >= slider.maximumValue {
            if slider.value >= slider.maximumValue {
                // If the slider is at the maximum value, the user has to touch up for seeing the values increment again
                slider.isContinuous = false
            }
        }
    }
    
    func calculateAndSetSliderMaximumValue(slider theSlider: UISlider) {
        // That's what we want for the minimum and maximum value:
        // [0 ... value (e.g. 7) ... 20] for values of 10 or lower, to be changed, when user hits the left border (i.e. the minimum value)
        // [0 ... value (e.g. 14) ... 28] for values greater than 10 up to 4999
        // [0 ... value (e.g. 6000) ... 9999] for numbers equal or greater than 5000
        //        if theSlider.dynValue.value <= 10.0 {
        if theSlider.value <= 10.0 {
            theSlider.maximumValue = 20.0
        } else {
            // Should not be greater than MAX_AMOUNT_IN_GRAMS
            theSlider.maximumValue = min( CFloat(theSlider.value * 2.0), CFloat(MAX_AMOUNT_IN_GRAMS) )
        }
    }
    
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
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
    
}
