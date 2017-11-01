//
//  HealthManager.swift
//  HKTutorial
//
//  Created by ernesto on 18/10/14.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import Foundation
import HealthKit
import CoreData
import AVFoundation

class HealthManager {
    
    let healthKitStore:HKHealthStore = HKHealthStore()
    
    func authorizeHealthKit(_ completion: ((_ success: Bool, _ error: NSError?) -> Void)!) {
        
        // 1. and 2. Set the types you want to share and read from HK Store
        let healthKitSampleTypesToShare = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)
            ]
            .flatMap{$0 as HKSampleType?}
        
        let healthKitObjectTypesToRead = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)
            ]
            .flatMap{$0 as HKObjectType?}
        
        let healthKitTypesToShare: Set? = Set<HKSampleType>(healthKitSampleTypesToShare)
        let healthKitTypesToRead: Set?  = Set<HKObjectType>(healthKitObjectTypesToRead)
        
        // 3. If the store is not available (for instance, iPad) return an error and don't go on.
        if !HKHealthStore.isHealthDataAvailable() {
            let error = NSError(domain: "UPP.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
            if completion != nil {
                completion(false , error)
            }
            return
        }
        
        // 4.  Request HealthKit authorization
        healthKitStore.requestAuthorization(toShare: healthKitTypesToShare, read: healthKitTypesToRead) { (success, error) -> Void in
            if completion != nil {
                let hugo = error as NSError?
                completion(success, hugo)
            }
        }
    }
    
    func syncMealToHealth(_ meal: Meal) {
        deleteMeal(meal)
        saveMeal(meal)
    }
    
    func saveMeal(_ meal: Meal) {
//        AudioServicesPlaySystemSound (1103)
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available in this Device")
//            let error = NSError(domain: "UPP.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
            return;
        }
        
        print("About to save the object with id: \(meal.objectID)")
        
        let managedObjectContext = meal.managedObjectContext
        let mealMetaData = ["comment": meal.comment ?? "", "CoreDataObjectIDAsURIString": meal.objectID.uriRepresentation().absoluteString]
        
//        let quantityTypeIdentifiers = [HKQuantityTypeIdentifierDietaryEnergyConsumed, HKQuantityTypeIdentifierDietaryCarbohydrates, HKQuantityTypeIdentifierDietaryProtein, HKQuantityTypeIdentifierDietaryFatTotal]
        
        let identifiers = [
            ("totalEnergyCals", HKQuantityTypeIdentifier.dietaryEnergyConsumed),
            ("totalCarb",       HKQuantityTypeIdentifier.dietaryCarbohydrates),
            ("totalProtein",    HKQuantityTypeIdentifier.dietaryProtein),
            ("totalFat",        HKQuantityTypeIdentifier.dietaryFatTotal)]
        
        var samplesSet = Set<HKQuantitySample>()
        
        for identifierTuple in identifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: identifierTuple.1),
                let nutrient = Nutrient.nutrientForKey(identifierTuple.0, inManagedObjectContext: managedObjectContext!) {
                    let quantity = HKQuantity(unit: nutrient.hkUnit, doubleValue: meal.doubleForNutrient(nutrient) ?? 0.0)
                    samplesSet.insert(HKQuantitySample(type: type, quantity: quantity, start: meal.dateOfCreation! as Date, end: meal.dateOfCreation! as Date, metadata: mealMetaData))
            }
        }
        
        //
        // Combine nutritional data into a food correlation
        //
        
        guard let correlationType = HKObjectType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food) else {
            print("Food correlation type not available")
            return
        }
        let mealCorrelation = HKCorrelation(type: correlationType, start: meal.dateOfCreation! as Date, end: meal.dateOfCreation! as Date, objects: samplesSet, metadata: mealMetaData)
        
        // 2. Save the sample in the store
        healthKitStore.save(mealCorrelation, withCompletion: { (success, error) -> Void in
            if( error != nil ) {
                print("Error saving carb sample: \(error!.localizedDescription)")
            } else {
                print("Saved food correlation successfully!")
            }
            print("Executed health save meal query")
            AudioServicesPlaySystemSound (1105)
        })
    }
    
    
    func deleteMeal(_ meal: Meal) {
//        AudioServicesPlaySystemSound (1113)
        if !HKHealthStore.isHealthDataAvailable(){
//            let error = NSError(domain: "UPP.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
            print("HealthKit is not available in this Device")
            return;
        }
        
        print("About to delete the meal with object ID: \(meal.objectID)")
        
        let predicate = HKQuery.predicateForObjects(withMetadataKey: "CoreDataObjectIDAsURIString", allowedValues: [meal.objectID.uriRepresentation().absoluteString])
        
        if let sampleType = HKSampleType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food) {
            let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 0, sortDescriptors: nil, resultsHandler:
                { (sampleQuery, results, error ) -> Void in
                    if let results = results {
                        let foodCorrelations = results
                            .flatMap{$0 as? HKCorrelation}
                            .filter {$0.correlationType == HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)! as HKCorrelationType}
                        
                        // for each food correlation delete its objects
                        for foodCorrelation in foodCorrelations {
                            for object in foodCorrelation.objects {
                                self.healthKitStore.delete(object, withCompletion:{(success, error) -> Void in
                                    if success {
                                        return
                                    }
                                })
                            }
                            
                            // delete the food correlation object itself
                            self.healthKitStore.delete(foodCorrelation, withCompletion:{(success, error) -> Void in
                                if success {
                                    print("Deleted a food correlation.")
                                    return
                                }
                                print("Error. Could not delete a food correlation.")
                            })
                        }
                    }
                    print("Executed health delete query")
                    AudioServicesPlaySystemSound (1114)
            })
            // 5. Execute the Query
            self.healthKitStore.execute(sampleQuery)
        }
    }
    
    
//    func readNutrientData (_ date: Date, completion: ((HKCorrelation?, NSError?) -> Void)!) {
//
//        if !HKHealthStore.isHealthDataAvailable(){
////            let error = NSError(domain: "UPP.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
//            print("HealthKit is not available in this Device")
//            return;
//        }
//
//        guard let sampleType = HKSampleType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food) else {
//            fatalError("Wrong identifier for food correlation")
//        }
////        let sampleType = HKSampleType.correlationTypeForIdentifier(HKCorrelationTypeIdentifierFood)
//        let options = HKQueryOptions()
//
//        let startDate = Date(timeInterval: -60, since: date)
//        let endDate = Date(timeInterval: 60, since: date)
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: options)
//
//        // query with completion handler (wherein another completion handler is called
//        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 0, sortDescriptors: nil, resultsHandler:
//            {(sampleQuery, results, error ) -> Void in
////                { [unowned self] (sampleQuery, results, error ) -> Void in
//
//                if let queryError = error {
//                    print( "There was an error while reading the samples: \(queryError.localizedDescription)")
//                    completion(nil, error as NSError?)
//                }
//
//                if let results = results {
//                    let foodCorrelations = results
//                        .flatMap{$0 as? HKCorrelation}
//                        .filter {$0.correlationType == HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)! as HKCorrelationType}
//
//                    if foodCorrelations.count > 1 {
//                        print("Number of food correlation objects is \(foodCorrelations.count), which is greater than one, which should not happen.")
//                        print("Aborting program. Please check and correct your database, Uwe.")
//                        abort()
//                    }
//
//                    for foodCorrelation in foodCorrelations {
//                        print("About to call completion")
//
//                        completion(foodCorrelation, nil)
//                        print("... done with call to completion")
//                    }
//                }
//            })
//        // 5. Execute the Query
//        self.healthKitStore.execute(sampleQuery)
//    }
    
    
}
