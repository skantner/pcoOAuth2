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
import AeroGearHttp
import AeroGearOAuth2

class ViewController: UIViewController {
    
    var serviceTypeList : [String]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        serviceTypeList = [String]()
        super.init(coder: aDecoder)
    }
    
    
    @IBAction func goPressed() {
        
        let clientID = "3c4a2ee10fae6870972de58cfc661341348c0e5dc5b0727fa9fb669b388f565b"
        let clientSecret = "896b9f9605027405d465a9a9c82b9d6613ec5eeffbb8c77b7be96b73e597f873"
  
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
        let http = Http()
        http.authzModule = gdModule
        
        http.request(method: .get,
                     path: "https://api.planningcenteronline.com/services/v2/service_types",
                       completionHandler: {(response, error) in
                        if (error != nil) {
                            print("Error -> \(error!.localizedDescription)")
                        } else {
                            if let jsonResult = response! as? NSDictionary,
                                let meta = jsonResult["meta"] as? NSDictionary,
                                let total = meta["total_count"] {
                                        print("Total = \(total)")
                            }
                            if let jsonResult = response! as? NSDictionary,
                                let serviceTypes = jsonResult["data"] as? NSArray {
                                for serviceType in serviceTypes {
                                    if let stype = serviceType as? NSDictionary,
                                        let attributes = stype["attributes"] as? NSDictionary,
                                        let name = attributes["name"] as? String {
                                            print(" \(name)")
                                            self.serviceTypeList.append(name)
                                        }
                                    }
                                }
                            }
                        print ("stop")

                        }
        )
     print ("stop")
    }

    
    func performStoreRequest(with url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Download error: \(error.localizedDescription)")
            showNetworkError()
            return nil
            
        }
    }
    
    func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            return result.results
        } catch {
            print("JSON error: \(error)")
            return []
        }
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

