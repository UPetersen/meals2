//
//  RecipeEditTVC.swift
//  meals2
//
//  Created by Uwe Petersen on 23.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

// View controller to edit recipe attributes, i.e. weight of the prepared recipe and comment
class RecipeEditTVC: UITableViewController, UITextViewDelegate, UITextFieldDelegate {
    
    var managedObjectContext: NSManagedObjectContext!
    var recipe: Recipe!

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var weightTextField: UITextField!
    
    lazy var numberFormatter: NumberFormatter =  {() -> NumberFormatter in
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        numberFormatter.zeroSymbol = "0"
        numberFormatter.perMillSymbol = nil
        return numberFormatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.text = recipe.food?.name
        commentTextView.text = recipe.comment
        weightTextField.text = textForRecipe(amount: recipe.amount)
        
        // dismiss keyboard on drag
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            let number = NSNumber(value: recipe.amountOfAllIngredients)
            return "Das Gewicht aller Rohzutaten beträgt \(numberFormatter.string(from: number) ?? "??")."
            // Unfortunately I don't manage to change the height of the section footer of this static table view and thus cannot add this text to the footer:
            // "Beim Zubereiten eines Rezeptes kann sich das Gewicht durch erhitzen verringern und dadurch der Nährwertanteil pro 100g erhöhen. Geben sie hier das Gewicht des fertig zubereiteten Gerichts an, damit dies bei der Nährwertberechnung entsprechend berücksichtigt wird."
        }
        return " "
    }
    
    func textForRecipe(amount: NSNumber?) -> String {
        if let amount = recipe.amount {
            return numberFormatter.string(from: amount) ?? ""
        }
        return ""
    }
        
    
    // TextView delegate (delegate itself set in storyboards)
    func textViewDidChange(_ textView: UITextView) {
        recipe.comment = textView.text
    }
    
    @IBAction func nameTextFieldEditingChanged(_ sender: UITextField) {
        recipe.food?.name = sender.text
    }
    
    @IBAction func amountTextFieldEditingChanged(_ sender: UITextField) {
        print("\(String(describing: sender.text))")
        if let text = sender.text {
            recipe.amount = numberFormatter.number(from: text)
        }
    }
    
}

