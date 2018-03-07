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

class SongItemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    var planID = ""
    var serviceTypeID = ""
    var serviceTypeName = ""
    var schedDate = ""
    var http = Http()
    var songItems = [SongItem]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
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
                        let itemData = jsonResult["data"] as? [Any] {
                        for item in itemData {
                            if let item = item as? Dictionary<String, Any>,
                                let itemID = item["id"] as? String,
                                let attributes = item["attributes"] as? Dictionary<String, Any>,
                                let itemType = attributes["item_type"] as? String,
                                let title = attributes["title"] as? String,
                                let keyName = attributes["key_name"] as? String,
                                let sequence = attributes["sequence"] as? Int {
                                if itemType == "song" {
                                    print("Item ID: \(itemID):Seq \(sequence):Title \(title)")
                                    let songItem = SongItem(itemID : itemID, title : title, keyName : keyName, sequence : sequence)
                                    self.songItems.append(songItem)

                                }
                                
                            }
                        }
                        DispatchQueue.main.async {
                            self.spinner.stopAnimating()
                            self.spinner.isHidden = true
                            self.tableView.reloadData()
                        }
                    }
                }
        })
    }
    
    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for:indexPath)

        let label = cell.viewWithTag(1000) as! UILabel
        let detailLabel = cell.viewWithTag(1001) as! UILabel
        
        let song = self.songItems[indexPath.row]
        
        label.text = song.title
        detailLabel.text = "Item ID: " + song.itemID + ", Key: " + song.keyName + ", Seq: " + String(song.sequence)
        
        return cell

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songItems.count
    }


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
