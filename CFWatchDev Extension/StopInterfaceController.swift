//
//  StopInterfaceController.swift
//  CF
//
//  Created by Radu Dutzan on 8/25/15.
//  Copyright © 2015 Onda. All rights reserved.
//

import WatchKit

class StopInterfaceController: WKInterfaceController {
    @IBOutlet weak var activityIndicator: WKInterfaceImage!
    @IBOutlet weak var stopTableView: WKInterfaceTable!
    
    private var stopDictionary: [String: AnyObject] = ["codigo": "PA0"]
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        stopDictionary = context as! [String: AnyObject]
    }
    
    override func willActivate() {
        super.willActivate()
        setTitle(stopDictionary["favoriteName"] as? String)
        
        activityIndicator.setImage(UIImage.animatedImageNamed("Activity", duration: 1))
        activityIndicator.startAnimating()
        activityIndicator.setImageNamed("Activity")
        activityIndicator.startAnimatingWithImagesInRange(NSMakeRange(0, 30), duration: 1, repeatCount: -1)
        // get!
    }
}
