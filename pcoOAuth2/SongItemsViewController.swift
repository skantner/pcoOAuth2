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
    var songItems = [SongItem]()
    var observer: Any!
    var authzModule: AuthzModule!
    var selectedSongIndex = NSNotFound
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var debugButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        print ("PlanID:\(planID):ServiceTypeID:\(serviceTypeID):ServiceTypeName:\(serviceTypeName)")
        self.navigationItem.title = self.schedDate

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getPlanSongs()
    }
    
    @IBAction func debugPressed() {
        self.tableView.reloadData()
        print("Hi")
    }

    func getPlanSongs() {
        
        let http = Http()
        http.authzModule = self.authzModule
        
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
                            self.tableView.reloadData()
                            self.getSongAttachments()
                        }
                    }
                }
        })
    }
    
    func getSongAttachments() {

        let totalSongs = songItems.count
        var count = 0
        
        for song in songItems {
            let url = "https://api.planningcenteronline.com/services/v2/service_types/\(self.serviceTypeID)/plans/\(self.planID)/items/\(song.itemID)/attachments"
            print("\(url)")
            
            let http = Http()
            http.authzModule = self.authzModule
            http.request(method: .get,
                         path: url,
                completionHandler: {(response, error) in
                    if (error != nil) {
                        print("Error -> \(error!.localizedDescription)")
                    } else {
                        if let jsonResult = response as? Dictionary<String, Any>,
                            let attachmentData = jsonResult["data"] as? [Any] {
                            for attachment in attachmentData {
                                if let attachment = attachment as? Dictionary<String, Any>,
                                    let attachmentID = attachment["id"] as? String,
                                    let attributes = attachment["attributes"] as? Dictionary<String, Any>,
                                    let contentType = attributes["content_type"] as? String,
                                    let filename = attributes["filename"] as? String {
                                    if contentType == "application/pdf" {
                                        let aurl = url + "/\(attachmentID)/open"
                                        print("Song:\(song.title):Attachment ID: \(attachmentID):filename \(filename):url \(aurl)")
                                        let a = Attachment(id : attachmentID, filename : filename, contentType : contentType, url : aurl)
                                        song.attachments.append(a)
                                    }
                                }
                            }
                        }
                    }
                    count += 1
                    if count == totalSongs {
                        DispatchQueue.main.async {
                            self.getArrangementAttachments()
                        }
                    }
            })
        }
    }
    
    func getArrangementAttachments() {

        let totalSongs = songItems.count
        var count = 0
        
        for song in songItems {
            let http = Http()
            http.authzModule = self.authzModule
            http.request(method: .get,
                         path: "https://api.planningcenteronline.com/services/v2/service_types/\(self.serviceTypeID)/plans/\(self.planID)/items/\(song.itemID)/arrangement/attachments",
                completionHandler: {(response, error) in
                    if (error != nil) {
                        print("Error -> \(error!.localizedDescription)")
                    } else {
                        if let jsonResult = response as? Dictionary<String, Any>,
                            let attachmentData = jsonResult["data"] as? [Any] {
                            for attachment in attachmentData {
                                if let attachment = attachment as? Dictionary<String, Any>,
                                    let attachmentID = attachment["id"] as? String,
                                    let attributes = attachment["attributes"] as? Dictionary<String, Any>,
                                    let pcoType = attributes["pco_type"] as? String,
                                    let filename = attributes["filename"] as? String,
                                    let url = attributes["url"] as? String {
                                    if pcoType == "AttachmentChart::Lyric" {
                                        print("Song:\(song.title):Attachment ID: \(attachmentID):filename \(filename):url \(url)")
                                        let a = Attachment(id : attachmentID, filename : filename, contentType : pcoType, url : url)
                                        song.attachments.append(a)
                                    }
                                }
                            }
                        }
                    }
                    count += 1
                    if count == totalSongs {
                        DispatchQueue.main.async {
                            let v = self.view.viewWithTag(1000 + song.sequence) as? UIActivityIndicatorView
                            v?.stopAnimating()
                            self.tableView.reloadData()
                        }
                    }
            })
        }
    }
    
    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for:indexPath)

        let label = cell.viewWithTag(1000) as! UILabel
        let detailLabel = cell.viewWithTag(1001) as! UILabel
        
        let song = self.songItems[indexPath.row]
        
        var attachments = ""
        
        label.text = song.title
        if song.attachments.count > 0 {
            attachments = String(song.attachments.count)
        } else {
            attachments = "-"
        }
        detailLabel.text = "Item ID: " + song.itemID + ", Key: " + song.keyName + ", Seq: " + String(song.sequence) + ", Attachments: " + attachments
        
        if cell.accessoryView == nil {
            let ai = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            ai.startAnimating()
            cell.accessoryView = ai
        }
        
        cell.accessoryView?.tag = 1000 + song.sequence
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songItems.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.selectedSongIndex = indexPath.row
        performSegue(withIdentifier: "ShowAttachments", sender: nil)
    }

    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        if segue.identifier == "ShowAttachments" {
            let avc = segue.destination as! AttachmentsViewController
            let song = self.songItems[self.selectedSongIndex]
            avc.songTitle = song.title
            avc.attachmentList = song.attachments
            avc.authzModule = self.authzModule
        }
    }

    // MARK: - Housekeeping
    
    deinit {
        print("*** deinit \(self)")
//        NotificationCenter.default.removeObserver(observer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
