//
//  FavoriteClient.swift
//  CF
//
//  Created by Radu Dutzan on 8/23/15.
//  Copyright © 2015 Onda. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

protocol FavoriteClientDelegate {
    func clientDidUpdateFavorites(updatedFavorites: [[String: AnyObject]])
}

class FavoriteClient: NSObject, WCSessionDelegate {
    
    static let sharedClient = FavoriteClient()
    private var cachedFavorites: [[String: AnyObject]]?
    private let session: WCSession
    var delegate: FavoriteClientDelegate?
    
    override init() {
        session = WCSession.defaultSession()
        
        super.init()
        
        session.delegate = self
        session.activateSession()
    }
    
    func favoritesArray() -> [[String: AnyObject]] {
        if let cache = cachedFavorites {
            return cache
        } else {
            return loadLatestData()
        }
    }
    
    var requestingData = false
    
    func loadLatestData() -> [[String: AnyObject]] {
        // check app context for fav data
        // - and if absent -
        // ask WC to ping parent app and get 'em
        if let receivedFavorites = session.receivedApplicationContext["favorites"] as? [[String: AnyObject]] {
            cachedFavorites = receivedFavorites
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.session.sendMessage(["request": "appContext"], replyHandler: {
                    (response: [String : AnyObject]) -> Void in
                    print("got response")
                    if let responseFavorites = response["favorites"] as? [[String: AnyObject]] {
                        self.cachedFavorites = responseFavorites
                        self.delegate?.clientDidUpdateFavorites(responseFavorites)
                        print("response is good")
                    }
                }, errorHandler: {(error ) -> Void in
                    print(error)
                })
            }
        }
        
        if let favorites = cachedFavorites {
            return favorites
        } else {
            return []
        }
    }
    
    func processResponse(favorites: [AnyObject]) -> [[String: AnyObject]] {
        return []
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String: AnyObject]) {
        print("got update")
        if let favorites = applicationContext["favorites"] as? [[String: AnyObject]] {
            cachedFavorites = favorites
            delegate?.clientDidUpdateFavorites(favorites)
        }
    }

}
