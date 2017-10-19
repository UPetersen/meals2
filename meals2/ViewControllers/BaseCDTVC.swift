//
//  BaseCDTVC.swift
//  bLS
//
//  Created by Uwe Petersen on 29.10.14.
//  Copyright (c) 2014 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc class BaseCDTVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
//    let TableViewCellStyle = UITableViewCellStyle.subtitle // Needed, if a new cell has to be created

    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.fetchedResultsController.sections?[section].name 
    }
    
    
    // MARK: - Fetched results controller
    
    var _fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> {
        set {
            
            // Set new value for var _fetchedResultsController if not yet set or if new value differs from old value
            if  _fetchedResultsController == nil || _fetchedResultsController! != newValue {
                
                _fetchedResultsController = newValue;
                _fetchedResultsController!.delegate = self

                do {
                    try _fetchedResultsController!.performFetch()
                    print("\(#file), \(#function):")
                    print("   Successfully fetched \(String(describing: _fetchedResultsController?.fetchedObjects?.count)) objects for entity name \(String(describing: _fetchedResultsController?.fetchRequest.entityName)) and predicate \(String(describing: _fetchedResultsController?.fetchRequest.predicate)).")
                } catch let error as NSError {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    print("Unresolved error \(error), \(error.userInfo)")
                    print("Perform fetch failed. ")
                    print("FetchedResultsController is: \(String(describing: _fetchedResultsController?.description))")
                    abort()
                }
            }
            self.tableView.reloadData()
        }
        get {
            if _fetchedResultsController == nil {
                print("This should not have happened: getter of fetchedResultsController called before initalized via its setter. ")
                fatalError()
            }
            return _fetchedResultsController!
        }
    }


/*
// Uwi, 2014-12-20: commented this out, since animations were not as desired
    
    // Wird aufgerufen bevor der fetched results controller Änderungen verarbeitet (aufgrund von add, remove, move oder update von Elementen)
    // Notifies the receiver that the fetched results controller is about to start processing of one or more changes due to an add, remove, move, or update.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
        self.tableView.reloadData() // added this line on 20. December 2014, when adding the feature of moving cells in MealsCDTVC
    }
*/

    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    // In the simplest, most efficient, case, reload the table view.
    self.tableView.reloadData() // Uwi, 20.12.2014: works better than using the above methods: Now the animations are right, sections are updated instantaneously
    }

}

