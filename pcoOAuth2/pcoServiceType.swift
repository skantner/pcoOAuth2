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

//struct PagedBreweries : Codable {
//    struct Meta : Codable {
//        let page: Int
//        let totalPages: Int
//        let perPage: Int
//        let totalRecords: Int
//        enum CodingKeys : String, CodingKey {
//            case page
//            case totalPages = "total_pages"
//            case perPage = "per_page"
//            case totalRecords = "total_records"
//        }
//    }
//    
//    struct Brewery : Codable {
//        let id: Int
//        let name: String
//    }
//    
//    let meta: Meta
//    let breweries: [Brewery]
//}
//
//struct Parent : Codable {
//    let data : String
//}

//struct ServiceTypeList : Codable {
//    struct ServiceType : Codable {
//        struct Attributes : Codable {
//                let attachmentTypesEnabled : Int
//                let backgroundCheckPermissions : String
//                let commentPermissions : String
//                let createdAt : String
//                let frequency : String
//                let lastPlanFrom : String
//                let name : String
//                let permissions : String
//                let sequence : Int
//                let updatedAt : String
//                enum CodingKeys : String, CodingKey {
//                    case attachmentTypesEnabled = "attachment_types_enabled"
//                    case backgroundCheckPermissions = "background_check_permissions"
//                    case commentPermissions = "comment_permissions"
//                    case createdAt = "created_at"
//                    case frequency
//                    case lastPlanFrom = "last_plan_from"
//                    case name
//                    case permissions
//                    case sequence
//                    case updatedAt = "updated_at"
//                }
//        }
//        let type : String
//        let id : Int
//        let attributes : Attributes
//        let links : [String : String]
//        let relationships : [Parent]
//    }
//    struct Meta : Codable {
//        let totalCount : Int
//        let count: Int
//        let canInclude: [String]
//        let parent : [Parent]
//        enum CodingKeys : String, CodingKey {
//            case totalCount = "total_count"
//            case count
//            case canInclude = "can_include"
//            case parent
//        }
//    }
//
//    let links : [String: String]
//    let data : [ServiceType]
//    let included : [String: String]
//    let meta : Meta
//}

//class ServiceTypeList : Codable {
//    struct ServiceType : Codable {
//        struct Attributes : Codable {
//            let attachmentTypesEnabled : Int
//            let backgroundCheckPermissions : String
//            let commentPermissions : String
//            let createdAt : String
//            let frequency : String
//            let lastPlanFrom : String
//            let name : String
//            let permissions : String
//            let sequence : Int
//            let updatedAt : String
//            enum CodingKeys : String, CodingKey {
//                case attachmentTypesEnabled = "attachment_types_enabled"
//                case backgroundCheckPermissions = "background_check_permissions"
//                case commentPermissions = "comment_permissions"
//                case createdAt = "created_at"
//                case frequency
//                case lastPlanFrom = "last_plan_from"
//                case name
//                case permissions
//                case sequence
//                case updatedAt = "updated_at"
//            }
//        }
//        let type : String
//        let id : Int
//        let attributes : Attributes
//        let links : [String : String]
//        let relationships : [Parent]
//    }
//    struct Meta : Codable {
//        let totalCount : Int
//        let count: Int
//        let canInclude: [String]
//        let parent : [Parent]
//        enum CodingKeys : String, CodingKey {
//            case totalCount = "total_count"
//            case count
//            case canInclude = "can_include"
//            case parent
//        }
//    }
//    
//    let links : [String: String]
//    let data : [ServiceType]
//    let included : [String: String]
//    let meta : Meta
//}



