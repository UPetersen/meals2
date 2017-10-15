//
//  BaseCDTVCWithTableIndex.swift
//  bLS
//
//  Created by Uwe Petersen on 02.11.14.
//  Copyright (c) 2014 Uwe Petersen. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc (BaseCDTVCWithTableIndex) class BaseCDTVCWithTableIndex: BaseCDTVC {
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.fetchedResultsController.section(forSectionIndexTitle: title, at: index)
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.fetchedResultsController.sectionIndexTitles
    }
}
