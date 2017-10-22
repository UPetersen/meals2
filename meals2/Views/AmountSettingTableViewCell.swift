//
//  AmountSettingTableViewCell.swift
//  bLS
//
//  Created by Uwe Petersen on 06.06.14.
//  Copyright (c) 2014 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit

@objc final class AmountSettingTableViewCell : UITableViewCell {
    
    // Just the outlets are needed here, for these UI elements to be accessible from the corresponding parent table view controller
    // target action and that stuff is then all handled from within the table view controller
    //
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var stepper: UIStepper!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
