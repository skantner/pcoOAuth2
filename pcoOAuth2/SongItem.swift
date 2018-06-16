//
//  PlanItem.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/6/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import Foundation

class SongItem: NSObject {
    
    var itemID = ""  // PCO item id
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
    var collectionIndexPath : IndexPath
    
    init(id : String, filename : String, contentType : String, url : String, indexPath: IndexPath) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.url = url
        self.collectionIndexPath = indexPath
        
        super.init()
    }
}

class NewSetItem: NSObject {
    
    var itemID : String
    var title : String
    var collectionIndexPath : IndexPath
    var isPCODownload = false
    var isNPLocalSong = false
    var attachment : Attachment?

    
    init(title: String, id: String, indexPath: IndexPath, isPCODownload : Bool, isNPLocalSong : Bool, attachment : Attachment?) {
        self.title = title
        self.itemID = id
        self.collectionIndexPath = indexPath
        self.isPCODownload = isPCODownload
        self.isNPLocalSong = isNPLocalSong
        self.attachment = attachment

        super.init()
    }
}

class NPSongItem: NSObject {
    
    var title : String
    var isInNewSetList : Bool
    
    init(title: String, isInNewSetList : Bool) {
        self.title = title
        self.isInNewSetList = isInNewSetList
        super.init()
    }
}

