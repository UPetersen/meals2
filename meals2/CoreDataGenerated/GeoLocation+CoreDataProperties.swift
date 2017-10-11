//
//  GeoLocation+CoreDataProperties.swift
//  meals2
//
//  Created by Uwe Petersen on 02.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//
//

import Foundation
import CoreData


extension GeoLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeoLocation> {
        return NSFetchRequest<GeoLocation>(entityName: "GeoLocation")
    }

    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?

}
