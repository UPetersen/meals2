//
//  AmountSettingTVC.swift
//
//  Created by Uwe Petersen on 09.06.14.
//  Copyright (c) 2014 Uwe Petersen. All rights reserved.
//
/*
import Foundation
import UIKit
import CoreData

//@objc(AmountSettingTVC) final class AmountSettingTVC: UITableViewController, UITextFieldDelegate {
    final class AmountSettingTVC: UITableViewController, UITextFieldDelegate {

    let MAX_AMOUNT_IN_GRAMS = 9999.0
    
    var managedObjectContext: NSManagedObjectContext!
    var food: Food!
    var item: Item?
    
    var amountInGrams: Double = Double(10) {
        didSet {
            print("Did set the amountInGrams to \(amountInGrams)")
        }
    }
    
    // Cell with slider, stepper and textField for setting amount using siftBond
    var amountCell:AmountSettingTableViewCell!
    let numberFormatter = numberFormatterOneDigit.sharedInstance
    
    override func viewDidLoad() {
        
        print("In viewDidLoad von " + #file)
        
        if let item = item {
            switch item {
            case .isMealIngredient(let theMealIngredient):
                food = theMealIngredient.food
                amountInGrams = theMealIngredient.amount.doubleValue 
                managedObjectContext = theMealIngredient.managedObjectContext
                self.title = "ändern"
                
            case .isFood(let theFood, _):
                food = theFood
                managedObjectContext = food.managedObjectContext
                amountInGrams = 0
                self.title = "hinzufügen"
            default: break
            }
        }
        self.tableView.backgroundColor = UIColor(red: 239.0, green:239.0, blue:244.0, alpha:1.0)
        
        // No toolbar
//        self.navigationController?.toolbarHidden = true
//        self.hidesBottomBarWhenPushed = true
        
        // Save button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(AmountSettingTVC.saveButtonSelected))

        // tapRecognizer, to withdraw the keyboard when user taps somewhere outside
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(AmountSettingTVC.tap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapRecognizer)

        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
        self.navigationController?.isToolbarHidden = true
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
                cell = theCell
            }
        case 2:
            let theCell = tableView.dequeueReusableCell(withIdentifier: "Serving Size Cell", for: indexPath)
            cell = theCell
            cell.textLabel?.text = food.name
            cell.detailTextLabel?.text = "12 g"
        default:
            fatalError("Could not find an appropriate cell in cellForRowAtIndexPath of AmountSettingTVC. Aborting program.")
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
                
                // Save and sync to HealthKit
                saveContextAndsyncToHealthKit(theMealIngredient.meal)
                
                // Jump (i.e. pop) to parent controller
                self.navigationController?.popViewController(animated: true)
                
            case .isFood( _, let theMeal):
                // This is the case, where a food was selected, an amount set for this food and now a meal ingredient has to be created from this food
                if let theMealIngredient = NSEntityDescription.insertNewObject(forEntityName: "MealIngredient", into: managedObjectContext) as? MealIngredient {
                    theMealIngredient.food = food
                    theMealIngredient.amount = NSNumber(value: amountInGrams as Double)
                    if theMeal != nil {
                        theMealIngredient.meal = theMeal!
                    } else { // create new meal if there are no meals existent, yet
                        theMealIngredient.meal = NSEntityDescription.insertNewObject(forEntityName: "Meal", into: managedObjectContext) as! Meal
                    }
                    // Save and sync to HealthKit
                    saveContextAndsyncToHealthKit(theMealIngredient.meal)
                    
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
        
        // Notify observer used to update the parent (or grand parent view) to which will be popped back
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateMealsCDTVCNotification"), object: nil)
    }
    
        
        
    //MARK: - target action stuff for amountSettingTableViewCell with textField, slider and stepper
        
        
        @objc func amountTextFieldEditingChanged(sender: UITextField) {
            
        // There is a problem when the user backspaces a number like "1.234" to "1.23" which ist not interpreted correctly as either 1.230 or nil, depending on the method used to convert the string to a float (assuming "." beeing the grouping separator of the locale). To overcame this the "." must be replaced by "" to obtain "123" which will then be interpreted correctly as a floatvalue of 123.0
        if let textWOGroupingSeparator = sender.text?.replacingOccurrences(of: self.numberFormatter.groupingSeparator, with: " ") { // Must exist and have a value
            let aDouble : Double? = (textWOGroupingSeparator as NSString).doubleValue
            if aDouble != nil {
                self.amountInGrams = aDouble!
            } else {
                self.amountInGrams = 0.0
            }
            updateAmountSettingTableViewCell()
        }
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
//            theCell.amountTextField.text = self.numberFormatter.stringFromNumber(NSNumber(double: self.amountInGrams))
            
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
        theCell.slider.addTarget(self, action: #selector(AmountSettingTVC.sliderTouchUpInside), for: UIControlEvents.touchUpInside)
        
        // Add target-action for textfield, slider and stepper
        theCell.amountTextField.addTarget(self, action: #selector(AmountSettingTVC.amountTextFieldEditingChanged), for: UIControlEvents.editingChanged)
        theCell.slider.addTarget(self, action: #selector(AmountSettingTVC.sliderValueChanged), for: UIControlEvents.valueChanged)
        theCell.slider.addTarget(self, action: #selector(AmountSettingTVC.sliderTouchUpOutside), for: UIControlEvents.touchUpOutside)
        theCell.slider.addTarget(self, action: #selector(AmountSettingTVC.sliderTouchUpInside), for: UIControlEvents.touchUpInside)
        theCell.stepper.addTarget(self, action: #selector(AmountSettingTVC.stepperValueChanged), for: UIControlEvents.valueChanged)
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
//        // TODO: understand and/or fix this. Currently the slider value is set here explicitly from dynValue.
//        // Doing so ensures that the slider maximum value is set correctly when the textField is edited. This does not work properly
//        // otherwhise (To check this, just type in "6" and then "6" again (to receive 66)
////        self.amountCell.slider.value = self.amountCell.slider.dynValue.value
//        self.amountCell.slider.value = self.amountCell.slider.bnd_value.value
////        println("adjust slider maximum if necessary to: (\(slider.minimumValue), \(slider.value), \(slider.dynValue.value), \(slider.maximumValue))")
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
    
    //MARK: - Tap Gesture Recognizer
    
     @objc func tap(_ tapRecognizer: UIGestureRecognizer) {
        self.view.endEditing(true) // force to dismiss the keyboard
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




*/



//
//  AmountSettingTVC.swift
//
//  Created by Uwe Petersen on 09.06.14.
//  Copyright (c) 2014 Uwe Petersen. All rights reserved.
//
//
//import Foundation
//import UIKit
//import CoreData
//import Bond
//
//@objc(AmountSettingTVC) final class AmountSettingTVC: UITableViewController, UITextFieldDelegate {
//
//    let MAX_AMOUNT_IN_GRAMS = 9999.0
//
//    var managedObjectContext: NSManagedObjectContext!
//    var food: Food!
//    var item: Item?
//
//    //    var amountInGrams: Double = 10.0
//    var amountInGrams: Double = Double(10) {
//        didSet {
//            print("Did set the amountInGrams to \(amountInGrams)")
//        }
//    }
//
//    // Cell with slider, stepper and textField for setting amount using siftBond
//    var amountCell:AmountSettingTableViewCell!
//    var amount = Observable<Double>(12.0)
//
//    let numberFormatter = numberFormatterOneDigit.sharedInstance
//
//    override func viewDidLoad() {
//
//        print("In viewDidLoad von " + #file)
//
//        if let item = item {
//            switch item {
//            case .isMealIngredient(let theMealIngredient):
//                food = theMealIngredient.food
//                amountInGrams = theMealIngredient.amount.doubleValue
//                managedObjectContext = theMealIngredient.managedObjectContext
//                self.title = "ändern"
//
//            case .isFood(let theFood, _):
//                food = theFood
//                managedObjectContext = food.managedObjectContext
//                amountInGrams = 0
//                self.title = "hinzufügen"
//            default: break
//            }
//        }
//        self.tableView.backgroundColor = UIColor(red: 239.0, green:239.0, blue:244.0, alpha:1.0)
//
//        // No toolbar
//        //        self.navigationController?.toolbarHidden = true
//        //        self.hidesBottomBarWhenPushed = true
//
//        // Save button
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(AmountSettingTVC.saveButtonSelected))
//
//        // tapRecognizer, to withdraw the keyboard when user taps somewhere outside
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(AmountSettingTVC.tap(_:)))
//        tapRecognizer.cancelsTouchesInView = false
//        self.view.addGestureRecognizer(tapRecognizer)
//
//        super.viewDidLoad()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        self.tableView.reloadData()
//        self.navigationController?.isToolbarHidden = true
//        super.viewWillAppear(animated)
//    }
//
//
//
//    //MARK: - Table view data source
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        return 3
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        switch section {
//        case 0, 1, 2:
//            return 1
//        default:
//            return 0
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        var cell: UITableViewCell = UITableViewCell()
//        switch indexPath.section {
//        case 0:
//            cell = tableView.dequeueReusableCell(withIdentifier: "Food Name Cell", for: indexPath)
//            cell.textLabel?.text = food.name
//            //            if let theCell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Food Name Cell", for: indexPath) {
//            //                cell = theCell
//            //                cell.textLabel!.text = food.name
//        //            }
//        case 1:  // The cell with textField, slider and stepper
//            if let theCell = tableView.dequeueReusableCell(withIdentifier: "Amount Cell", for: indexPath) as? AmountSettingTableViewCell {
//                addBondsV4ToCell(theCell)
//                addTargetsToCell(theCell)
//                configureSliderAndStepperForCell(theCell)
//                amount.value = self.amountInGrams  // Trigger the action (although fired already, when dynamics and bonds are define
//                cell = theCell
//            }
//        case 2:
//            let theCell = tableView.dequeueReusableCell(withIdentifier: "Serving Size Cell", for: indexPath)
//            cell = theCell
//            cell.textLabel!.text = food.name
//            cell.detailTextLabel?.text = "12 g"
//        default:
//            fatalError("Could not find an appropriate cell in cellForRowAtIndexPath of AmountSettingTVC. Aborting program.")
//        }
//        return cell
//    }
//
//
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        switch indexPath.section {
//        case 1:
//            return 125.0
//        default:
//            return 44.0
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        switch section {
//        case 0:
//            return 11.0
//        default:
//            return 22.0
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        switch section {
//        case 0:
//            return 11.0
//        case 1:
//            return 44.0
//        default:
//            return 22.0
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        switch section {
//        case 1:
//            return "PORTION"
//        case 2:
//            return "VORDEFINIERTE PORTIONEN"
//        default:
//            return ""
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        switch section {
//        case 2:
//            return "Mehrfach drücken für mehrere Portionen"
//        default:
//            return ""
//        }
//    }
//
//    //MARK: - Navigation from here on
//
//    @objc func saveButtonSelected() {
//
//        amountInGrams = amount.value
//
//        if let item = item {
//            switch item {
//            case .isMealIngredient(let theMealIngredient):
//                // This is the case where the amount of a meal ingredient was changed by the user and has now to be stored properly
//                // convert to milligrams and store
//                theMealIngredient.amount = NSNumber(value: self.amountInGrams as Double)
//
//                // Save and sync to HealthKit
//                saveContextAndsyncToHealthKit(theMealIngredient.meal)
//
//                // Jump (i.e. pop) to parent controller
//                self.navigationController?.popViewController(animated: true)
//
//            case .isFood( _, let theMeal):
//                // This is the case, where a food was selected, an amount set for this food and now a meal ingredient has to be created from this food
//                if let theMealIngredient = NSEntityDescription.insertNewObject(forEntityName: "MealIngredient", into: managedObjectContext) as? MealIngredient {
//                    theMealIngredient.food = food
//                    theMealIngredient.amount = NSNumber(value: amountInGrams as Double)
//                    if theMeal != nil {
//                        theMealIngredient.meal = theMeal!
//                    } else { // create new meal if there are no meals existent, yet
//                        theMealIngredient.meal = NSEntityDescription.insertNewObject(forEntityName: "Meal", into: managedObjectContext) as! Meal
//                    }
//                    // Save and sync to HealthKit
//                    saveContextAndsyncToHealthKit(theMealIngredient.meal)
//
//                    // Jump back (i.e. pop) two view controllers (that's kind of the grand parent view controller)
//                    if let viewControllers = self.navigationController?.viewControllers {
//                        print("View controllers: \(viewControllers)")
//                        let index: Int = viewControllers.count - 3;
//                        self.navigationController?.popToViewController(viewControllers[index], animated: true)
//                    }
//                    //                    print("View controllers: \(viewControllers)")
//                    //                    let index: Int = viewControllers.count - 3;
//                    //                    self.navigationController?.popToViewController(viewControllers[index], animated: true)
//                }
//            default: break
//            }
//        }
//
//        // Notify observer used to update the parent (or grand parent view) to which will be popped back
//        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateMealsCDTVCNotification"), object: nil)
//    }
//
//    func saveContextAndsyncToHealthKit(_ meal: Meal) {
//        saveContext()
//        let healthManager = HealthManager()
//        healthManager.syncMealToHealth(meal)
//    }
//
//
//    //MARK: - cell configuration and SwiftBond and target action
//
//    func addBondsV4ToCell(_ cell: AmountSettingTableViewCell) {
//
//        // Use SwiftBond to bind the following items of the cell together, as depicted here:
//        //
//        //                                                                   +-> cell.slider.maximumValue
//        //                                                                   |
//        //     +--> cell.stepper -> cell.slider -> cell.textField -> amount -+-> ---+   (strong references)
//        //     |                                                                    |
//        //     +--------------------------------------------------------------------+   (weak reference)
//        //
//        // Unfortunately adjusting the slider maximum value does not work properly without a trick
//
//        amountCell = cell
//
//        //        let hugo = Observable<Double>(amountInGrams)
//        //            .map{
//        //                debugPrint("amountInGrams: \($0)")
//        //                return Float($0)
//        //            }
//        //            .bindTo(cell.slider.bnd_value)
//
//        amount.map{
//            debugPrint("amount: \($0)")
//            return Float($0)
//            }.bind(to: cell.slider)
//        //            .bindTo(cell.slider.bnd_value)
//
//        // slider -> textField
//        amountCell.slider.reactive.value.observeNext(with:) { value in
//            debugPrint("slider: \(value)")
//            return self.numberFormatter.string(from: NSNumber(value: value as Float)) ?? ""
//        }
//
//        //            .bind(to: amountCell.amountTextField)
//        //        amountCell.slider.bnd_value.map{[unowned self] value in
//        //            debugPrint("slider: \(value)")
//        //            return self.numberFormatter.string(from: NSNumber(value: value as Float)) ?? ""
//        //            }
//        //            .bindTo(amountCell.amountTextField.bnd_text)
//        //            ->> amountCell.amountTextField.bnd_text
//
//        // textField -> amount
//        amountCell.amountTextField.bnd_text
//            .map{ [unowned self] text in
//                debugPrint("TextField: \(text)")
//                if let text = text, let aNumber = self.numberFormatter.number(from: text) {
//                    return aNumber.doubleValue
//                }
//                return 0.0
//            }
//            .bindTo(amount)
//
//        _ = amount.observe{value in print("amount.value \(value)")}
//
//
//    }
//
//
//    func addTargetsToCell(_ theCell: AmountSettingTableViewCell) {
//        // needed to adjust maximum value of slider when slider hits the right boundary
//        // (I don't know how to do this properly with SwiftBond and think it is too complicated and using ordinary target action is more simple)
//        theCell.slider.addTarget(self, action: #selector(AmountSettingTVC.sliderTouchUpInside(_:)), for: UIControlEvents.touchUpInside)
//    }
//
//    func configureSliderAndStepperForCell(_ theCell: AmountSettingTableViewCell) {
//        theCell.slider.minimumValue = 0.0
//        theCell.stepper.maximumValue = CDouble(MAX_AMOUNT_IN_GRAMS) // to be called before value is set (otherwhise, value is capped to standard maximum of 100)
//    }
//
//    //MARK: - slider maximum value adjustment
//
//    @objc func sliderTouchUpInside(_ sender:UISlider) {
//        // Whenever the user ends dragging, switch back to continuous mode (if it was not set already)
//        sender.isContinuous = true
//        adjustSliderMaximumValueIfNecessary(sender)
//    }
//
//    func adjustSliderMaximumValueIfNecessary(_ slider: UISlider) {
//        //        println("adjust slider maximum if necessary from: (\(slider.minimumValue), \(slider.value), \(slider.dynValue.value), \(slider.maximumValue))")
//        // Adjustment of maximum value shall occur, if
//        //    a) slider hits the maximum (i.e. the right border) or
//        //    b) slider hits the minimum (i.e. the left border)
//        if slider.bnd_value.value >= slider.maximumValue || slider.bnd_value.value <= slider.minimumValue {
//            //        if slider.dynValue.value >= slider.maximumValue || slider.dynValue.value <= slider.minimumValue {
//
//            calculateAndSetSliderMaximumValue(slider: slider)
//            //            if slider.dynValue.value >= slider.maximumValue {
//            if slider.bnd_value.value >= slider.maximumValue {
//                // If the slider is at the maximum value, the user has to touch up for seeing the values increment again
//                slider.isContinuous = false
//            }
//        }
//        // TODO: understand and/or fix this. Currently the slider value is set here explicitly from dynValue.
//        // Doing so ensures that the slider maximum value is set correctly when the textField is edited. This does not work properly
//        // otherwhise (To check this, just type in "6" and then "6" again (to receive 66)
//        //        self.amountCell.slider.value = self.amountCell.slider.dynValue.value
//        self.amountCell.slider.value = self.amountCell.slider.bnd_value.value
//        //        println("adjust slider maximum if necessary to: (\(slider.minimumValue), \(slider.value), \(slider.dynValue.value), \(slider.maximumValue))")
//    }
//
//    func calculateAndSetSliderMaximumValue(slider theSlider: UISlider) {
//        // That's what we want for the minimum and maximum value:
//        // [0 ... value (e.g. 7) ... 20] for values of 10 or lower, to be changed, when user hits the left border (i.e. the minimum value)
//        // [0 ... value (e.g. 14) ... 28] for values greater than 10 up to 4999
//        // [0 ... value (e.g. 6000) ... 9999] for numbers equal or greater than 5000
//        //        if theSlider.dynValue.value <= 10.0 {
//        if theSlider.bnd_value.value <= 10.0 {
//            theSlider.maximumValue = 20.0
//        } else {
//            // Should not be greater than MAX_AMOUNT_IN_GRAMS
//            //            theSlider.maximumValue = min( CFloat(theSlider.dynValue.value*2.0), CFloat(MAX_AMOUNT_IN_GRAMS) )
//            theSlider.maximumValue = min( CFloat(theSlider.bnd_value.value*2.0), CFloat(MAX_AMOUNT_IN_GRAMS) )
//        }
//    }
//
//    //MARK: - Tap Gesture Recognizer
//
//    @objc func tap(_ tapRecognizer: UIGestureRecognizer) {
//        self.view.endEditing(true) // force to dismiss the keyboard
//    }
//
//
//    // MARK: - Core Data Saving support
//
//    func saveContext () {
//        if let moc = self.managedObjectContext {
//            var error: NSError? = nil
//            if moc.hasChanges {
//                do {
//                    try moc.save()
//                } catch let error1 as NSError {
//                    error = error1
//                    // Replace this implementation with code to handle the error appropriately.
//                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                    NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
//                    abort()
//                }
//            }
//        }
//    }
//
//}

