//
//  InterfaceController.swift
//  CFWatchDev Extension
//
//  Created by Radu Dutzan on 7/22/15.
//  Copyright © 2015 Onda. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    @IBOutlet weak var tableView: WKInterfaceTable?
    @IBOutlet weak var noFavoritesView: WKInterfaceGroup?
    private var favorites: NSArray? {
        get {
            let defaults = NSUserDefaults(suiteName: "group.ondalabs.cfbetagroup")
            let favoritesArray = defaults?.objectForKey("favorites") as? NSArray
            return favoritesArray
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        tableView?.setNumberOfRows(3, withRowType: "Hello")
        if favorites?.count == 0 {
            noFavoritesView?.setHidden(true)
            tableView?.setHidden(false)
        } else {
            noFavoritesView?.setHidden(false)
            tableView?.setHidden(true)
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
