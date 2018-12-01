//
//  UIAlertControllerExtension.swift
//  meals
//
//  Created by Uwe Petersen on 09.09.15.
//  Copyright © 2015 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit


extension UIAlertController {
    class func alertControllerForLists(title: String?, message: String?, itemTitles: [String], fromBarButtonItem barButtonItem: UIBarButtonItem?, handler: ((UIAlertAction) -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.actionSheet)
        
        // items, i.e. actions
        for itemTitle in itemTitles {
            alertController.addAction(UIAlertAction(title: itemTitle, style: .default, handler: handler))
        }
        alertController.addAction( UIAlertAction(title: "Zurück", style: .cancel) {(action) in print("Cancel Action")})
        
        // For iPad only: must be popover and have a presentation controller
        if barButtonItem != nil  {
            alertController.modalPresentationStyle = UIModalPresentationStyle.popover  // for iPad only
            alertController.popoverPresentationController?.barButtonItem = barButtonItem
        }
        return alertController
    }
    
}
