//
//  InterfaceController.swift
//  CFWatchDev Extension
//
//  Created by Radu Dutzan on 7/22/15.
//  Copyright © 2015 Onda. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController, FavoriteClientDelegate {
    @IBOutlet weak var tableView: WKInterfaceTable!
    @IBOutlet weak var noFavoritesView: WKInterfaceGroup!
    
    private var defaults = NSUserDefaults(suiteName: "group.ondalabs.cfbetagroup")
    private var favorites: [[String: AnyObject]] = []
    private var favoriteClient = FavoriteClient.sharedClient

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        favoriteClient.delegate = self
    }

    override func willActivate() {
        super.willActivate()
        
        favorites = favoriteClient.favoritesArray()
        reloadData()
    }
    
    func reloadData() {
        if favorites.count == 0 {
            noFavoritesView.setHidden(false)
            tableView.setHidden(true)
            print("no favs")
        } else {
            noFavoritesView.setHidden(true)
            tableView.setHidden(false)
            
            tableView.setNumberOfRows(favorites.count, withRowType: "FavoriteRow")
            
            var index = 0
            for favorite in favorites {
                if let row = tableView.rowControllerAtIndex(index) as? FavoriteRow {
                    row.titleLabel.setText(favorite["favoriteName"] as? String)
                    row.detailLabel.setText(favorite["nombre"] as? String)
                }
                index++
            }
        }
    }
    
    func clientDidUpdateFavorites(updatedFavorites: [[String : AnyObject]]) {
        favorites = updatedFavorites
        reloadData()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
