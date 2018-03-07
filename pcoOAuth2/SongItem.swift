//
//  PlanItem.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/6/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import Foundation

class SongItem: NSObject {
    var itemID = ""
    var title = ""
    var keyName = ""
    var sequence = 0
    var attachments = 0

    init(itemID : String, title : String, keyName : String, sequence : Int) {
        self.itemID = itemID
        self.title = title
        self.keyName = keyName
        self.sequence = sequence
        
        super.init()
    }
}
