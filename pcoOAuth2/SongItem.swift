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
    var attachments = [Attachment]()
    var isInNewSetList = false

    init(itemID : String, title : String, keyName : String, sequence : Int) {
        self.itemID = itemID
        self.title = title
        self.keyName = keyName
        self.sequence = sequence
        
        super.init()
    }
}

class Attachment: NSObject {
    
    var id = ""
    var filename = ""
    var contentType = ""
    var url = ""
    
    init(id : String, filename : String, contentType : String, url : String) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.url = url
        
        super.init()
    }
}
