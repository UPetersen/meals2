//
//  AppDelegate.swift
//  meals2
//
//  Created by Uwe Petersen on 01.10.17.
//  Copyright © 2017 Uwe Petersen. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Speed up all animations (view transitions) by this factor
        window?.layer.speed = 2.0
        
        // Set up and show view controller (i.e. MealsCDTVC)
        let navigationController = self.window!.rootViewController as! UINavigationController
        if let mealsCDTVC = navigationController.topViewController as? MealsCDTVC {
            //            mealsCDTVC.managedObjectContext = self.persistentContainer.viewContext
            mealsCDTVC.persistentContainer = persistentContainer
            
            // Check dictionary for 3D touch short cut items and perform corresponding actions
            if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
                handleShortcutItem(shortcutItem, forMealsCDTVC: mealsCDTVC)
                return false // prevents call of application:performActionFor... (see below)
            }
        }
        return true
    }
    
    // Uwe: This function is called, when user launches app (app not yet running) or relaunches
    // app (app being in the background and not terminated) from home screen using quick actions.
    // Normally this function is called each time user uses Quick actions. But when in
    // application:didFinishWithOptions returns false, this function is only called when
    // user uses quick actions in the case, the app is still running in the background.
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let navigationController = self.window!.rootViewController as! UINavigationController
        navigationController.popToRootViewController(animated: false)
        if let mealsCDTVC = navigationController.topViewController as? MealsCDTVC {
            //            mealsCDTVC.managedObjectContext = self.persistentContainer.viewContext
            mealsCDTVC.persistentContainer = persistentContainer
            handleShortcutItem(shortcutItem, forMealsCDTVC: mealsCDTVC)
        }
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    

    // MARK: - shortcutItems i.e. 3D touch quick actions
    
    // Handle quick action shortcutItems appropriately, i.e. create a new meal and in some cases push
    // a view controller by performing the corresponding segue
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem, forMealsCDTVC mealsCDTVC: MealsCDTVC) {
        // Check dictionary for 3D touch short cut items and perform corresponding actions
        switch shortcutItem.type {
        case "UPP.meals2.NewMeal": // create new meal
            let dummyBarButtonItem = UIBarButtonItem()
            mealsCDTVC.managedObjectContext = persistentContainer.viewContext
            mealsCDTVC.addButtonSelected(dummyBarButtonItem)
        case "UPP.meals2.NewMealAndShowFavoriteSearch": // create new meal an show favorites
            let dummyBarButtonItem = UIBarButtonItem()
            mealsCDTVC.managedObjectContext = persistentContainer.viewContext
            mealsCDTVC.addButtonSelected(dummyBarButtonItem)
            mealsCDTVC.performSegue(withIdentifier: MealsCDTVC.SegueIdentifier.ShowFavoriteSearchCDTVC.rawValue, sender: mealsCDTVC)
        case "UPP.meals2.NewMealAndShowGeneralSearch": // create new meal and show general search
            let dummyBarButtonItem = UIBarButtonItem()
            mealsCDTVC.managedObjectContext = persistentContainer.viewContext
            mealsCDTVC.addButtonSelected(dummyBarButtonItem)
            mealsCDTVC.performSegue(withIdentifier: MealsCDTVC.SegueIdentifier.ShowGeneralSearchCDTVC.rawValue, sender: mealsCDTVC)
        default:
            break
        }
    }
    

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "meals")
        
        // Use old store from original meals app
        let storeURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("meals.sqlite")
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]

        // Continue with boiler plate code from apple
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

