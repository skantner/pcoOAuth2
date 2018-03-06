//
//  PlanItemsViewController.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/6/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import UIKit
import AeroGearHttp
import AeroGearOAuth2

class PlanItemsViewController: UITableViewController {

    var planID = ""
    var serviceTypeID = ""
    var serviceTypeName = ""
    var schedDate = ""
    var http = Http()
    var planItems = [PlanItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        print ("PlanID:\(planID):ServiceTypeID:\(serviceTypeID):ServiceTypeName:\(serviceTypeName)")
        self.navigationItem.title = self.schedDate
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getPlanSongs()
    }
    
    func getPlanSongs() {
        
        http.request(method: .get,
                     path: "https://api.planningcenteronline.com/services/v2/service_types/\(self.serviceTypeID)/plans/\(self.planID)/items",
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
                                let planID = planData["id"] as? String,
                                let service = relationships["service_type"] as? Dictionary<String, Any>,
                                let serviceData = service["data"] as? Dictionary<String, Any>,
                                let serviceTypeID = serviceData["id"] as? String {
                                print("Schedule Data: \(schedID):SType=\(serviceTypeID):\(serviceTypeName) : \(shortDates) : \(teamName) : Plan ID = \(planID)")
                                let scheduledPlan = ScheduledPlan(planID: planID, schedDate: shortDates, serviceTypeID: serviceTypeID, serviceTypeName: serviceTypeName)
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
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - Housekeeping
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
