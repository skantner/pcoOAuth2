//
//  ScheduledPlan.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/5/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import Foundation

class ScheduledPlan: NSObject {
    var planID = ""
    var scheduledDate = ""
    var serviceTypeName = ""
    
    init(planID : String, schedDate : String, serviceType : String) {
        self.planID = planID
        self.scheduledDate = schedDate
        self.serviceTypeName = serviceType
        
        super.init()
    }
}
