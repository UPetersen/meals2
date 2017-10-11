//
//  ServingSize+CoreDataProperties.swift
//  meals2
//
//  Created by Uwe Petersen on 02.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//
//

import Foundation
import CoreData


extension ServingSize {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ServingSize> {
        return NSFetchRequest<ServingSize>(entityName: "ServingSize")
    }

    @NSManaged public var amount: NSNumber?
    @NSManaged public var label: String?
    @NSManaged public var food: Food?

}
