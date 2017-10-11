//
//  FoodDetails.swift
//  bLS
//
//  Created by Uwe Petersen on 18.06.14.
//  Copyright (c) 2014 Uwe Petersen. All rights reserved.
//

import Foundation
import CoreData
import HealthKit



/// Intermediate Model/Class,for rows to be displayed in aFood Display Tableview in order to make
/// the corresponding table view controller more simple
///
/// - parameter name: String, e.g. "Fat"
/// - parameter value: NSNumber, e.g. 100
/// - parameter unit: String, e.g. "g"
/// - parameter key: String, e.g. "totalCarbs (key to obtain the nutrient out of a nutrient object


final class InformationDataRecord:DataRecord {
    init(information:String?, detail: String?) {
        super.init(textLabel: information, detailTextLabel: detail)
    }
}

final class NutrientDataRecord:DataRecord {
    
    var nutrient: Nutrient

    init(nutrient: Nutrient, food: Food, numberFormatter: NumberFormatter) {
        self.nutrient = nutrient
        let value = food.doubleForKey(nutrient.key!)
        
        let text = nutrient.name
        let detailText = nutrient.dispStringForValue(value, formatter: numberFormatter, showUnit: true)
        
        super.init(textLabel: text, detailTextLabel: detailText)
    }
    
    init (nutrient: Nutrient, item: HasNutrients, numberFormatter: NumberFormatter) {
        self.nutrient = nutrient
        let value = item.doubleForKey(nutrient.key!)
        
        let text = nutrient.name
        let detailText = nutrient.dispStringForValue(value, formatter: numberFormatter, showUnit: true)
        super.init(textLabel: text, detailTextLabel: detailText)
    }
}

class DataRecord {
    var textLabel: String?
    var detailTextLabel: String?
    
    init(textLabel: String?, detailTextLabel: String?) {
        self.textLabel = textLabel
        self.detailTextLabel = detailTextLabel
    }
}

//Class Section {
final class Section {
    var title: String?
    var footer:String?
    var rows: [DataRecord]?
    init(title: String, footer: String, rows: [DataRecord]) {
        self.title = title
        self.footer = footer
        self.rows = rows
    }
}

/// View model for table view controller that display nutrient data and metadata for
/// an item that has nutrients (connforms to the HasNutrient protocol). 
/// This can be a food, a meal or a recipe.
final class FoodDetails {
   
    var managedObjectContext: NSManagedObjectContext
    var item: HasNutrients
    var amountString: String!
    
    lazy var numberFormatter: NumberFormatter =  {() -> NumberFormatter in
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        numberFormatter.zeroSymbol = "0"
        return numberFormatter
        }()
    
//   We need a lazy property here, only calculated once, this can be done in various ways:
//
//   LAZY PROPERTY WITH A CLOSURE (THIS IS NOT A GETTER) -> Works, only called once
//   lazy var moreSections: [Section] = {() -> [Section] in
//      var theMoreSections:[Section] = [Section]()
//       ...
//      return theMoreSections
//      }()
//
//   LAZY GETTER CONSTRUCT WITH TWO PROPERTIES -> Works, only called once
//   var _sections: [Section]? = nil
//   var sections: [Section] {
//      if _sections == nil {
//         var theSections:[Section] = [Section]()
//         ...
//         _sections = theSections
//      }
//      return _sections!
//   }
//   USING A METHOD (definetly lazy), BUT NEEDS A PROPERTY -> Works
//   lazy var lastSections: [Section] = self.tableSections()
//   func tableSections () -> [Section] {
//      var theSections:[Section] = [Section]()
//      ...
//      return theSections
//   }
//
//   COMPUTED PROPERTY WITH GETTER -> Nope, called each time
//   var sectionsTest: [Section] {
//      get {
//         var theSections:[Section] = [Section]()
//         ...
//         return theSections
//      }
//   }

    var _sections: [Section]? = nil // This var needed for the lazy getter, otherwhise it does not work
    
    var sections: [Section] { // Lazy getter for the sections, the property we actually desire and do this whole thing for
        if _sections == nil {
            
//            configureAmountString(item)
            
            // Definition of the sections. They will later be displayed in the same order
            var theSections:[Section] = [Section]()
            
            // Section mit den allgemeinen Nährwerten
            theSections.append(
                sectionForKeys(
                    ["totalEnergyCals", "totalCarb", "totalProtein", "totalFat", "totalAlcohol", "totalDietaryFiber", "totalMineralsInRawAsh","totalOrganicAcids","totalWater", "totalSalt"],
                    title: "Grund-Nährwerte je 100 g",
                    footer: "")
            )
            
            // Section mit allgemeinen Daten
            let rows = configureMetadataRows(item)
            if let rows = rows {
                theSections.append(Section(title: "Allgemeine Informationen", footer: "", rows: rows))
            }
            
            print("amount string \(amountString)")
            
            // Section mit Ein- und Zweifachzuckern
            theSections.append(
                sectionForKeys(
                    ["carbGlucose",  "carbFructose", "carbGalactose", "carbMonosaccharide", "carbSucrose", "carbMaltose", "carbLactose", "carbDisaccharide", "carbSugar"],
                    title: "Ein-/Zweifachzucker je 100 g",
                    footer: "")
            )

            //Section mit Zuckeralkoholen
            theSections.append(
                sectionForKeys(
                    ["carbMannitol", "carbSorbitol", "carbXylitol", "carbSugarAlcohol"],
                    title: "Zuckeralkohole je 100 g",
                    footer: "")
            )
            
            //Section mit höherwertigen KH
            theSections.append(
                sectionForKeys(
                    ["carbOligosaccharideResorbable", "carbOligosaccharideNonResorbable", "carbGlycogen", "carbStarch", "carbPolysaccharide", "carbPolyPentose", "carbPolyHexose", "carbPolyUronicAcid", "carbCellulose", "carbLignin", "carbWaterSolubleDietaryFiber", "carbWaterInsolubleDietaryFiber"],
                    title: "HÖHERWERTIGE KH JE 100 g",
                    footer: "")
            )
            
            //Section mit Fetten
            theSections.append(
                sectionForKeys(
                    ["fattyAcidPolyunsaturatedFattyAcids", "fattyAcidShortChainFattyAcids", "fattyAcidMediumChainFattyAcids", "fattyAcidLongChainFattyAcids", "fattyAcidOmega3FattyAcids", "fattyAcidOmega6FattyAcids", "fattyAcidGlycerin", "fattyAcidCholesterol"],
                    title: "FETTE JE 100 g",
                    footer: "")
            )
            
            //Section mit Mineralien
            theSections.append(
                sectionForKeys(
                    ["mineralSodium", "mineralPotassium", "mineralCalcium", "mineralMagnesium", "mineralPhosphorus", "mineralSulphur", "mineralChlorine"],
                    title: "MINERALIEN JE 100 g",
                    footer: "")
            )
            
            //Section mit Spurenelementen
            theSections.append(
                sectionForKeys(
                    ["elementIron", "elementZinc", "elementCopper", "elementManganese", "elementFluorine", "elementIodine"],
                    title: "SPURENELEMENTE JE 100 g",
                    footer: "")
            )
            
            //Section mit Vitaminen
            theSections.append(
                sectionForKeys(
                    ["vitaminA", "vitaminARetinol", "vitaminABetaCarotene", "vitaminD", "vitaminE", "vitaminETocopherol", "vitaminK", "vitaminB1", "vitaminB2", "vitaminB3Niacin", "vitaminB3", "vitaminB5", "vitaminB6", "vitaminB7", "vitaminB9", "vitaminB12", "vitaminC"],
                    title: "VITAMINE JE 100 g",
                    footer: "")
            )
            
            //Section mit Aminosäuren
            theSections.append(
                sectionForKeys(
                    ["aminoAcidIsoleucine", "aminoAcidLeucine", "aminoAcidLysine", "aminoAcidMethionine", "aminoAcidCysteine", "aminoAcidPhenylalanine", "aminoAcidTyrosine", "aminoAcidThreonine", "aminoAcidTryptophan", "aminoAcidValine", "aminoAcidArginine", "aminoAcidHistidine", "aminoAcidEssentialAminoAcids", "aminoAcidAlanine", "aminoAcidAsparticAcid", "aminoAcidGlutamicAcid", "aminoAcidGlycine", "aminoAcidProline", "aminoAcidSerine", "aminoAcidNonEssentialAminoAcids", "aminoAcidUricAcid", "aminoAcidPurine"],
                    title: "AMINOSÄUREN JE 100 g",
                    footer: "")
            )
            
            //Section mit Fettsäuren
            theSections.append(
                sectionForKeys(
                    ["fattyAcidButyricAcid", "fattyAcidHexanoicAcid", "fattyAcidOctanoicAcid", "fattyAcidDecanoicAcid", "fattyAcidDodecanoicAcid", "fattyAcidTetradecanoicAcid", "fattyAcidPentadecanoicAcid", "fattyAcidHexadecanoicAcid", "fattyAcidHeptadecanoicAcid", "fattyAcidOctadecanoicAcid", "fattyAcidEicosanoicAcid", "fattyAcidDocosanoicAcid", "fattyAcidTetracosanoicAcid", "fattyAcidSaturatedFattyAcids", "fattyAcidTetradecenoicAcid", "fattyAcidPentadecenoicAcid", "fattyAcidHexadecenoicAcid", "fattyAcidHeptadecenoicAcid", "fattyAcidOctadecenoidAcid", "fattyAcidEicosenoicAcid", "fattyAcidDocosenoicAcid", "fattyAcidTetracosenoicAcid", "fattyAcidMonounsaturatedFattyAcids", "fattyAcidHexadecadieonicAcid", "fattyAcidHexadecatetraenoicAcid", "fattyAcidOctadecadienoicAcid", "fattyAcidOctadecatrienoicAcid", "fattyAcidOctadecatetraenoicAcid", "fattyAcidNonadecatrienoicAcid", "fattyAcidEicosadienoicAcid", "fattyAcidEicosatrienoicAcid", "fattyAcidEicosatetraenoicAcid", "fattyAcidEicosapentaeonoicAcid", "fattyAcidDocosadienoicAcid", "fattyAcidDocosatrienoicAcid", "fattyAcidDocosatetraenoicAcid", "fattyAcidDocosapentaenoicAcid", "fattyAcidDocosahexaenoicAcid"],
                    title: "FETTSÄUREN JE 100 g",
                    footer: "")
            )
            
            _sections = theSections
        }
        return _sections!
    }
    
    
    // #pragma mark - initizalizer
    
    
    /// Initializer
    ///
    /// - parameter managedObjectContext: context of the item
    /// - parameter item: item that conforms to HasNutrients protocol (i.e. is Food, Meal or Recipe)
    init(managedObjectContext:NSManagedObjectContext, item: HasNutrients) {
        //    init(managedObjectContext:NSManagedObjectContext, food:Food, item: HasNutrients, amountInGrams:Double=100.0) {
        
        self.managedObjectContext = managedObjectContext
        self.item = item
        //        self.amountInGrams = amountInGrams
    }
    
    
    // MARK: - helper stuff
    
    func sectionForKeys(_ keys:[String], title:String, footer:String) -> Section {
        
        // Get the nutrients for the keys (i.e. "totalCarb", ...), but only those that are not nil, and then construct a row
        let rows = keys.filter {!$0.isEmpty}    // only non-nil keys
//        let rows = keys.filter {$0 != nil}    // only non-nil keys
            .map {[unowned self] in Nutrient.nutrientForKey($0, inManagedObjectContext: self.managedObjectContext)! }   // nutrients for these non-nil keys
//            .map {[unowned self] in NutrientDataRecord(nutrient: $0 as Nutrient, food: self.food, numberFormatter: self.numberFormatter)} // the final row for these nutrients
            .map {[unowned self] in
                //                NutrientDataRecord(nutrient: $0 as Nutrient, food: self.food, numberFormatter: self.numberFormatter)
                NutrientDataRecord(nutrient: $0 as Nutrient, item: self.item as HasNutrients, numberFormatter: self.numberFormatter)
        } // the final row for these nutrients
        
        
        return Section(title: title, footer: footer, rows: rows)
    }
    
    func configureMetadataRows(_ item: HasNutrients) -> [InformationDataRecord]?{
        switch item {
        case let food as Food:
            return configureMetadataRowsForFood(food)
        case let meal as Meal:
           return configureMetadataRowsForMeal(meal)
        case _ as Recipe:
            return nil
        default:
            fatalError("Unknown type for item \(item)")
        }
    }
    
    func configureMetadataRowsForFood(_ food: Food) -> [InformationDataRecord] {
        let dateOfCreation = DateFormatter.localizedString(from: food.dateOfCreation! as Date, dateStyle: .short, timeStyle: .short)
        let dateOfLastModification = DateFormatter.localizedString(from: food.dateOfLastModification! as Date, dateStyle: .short, timeStyle: .short)

        var rows = [InformationDataRecord]()
        rows.append( InformationDataRecord(information: "Name",     detail: food.name) )
        rows.append( InformationDataRecord(information: "Detail",   detail: food.detail?.name ?? nil) )
        rows.append( InformationDataRecord(information: "Gruppe",   detail: food.group?.name ?? nil) )
        rows.append( InformationDataRecord(information: "Untergr.", detail: food.subGroup?.name ?? nil)  )
        rows.append( InformationDataRecord(information: "Zuber..",  detail: food.preparation?.name ?? nil) )
        rows.append( InformationDataRecord(information: "Refer.",   detail: food.referenceWeight?.name ?? nil) )
        rows.append( InformationDataRecord(information: "Quelle",   detail: food.source?.name ?? nil) )
        rows.append( InformationDataRecord(information: "Datum",       detail: dateOfCreation) )
        rows.append( InformationDataRecord(information: "Letzte Änd.", detail: dateOfLastModification) )

        amountString = " je " + String(stringInterpolationSegment: food.amount) + " g"

        return rows
//        theSections.append(Section(title: "Allgemeine Informationen", footer: "", rows: rows))
        
        
    }
    func configureMetadataRowsForMeal(_ meal: Meal) -> [InformationDataRecord] {

        amountString = "je " + String(stringInterpolationSegment: meal.amount) + " g"

        
        let dateOfCreation = DateFormatter.localizedString(from: meal.dateOfCreation! as Date, dateStyle: .short, timeStyle: .short)
        let dateOfLastModification = DateFormatter.localizedString(from: meal.dateOfLastModification! as Date, dateStyle: .short, timeStyle: .short)

        var rows = [InformationDataRecord]()
        rows.append( InformationDataRecord(information: "Gesamtmenge", detail: amountString) )
        rows.append( InformationDataRecord(information: "Datum",       detail: dateOfCreation) )
        rows.append( InformationDataRecord(information: "Letzte Änd.", detail: dateOfLastModification) )
        return rows
        
    }
    
   
}
