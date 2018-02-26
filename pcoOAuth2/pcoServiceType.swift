//
//  pcoServiceType.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 2/24/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

// attributes
// links: dict
// relationships: dict of dict
// Plan - major type

class ServiceType {
    let type = "ServiceType"
    var id = ""
    var attributes = [
        "attachment_types_enabled" : false,
        "background_check_permissions" : "default",
        "comment_permissions" : "Scheduled Viewer",
        "created_at" : "",
        "frequency" : "",
        "last_plan_from" : "organization",
        "name" : "",
        "permissions" : "Administrator",
        "sequence" : 0,
        "updated_at" : ""
        ] as [String : Any]
    var links = [String: String]()
    var relationships = [String: [String: String]]()
}

class ServiceTypeResults {
    var links = [String: String]()
    var data = [ServiceType]()
    var included = [String]()
    var meta = [String: String]()
}
