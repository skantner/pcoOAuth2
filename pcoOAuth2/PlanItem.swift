//
//  PlanItem.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/6/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import Foundation

class PlanItem: NSObject {
    var itemID = ""
    var title = ""
    var sequence = 0
    
    init(itemID : String, title : String, sequence : Int) {
        self.itemID = itemID
        self.title = title
        self.sequence = sequence
        
        super.init()
    }
}
