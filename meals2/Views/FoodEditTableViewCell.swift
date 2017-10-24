//
//  FoodEditTableViewCell.swift
//  meals2
//
//  Created by Uwe Petersen on 23.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit

@objc final class FoodEditTableViewCell: UITableViewCell {
    
    // Just the outlets are needed here, for these UI elements to be accessible from the corresponding parent table view controller
    // target action and that stuff is then all handled from within the table view controller
    
    @IBOutlet weak var LeftDetailTextLabel: UILabel!
    @IBOutlet weak var RightDetailTextField: UITextField!
}
