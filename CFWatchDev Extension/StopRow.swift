//
//  StopRow.swift
//  CF
//
//  Created by Radu Dutzan on 8/25/15.
//  Copyright © 2015 Onda. All rights reserved.
//

import WatchKit

class StopRow: NSObject {
    @IBOutlet weak var stopNameLabel: WKInterfaceLabel!
    @IBOutlet weak var estimationGroup: WKInterfaceGroup!
    @IBOutlet weak var distanceLabel: WKInterfaceLabel!
    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var noEstimationLabel: WKInterfaceLabel!
}
