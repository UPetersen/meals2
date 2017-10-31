//
//  BlsToCoreDataImporter.swift
//  meals
//
//  Created by Uwe Petersen on 27.12.14.
//  Copyright (c) 2014 Uwe Petersen. All rights reserved.
//

import Foundation
import CoreData
import UIKit


struct TextFileData {
    let propertyNames: [String]
    let propertyTypes: [String]
    let dataAsStrings: [String]
}

final class BlsToCoreDataImporter {
    
    let documentsDirectory: URL
    var context: NSManagedObjectContext
    
    let LINE_DELIMITER = "\n"
    let VALUE_DELIMITER = "\t"
    let BLS_SOURCE = "BLS 3.02 (2015)"
    
    let numberFormatter: NumberFormatter
    
    init(documentsDirectory: URL, managedObjectContext context: NSManagedObjectContext) {
        self.documentsDirectory = documentsDirectory
        self.context = context
        
        self.numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = ","
    }
    
    // Do this only once and succesful to import core data data
    // If not successfull, repeat next time
    // What is successfull?
    //  Well, read all files into data base and created all connections
    // Once data was imported successfully, denote this in NSUserDefaults, together with den BSL-Version, delete the text files, since they are not needed any more and don't call the importer any more

    func importBLS() -> Bool {
        
        let startTimeForReading = Date()
        print("Step 1: Reading BLS-Files and storing content into core data ...")
        let readSuccess = readTextFilesAndStoreContentIntoDatabaseEntities()
        print("... done with step 1 within \(self.timeIntervalSince(startTimeForReading)) s.\n")
          
        if readSuccess {
            let startTimeForSettingConnections = Date()
            print("Step 2: Setting up connections for food items according to BLS-key information ...")
            createConnectionsForFood()
            print("... done with step 2 within \(self.timeIntervalSince(startTimeForSettingConnections)) s.\n")
        } else {
            print("Skipping step 2 due to error in step 1.\n")
        }
        
        return readSuccess
    }
    
    func readTextFilesAndStoreContentIntoDatabaseEntities() -> Bool {
        let entities = ["Food", "Group", "SubGroup", "Preparation", "Nutrient", "ReferenceWeight", "Detail"] // Convention: corresponding files are named ".csv" (e.g. "Group.csv")
        let propertiesForComparison = [
            "Group": ["key"],
            "SubGroup": ["key"],
            "Food": ["key"],
            "Nutrient": ["key"],
            "Detail": ["key","detailType"],
            "Preparation": ["key", "preparationType"],
            "ReferenceWeight": ["key"]
        ]
        
        var readSuccess = true
        
        for entity in entities {
            let start = Date()
            
            let urlForEntity = self.documentsDirectory.appendingPathComponent(entity + ".csv")
            let propertiesForComparison_ = propertiesForComparison[entity]!
            
            autoreleasepool{
                let finalResult = fileAsOneBigStringForUrl(urlForEntity)
                    .flatMap({ [unowned self] in self.textFileDataForFileAsOneBigString($0) })
                    .flatMap({ [unowned self, entity, propertiesForComparison_] in self.storeTextFileData($0, forEntity: entity, withPropertiesForComparison: propertiesForComparison_, inManagedObjectContext: self.context) })
                
                // Report Success or Failure
                switch finalResult {
                case .success( _):
                    print("Successfully handled entity '\(entity)'")
                case .failure(let error):
                    readSuccess = false
                    print(error.unbox)
                }
            }
            print("\(  self.timeIntervalSince(start)) s elapsed for entity '\(entity)'")
        }
        return readSuccess
    }
    
    func timeIntervalSince(_ start: Date) -> Double {
        let end = Date()
        let timeInterval: Double = end.timeIntervalSince(start);
        return timeInterval
    }
    
    func fileAsOneBigStringForUrl(_ url: URL) -> Result<String, NSError> {
        do {
            let fileAsString = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String
            if fileAsString.isEmpty {
                fatalError("Error in '\(#function)': File at url '\(url)' is empty")
            }
            print("Read file '\(url)'.")
            return success(fileAsString)
        } catch {
            return failure(error as NSError)
        }
    }
    
    func textFileDataForFileAsOneBigString(_ string: String) -> Result<TextFileData,NSError> {
        var lines = string.components(separatedBy: self.LINE_DELIMITER)
        if (lines.last?.isEmpty != nil) {
            lines.removeLast()  // Last line may be empty due to extra line feed
        }
        
        if lines.count >= 3 { // two lines of header info (property names and property types) and at least one line of data
            
            let propertyNames = lines[0].components(separatedBy: self.VALUE_DELIMITER) // e.g. "key", "name", "nameEnglish", ...
            let propertyTypes = lines[1].components(separatedBy: self.VALUE_DELIMITER) // e.g. "TEXT", "TEXT", "TEXT", "FLOAT", ...
            let dataAsStrings = Array(lines[2 ..< lines.count])
            
            print("Read \(lines.count-2) lines of data.")
            return success(TextFileData(propertyNames: propertyNames, propertyTypes: propertyTypes, dataAsStrings: dataAsStrings))
            
        } else {
            fatalError("File contains less than three lines, i.e. no data. File may be empty or corrupt.")
        }
    }
    
    
    func storeTextFileData(_ textFileData: TextFileData, forEntity entity: String, withPropertiesForComparison comparisonProperties: [String], inManagedObjectContext context: NSManagedObjectContext) -> Result<Bool, NSError> {
        
        let objectsAlreadyStored = self.fetchAllObjectsForEntity(entity, inManagedObjectContext: context)
        
        let finalResult = objectsAlreadyStored.flatMap{[unowned self, entity, comparisonProperties, context] in
            self.storeTextFileDataNotAlreadyStored(textFileData, objectsAlreadyStored: $0!, forEntity: entity, withPropertiesForComparison: comparisonProperties, inManagedObjectContext: context)
        }
        return finalResult
    }
    
    
    // Returns the keyPropertys, i.e the string stored in the column (property) "key" of an Entity (i.e. an Object) in the core data database
    func fetchAllObjectsForEntity(_ entityName: String, inManagedObjectContext context: NSManagedObjectContext) -> Result<[NSManagedObject]?, NSError> {
            
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)  // init with entityName, e.g. "Group" or "Food"
        let sortDescriptor = NSSortDescriptor(key: "key", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "name", ascending: true)
        
        request.sortDescriptors = [sortDescriptor, sortDescriptor2]
        
        // fetch (complete) objects
        do {
            if let fetchedObjects = try context.fetch(request) as? [NSManagedObject] {
                print("Number of objects stored in database: \(fetchedObjects.count)")
                return success(fetchedObjects)
            } else {
                print("No objects found in database.")
                return success(nil)
            }
        } catch {
            return failure(error as NSError)
        }
    }
    
    
    func storeTextFileDataNotAlreadyStored(_ textFileData: TextFileData, objectsAlreadyStored: [NSManagedObject], forEntity entity: String, withPropertiesForComparison comparisonProperties: [String], inManagedObjectContext context: NSManagedObjectContext) -> Result<Bool, NSError> {
        var objectsAlreadyStored = objectsAlreadyStored
        
        var result:Result<Bool,NSError> = success(true)
        
        // Lopp over all textFileData lines, each line representing one new object potentially to be stored in the database
        var nObjects = 0
        var savedAtNThousandObjects = 0.0
        for lineWithObjectData in textFileData.dataAsStrings {
            
            autoreleasepool {
                
                let values = lineWithObjectData.components(separatedBy: self.VALUE_DELIMITER)
                if values.count <= 1 {
                    print("Reached end of textFileData")
                    //                return success(true) // end of file
                } else {
                    let objectIsAlreadyStored = isAlreadyStored(objectValues: values, propertyNames: textFileData.propertyNames, comparisonProperties: comparisonProperties, storedObjects: &objectsAlreadyStored)
                    
                    result = objectIsAlreadyStored
                        .flatMap{ [unowned self, values, textFileData, context] (objectIsAlreadyStored) in
                            if !objectIsAlreadyStored {
                                
                                let storageResult = self.storeObjectForEntityForName(entity, values: values, propertyNames: textFileData.propertyNames, propertyTypes: textFileData.propertyTypes, inManagedObjectContext: context)
                                return storageResult
                            }
                            return success(true)
                    }
                    if result.isSuccess {
                        nObjects += 1
                    }
                }
            }
            // save context after each 1000 lines, this is a compromise to reduce ovarall memory and computing time
            if floor(Double(nObjects) / 1000.0) > savedAtNThousandObjects {
                savedAtNThousandObjects += 1
                self.saveContext(managedObjectContext: context)
                print("Saved context after processing \(nObjects) Objects.")
            }
        }
        self.saveContext(managedObjectContext: context)
        print("Stored \(nObjects) new objects.")
        return success(true)
//        return result
    }
    
    
    func isAlreadyStored(objectValues: [String], propertyNames: [String], comparisonProperties: [String], storedObjects: inout [NSManagedObject]) -> Result<Bool,NSError> {
        // Check, if object is alread stored. Do this for a tuple of object properties, that are to be compared
        for index in 0 ..< storedObjects.count {
            
            let theBool = self.objectsAreEqual(storedObject: storedObjects[index], objectToStoreValues: objectValues, objectToStorePropertyNames: propertyNames, comparisonProperties: comparisonProperties)
            
            if theBool.isSuccess && theBool.value! == true {
                storedObjects.remove(at: index)
                return success(true)
            }
            if !theBool.isSuccess {
                print("\(theBool.description)")
                return theBool
            }
        }
        return success(false)
    }
    
    
    /// Check if stored properties and new properties are equal by comparing a set of comparison properties
    func objectsAreEqual(storedObject: NSManagedObject, objectToStoreValues: [String], objectToStorePropertyNames: [String], comparisonProperties: [String]) -> Result<Bool,NSError> {
        
        for comparisonProperty in comparisonProperties {
            
            let storedValue: AnyObject? = storedObject.value(forKey: comparisonProperty) as AnyObject
            if let index = objectToStorePropertyNames.index(of: comparisonProperty) {

                let newValue = objectToStoreValues[index]
                
                switch storedValue {
                case let storedValue as String:
                    if storedValue != newValue {
                        return success(false)
                    }
                case let storedValue as Int:
                    if storedValue != Int(newValue) {
                        return success(false)
                    }
                default:
                    fatalError("Comparison Property of value '\(String(describing: storedValue))' is neither String nor int.")
                }
            } else {
                fatalError("Property '\(comparisonProperty)' not found in list of property names ('\(objectToStorePropertyNames)')")
            }
        }
        return success(true)  // for all properties that where checked
    }
    
    
    
    func storeObjectForEntityForName(_ entityName: String, values: [String], propertyNames: [String], propertyTypes: [String], inManagedObjectContext context: NSManagedObjectContext) -> Result<Bool,NSError> {
        
        // create core data object for the group and set properties using values from the data file (i.e. the current line)
        let object: AnyObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        
        for iValue in 0 ..< values.count {
            autoreleasepool {
                switch propertyTypes[iValue] {
                case "REAL":
                    let aString = values[iValue]
                    let aNumber = numberFormatter.number(from: aString)
                    object.setValue(aNumber, forKey: propertyNames[iValue])
                    
                case "TEXT":
                    object.setValue(values[iValue], forKey: propertyNames[iValue])
                    
                case "INTEGER":
                    object.setValue(Int(values[iValue]), forKey: propertyNames[iValue])
                    
                default:
                    fatalError("Error: propertyType '\(propertyTypes[iValue])' is neither 'REAL', 'TEXT' nor 'INTEGER' as is required. File may be corrupt.")
                }
            }
        }
        return success(true)
    }
    
    
    func createBLSSourceIfNotAlreadyStored(inManagedObjectContext context: NSManagedObjectContext) -> Source {

        // Same source for all BLS data, but check if this source already exists (if not, create it)
        let knownSources = Source.fetchSourcesForName(BLS_SOURCE, managedObjectContext: context)
        if knownSources != nil && !knownSources!.isEmpty  {
            return knownSources!.first!
        } else {
            return Source.createSourceWithName(BLS_SOURCE, inManagedObjectContext: context) as Source
        }
    }

    func createConnectionsForFood() {
        
        // Same source for all BLS data, but check if this source already exists (if not, create it)
        let source = createBLSSourceIfNotAlreadyStored(inManagedObjectContext: context)
        
        let fetchedFoods = Food.fetchAllFoods(managedObjectContext: context)
        if let fetchedFoods = fetchedFoods {
            
            print("Undomanager is \(String(describing: context.undoManager))")
            if context.undoManager != nil {
                print("ist an")
            }
            
            _ = SubGroup.fetchAllSubGroups(managedObjectContext: context)
            
            var nObjects = 0
            var savedAtNThousandObjects = 0.0
            for food in fetchedFoods {
                autoreleasepool {
                    if let foodKey = food.key {
                        if !foodKey.isEmpty { // Only foods that have a BLS-key (and are, thus, incorporated from text files)
                            //                    println("\(food.name)")
                            nObjects += 1
                            // 1st Pos.: Set the group
                            if let group = Group.fetchGroupForBLSGroupKey(foodKey[0...0], inManagedObjectContext: context) as Group? {
                                food.group = group
                            }
                            
                            // 1st and 2nd Pos.: set the subGroup
                            //                    println("food.name: '\(food.name)', key: '\(foodKey)'")
                            if let subGroup = SubGroup.fetchSubGroupForBLSSubGroupKey(foodKey[0...1], inManagedObjectContext: context) {
                                food.subGroup = subGroup
                                //                        println("food.subGroup: \(food.subGroup.key)")
                            } else {
                                print(" Could not find subgroupkey")
                            }
                            
                            
                            // 3rd and 4th Pos.: Set the consecutive number as String, we need it as string and as NSNumber/Int to later be able to sort using it
                            food.consecutiveNumberAsString = foodKey[2...3]  // 3rd and 4th Pos.: Set the consecutive number as String
                            
                            
                            // 5th Pos.: Set the detail (MUST BE DONE AFTER SETTING THE SUBGROUP)
                            //                    println("food.subGroupKey: \(food.subGroup.key)")
                            if let key = food.subGroup?.key {
                                if let detail = Detail.fetchDetailForBLSGroupKey(foodKey[4...4], andSubGroupKey: key, inManagedObjectContext: context) {
                                    food.detail = detail
                                    //                        println("\(detail.description)")
                                    //                        println("food.detail: '\(food.detail.key)'")
                                }
                            }
                            
                            // 6th Pos.: Set the preparation information (MUST BE DONE AFTER SETTING THE SUBGROUP AND THE GROUP)
                            if let key = food.group?.key {
                                if let preparation = Preparation.fetchPreparationForBLSPreparationKey(foodKey[5...5], andGroupKey: key, inManagedObjectContext: context) {
                                    food.preparation = preparation
                                }
                            } else {
                                print("SubGroup is unexpectedly nil. This should not happen, since all BLS foods should have a group. Review the data.")
                                abort()
                            }
                            
                            // 6th Pos.: Replace e.g. the string "(1)" at the end of food.name with the corresponding preparation, e.g. "(Zubereitung im Haushalt)"
                            replaceSixthBLSKeyPosInBracesWithPreparationNameForGroupsXAndYForFood(food)
                            
                            // 7th Pos.: Set the reference weight
                            if let referenceWeight = ReferenceWeight.fetchReferenceWeightForBLSReferenceWeightKey(foodKey[6...6], inManagedObjectContext: context) {
                                food.referenceWeight = referenceWeight
                            }
                            food.source = source
                        }
                    }
                }
                // save context after each 1000 lines, this is a compromise to reduce ovarall memory and computing time
                if floor(Double(nObjects) / 1000.0) > savedAtNThousandObjects {
                    savedAtNThousandObjects += 1
                    self.saveContext(managedObjectContext: context)
                    print("Saved context after processing \(nObjects) Objects.")
                }
            }
        }
        self.saveContext(managedObjectContext: context)
    }

    /// For foods of the groups "X" and "Y":
    /// Replace e.g. the string "(1)" at the end of food.name with the corresponding preparation, e.g. "(Zubereitung im Haushalt)"
    /// "(0)" is not replaced but just deleted since it denotes "Andere und ohne Angaben" and is thus not very useful but rather anoying information
    func replaceSixthBLSKeyPosInBracesWithPreparationNameForGroupsXAndYForFood(_ food:Food) {
        
        if let key = food.group?.key, let preparationName = food.preparation?.name, var foodName = food.name {
            switch key {
            case "X", "Y":
                
                let range = NSRange(location: 0, length: foodName.characters.count)
                
                // Search for e.g. "(1)" or "(4)" at the end of a line ("$" is for end of line)
                do {
                    let regex = try NSRegularExpression(pattern: "\\([1-6]{1}\\)$", options: [])
                    foodName = regex.stringByReplacingMatches(in: foodName, options: [], range: range, withTemplate: "(\(preparationName))")
                } catch _ as NSError {
                }
                
                // Search for "(0)" at the end of a line ("$" is for end of line)
                do {
                    let regex = try NSRegularExpression(pattern: "\\([0]{1}\\)$", options: [])
                    foodName = regex.stringByReplacingMatches(in: foodName, options: [], range: range, withTemplate: "")
                    //                println("food: \(food.name)")
                } catch _ as NSError {
                }
                food.name = foodName
            default:
                break
            }
        } else {
            print("SubGroup is unexpectedly nil. This should not happen, since all BLS foods should have a group. Review the data.")
            abort()
        }
    }


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



