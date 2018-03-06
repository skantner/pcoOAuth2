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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var serviceTypeList : [String : String]
    let clientID = "3c4a2ee10fae6870972de58cfc661341348c0e5dc5b0727fa9fb669b388f565b"
    let clientSecret = "896b9f9605027405d465a9a9c82b9d6613ec5eeffbb8c77b7be96b73e597f873"
    let http = Http()
    var userID : String
    var userName : String
    var scheduledPlans : [ScheduledPlan]
    
    let PCOUserID = Notification.Name(rawValue: "PCOUserIDNotification")
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
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
        self.userName = ""
        self.scheduledPlans = [ScheduledPlan]()

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
                                let id = data["id"] as? String,
                                let attributes = data["attributes"] as? Dictionary<String, Any>,
                                let lastName = attributes["last_name"] as? String,
                                let firstName = attributes["first_name"] as? String {
                                self.userID = id
                                self.userName = firstName + " " + lastName;
                                print("PCO User Info: \(self.userName), ID = \(self.userID)")
                                DispatchQueue.main.async {
                                    self.spinner.stopAnimating()
                                    self.spinner.isHidden = true
                                    self.userIDLabel.text = self.userID
                                    self.nameLabel.text = self.userName
                                    self.getPCOSchedules(userID: self.userID)
                                }
                            }
                        }
        })
    }
    

    func getPCOSchedules(userID: String) {
        
        self.spinner.startAnimating()
        self.spinner.isHidden = false
        
        http.request(method: .get,
                     path: "https://api.planningcenteronline.com/services/v2/people/\(userID)/schedules",
                     completionHandler: {(response, error) in
                        if (error != nil) {
                            print("Error -> \(error!.localizedDescription)")
                        } else {
                            if let jsonResult = response as? Dictionary<String, Any>,
                                let scheduleData = jsonResult["data"] as? [Any] {
                                for schedule in scheduleData {
                                    if let sched = schedule as? Dictionary<String, Any>,
                                        let schedID = sched["id"] as? String,
                                        let attributes = sched["attributes"] as? Dictionary<String, Any>,
                                        let serviceTypeName = attributes["service_type_name"] as? String,
                                        let shortDates = attributes["short_dates"] as? String,
                                        let teamName = attributes["team_name"] as? String,
                                        let relationships = sched["relationships"] as? Dictionary<String, Any>,
                                        let plan = relationships["plan"] as? Dictionary<String, Any>,
                                        let planData = plan["data"] as? Dictionary<String, Any>,
                                        let planID = planData["id"] as? String {
                                            print("Schedule Data: \(schedID):\(serviceTypeName) : \(shortDates) : \(teamName) : Plan ID = \(planID)")
                                        let scheduledPlan = ScheduledPlan(planID: planID, schedDate: shortDates, serviceType: serviceTypeName)
                                        self.scheduledPlans.append(scheduledPlan)
                                        
                                        DispatchQueue.main.async {
                                            self.spinner.stopAnimating()
                                            self.spinner.isHidden = true
                                            self.tableView.reloadData()
                                        }

                                    }
                                }
                            }
                        }
        })
    }

    //MARK: - TableView methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.scheduledPlans.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for:indexPath)
        
        let label = cell.viewWithTag(1000) as! UILabel
        let detalLabel = cell.viewWithTag(1001) as! UILabel

        let sp = self.scheduledPlans[indexPath.row]
        
        label.text = sp.scheduledDate
        detalLabel.text = sp.planID
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowPlan", sender: nil)
    }
    
    // MARK: - Housekeeping
    
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

