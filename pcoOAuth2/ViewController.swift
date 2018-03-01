//
//  ViewController.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 2/19/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import UIKit

// scope = services
// 1

//CoreDataSaveFailedNotification = Notification.Name(rawValue: "CoreDataSaveFailedNotification")

import AeroGearHttp
import AeroGearOAuth2

class ViewController: UIViewController {
    
    var serviceTypeList : [String : String]
    let clientID = "3c4a2ee10fae6870972de58cfc661341348c0e5dc5b0727fa9fb669b388f565b"
    let clientSecret = "896b9f9605027405d465a9a9c82b9d6613ec5eeffbb8c77b7be96b73e597f873"
    let http = Http()
    var userID : String
    let PCOUserID = Notification.Name(rawValue: "PCOUserIDNotification")
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let pcoConfig =    Config(base: "https://api.planningcenteronline.com/",
                                  authzEndpoint: "oauth/authorize",
                                  redirectURL: "com.krtapps.pcooauth2://pcooauth2/",
                                  accessTokenEndpoint: "oauth/token", // no space on the end of this!
            clientId: clientID,
            refreshTokenEndpoint: "oauth/token",
            scopes: ["services"],
            clientSecret: clientSecret)
        
        let gdModule = AccountManager.addAccountWith(config: pcoConfig, moduleClass: OAuth2Module.self)
        //3
        http.authzModule = gdModule
        
        self.spinner.isHidden = true


    }
    
    required init?(coder aDecoder: NSCoder) {
        self.serviceTypeList = [String : String]()
        self.userID = "NotFound"
        
        super.init(coder: aDecoder)
    }
    
    
    @IBAction func goPressed() {
        
        getPCOuserId()
        
//        DispatchQueue.main.async(execute: {
//            self.updateUISuccess(resp)
//        })

/*
        http.request(method: .get,
                     path: "https://api.planningcenteronline.com/services/v2/service_types",
                       completionHandler: {(response, error) in
                        if (error != nil) {
                            print("Error -> \(error!.localizedDescription)")
                        } else {
//                            if let jsonResult = response as? Dictionary<String, Any>,
//                                let meta = jsonResult["meta"] as? Dictionary<String, Any>,
//                                let total = meta["total_count"] {
//                            }
                            if let jsonResult = response as? Dictionary<String, Any>,
                                let serviceTypes = jsonResult["data"] as? [Any] {
                                for serviceType in serviceTypes {
                                    if let stype = serviceType as? Dictionary<String, Any>,
                                        let id = stype["id"] as? String,
                                        let attributes = stype["attributes"] as? Dictionary<String, Any>,
                                        let name = attributes["name"] as? String {
                                            self.serviceTypeList[name] = id
                                        }
                                    }
                                }
                            }
                        })
 */
    }

    func getPCOuserId() {
        
        self.spinner.startAnimating()
        self.spinner.isHidden = false
        
        http.request(method: .get,
                     path: "https://api.planningcenteronline.com/services/v2/me",
                     completionHandler: {(response, error) in
                        if (error != nil) {
                            print("Error -> \(error!.localizedDescription)")
                        } else {
                            if let jsonResult = response as? Dictionary<String, Any>,
                                let data = jsonResult["data"] as? Dictionary<String, Any>,
                                let id = data["id"] as? String {
                                self.userID = id
                                print("PCO User ID:\(self.userID)")
                                DispatchQueue.main.async {
                                    self.spinner.stopAnimating()
                                    self.spinner.isHidden = true
                                }
                            }
                        }
        })
    }

    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...",
                                      message: "There was an error accessing the iTunes Store. Please try again.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        present(alert, animated: true, completion: nil)
        alert.addAction(action)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

