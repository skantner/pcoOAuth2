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
    var serviceTypeID = ""
    var serviceTypeName = ""
    
    init(planID : String, schedDate : String, serviceTypeID : String, serviceTypeName : String) {
        self.planID = planID
        self.scheduledDate = schedDate
        self.serviceTypeID = serviceTypeID
        self.serviceTypeName = serviceTypeName
        
        super.init()
    }
}
