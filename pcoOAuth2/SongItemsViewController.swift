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

class SongItemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {

    var planID = ""
    var serviceTypeID = ""
    var serviceTypeName = ""
    var schedDate = ""
    var songItems = [SongItem]()
    var observer: Any!
    var authzModule: AuthzModule!
    var selectedSongIndex = NSNotFound
    var didGetSongs = false
    let itemsPerRow: CGFloat = 5
    let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var leadSwitch: UISwitch!
    @IBOutlet weak var chordSwitch: UISwitch!

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
        
        if !didGetSongs {
            getPlanSongs()
        }
    }

    @IBAction func chordsSwitchChanged(_ sender: Any) {
    }
    @IBAction func leadSwitchChanged(_ sender: Any) {
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
                            self.didGetSongs = true
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
//                                        print("Song:\(song.title):Attachment ID: \(attachmentID):filename \(filename):url \(aurl)")
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
            let url = "https://api.planningcenteronline.com/services/v2/service_types/\(self.serviceTypeID)/plans/\(self.planID)/items/\(song.itemID)/arrangement/attachments"
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
                                    let pcoType = attributes["pco_type"] as? String,
                                    let filename = attributes["filename"] as? String {
                                    if pcoType == "AttachmentChart::Lyric" {
                                        let aurl = url + "/\(attachmentID)/open"
                                        let a = Attachment(id : attachmentID, filename : filename, contentType : pcoType, url : aurl)
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
                            self.collectionView.reloadData()
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
  //      performSegue(withIdentifier: "ShowAttachments", sender: nil)
    }

    // MARK: - CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.songItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.songItems[section].attachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AttachmentCell",
                                                      for: indexPath)
        cell.backgroundColor = UIColor.lightGray
        let song = self.songItems[indexPath.section]
        let attachment = song.attachments[indexPath.row]
        let label = cell.viewWithTag(2000) as! UILabel
        label.text = attachment.filename
        
        return cell
    }
    

    func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        print ("Hi from \(indexPath.section):\(indexPath.row)")
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
    }
}

extension SongItemsViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = collectionView.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

