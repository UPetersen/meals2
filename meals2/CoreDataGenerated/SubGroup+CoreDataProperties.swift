//
//  SubGroup+CoreDataProperties.swift
//  meals2
//
//  Created by Uwe Petersen on 02.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//
//

import Foundation
import CoreData


extension SubGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SubGroup> {
        return NSFetchRequest<SubGroup>(entityName: "SubGroup")
    }

    @NSManaged public var key: String?
    @NSManaged public var name: String?
    @NSManaged public var nameEnglish: String?
    @NSManaged public var subGroupKey: NSNumber?
    @NSManaged public var foods: NSSet?

}

// MARK: Generated accessors for foods
extension SubGroup {

    @objc(addFoodsObject:)
    @NSManaged public func addToFoods(_ value: Food)

    @objc(removeFoodsObject:)
    @NSManaged public func removeFromFoods(_ value: Food)

    @objc(addFoods:)
    @NSManaged public func addToFoods(_ values: NSSet)

    @objc(removeFoods:)
    @NSManaged public func removeFromFoods(_ values: NSSet)

}
