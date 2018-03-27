//
//  PlanItemsViewController.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/6/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

//TODO:
// 1. Rerrange/delete from new set table
// 2. Add/remove from NP song list by tapping on cells
// 3. Activity indicator during attachment downloads
// 4. Add/remove from new set by tapping on collectionView attachments

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
    var npSongList = [String]()
    var newSetList = [NewSetItem]()
    var dipView = UIView()
    var downloadTotal = 0
    var downloadCount = 0

    @IBOutlet weak var pcoTableView: UITableView!
    @IBOutlet weak var npSongTableView: UITableView!
    @IBOutlet weak var newSetTableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var leadSwitch: UISwitch!
    @IBOutlet weak var chordSwitch: UISwitch!
    @IBOutlet weak var createSetListButton: UIButton!
    @IBOutlet weak var rebuildButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        print ("PlanID:\(planID):ServiceTypeID:\(serviceTypeID):ServiceTypeName:\(serviceTypeName)")
        self.navigationItem.title = self.schedDate
        
        self.collectionView.allowsMultipleSelection = true
        
        npSongList.append("Fullness")
        npSongList.append("Here In The Presence-B (LEAD)")
        npSongList.append("Here In The Presence-B (CHORDS)")
        
        npSongTableView.estimatedRowHeight = 44.0
        npSongTableView.rowHeight = UITableViewAutomaticDimension
        
        self.leadSwitch.isOn = true
        self.chordSwitch.isOn = false
        self.createSetListButton.isEnabled = false
        
        dipView.backgroundColor = .darkGray
        self.view.addSubview(dipView)
        dipView.translatesAutoresizingMaskIntoConstraints = false
        dipView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        dipView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        dipView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        dipView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        dipView.layer.cornerRadius = 5.0
        
        let dipLabel = UILabel()
        dipLabel.text = "Downloading from PCO"
        dipLabel.textColor = .white
        dipView.addSubview(dipLabel)
        dipLabel.translatesAutoresizingMaskIntoConstraints = false
        dipLabel.centerXAnchor.constraint(equalTo: dipView.centerXAnchor).isActive = true
        dipLabel.topAnchor.constraint(equalTo: dipView.topAnchor, constant: 10).isActive = true

        let dipSpinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        dipSpinner.startAnimating()
        dipView.addSubview(dipSpinner)
        dipSpinner.translatesAutoresizingMaskIntoConstraints = false
        dipSpinner.centerXAnchor.constraint(equalTo: dipView.centerXAnchor).isActive = true
        dipSpinner.bottomAnchor.constraint(equalTo: dipView.bottomAnchor, constant: -10).isActive = true

        dipView.alpha = 0.0
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didGetSongs {
            getPlanSongs()
        }
    }

    @IBAction func chordsSwitchChanged(_ sender: Any) {
        let sw = sender as! UISwitch
        if sw.isOn {
            self.leadSwitch.setOn(false, animated: true)
        }
    }
    
    @IBAction func leadSwitchChanged(_ sender: Any) {
        let sw = sender as! UISwitch
        if sw.isOn {
            self.chordSwitch.setOn(false, animated: true)
        }
    }

    @IBAction func createPressed(_ sender: Any) {

        // Save .setlist file
        // download needed attachments
        
        var mustDownload = false
        
        self.downloadTotal = 0
        
        let setlist = NSMutableArray()
        for song in newSetList {
            setlist.add(song.title)
            if song.isPCODownload {
                mustDownload = true
                self.downloadTotal += 1
            }
        }
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let writePath = documents + "/testsetlist.plist"
        setlist.write(toFile: writePath, atomically: false)

        if mustDownload {
            DispatchQueue.main.async {
                self.dipView.alpha = 1.0
            }
            downloadCount = 0
            for song in newSetList {
                if song.isPCODownload {
                    getPCOAttachment(openUrl: song.attachment!.url, fileName: song.title)
                }
            }
        }
        
//        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        print("Documents dir:\(documentsURL)")
        

    }
    
    @IBAction func rebuildPressed(_ sender: Any) {
        
        buildNewSetList()
    }
    
    func getPCOAttachment(openUrl : String, fileName: String) {
        let http = Http()
        http.authzModule = self.authzModule
        http.request(method: .post,
                     path: openUrl,
                     completionHandler: {(response, error) in
                        if (error != nil) {
                            print("Error -> \(error!.localizedDescription)")
                        } else {
                            if let jsonResult = response as? Dictionary<String, Any>,
                                let attachmentData = jsonResult["data"] as? Dictionary<String, Any>,
                                let attributes = attachmentData["attributes"] as? Dictionary<String, Any>,
                                let attachmentUrl = attributes["attachment_url"] as? String {
                                let s3http = Http()
                                s3http.download(url: attachmentUrl,
                                                method: .get,
                                                progress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)  in
                                                    print("bytesWritten: \(bytesWritten), totalBytesWritten: \(totalBytesWritten), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
                                }, completionHandler: { (response, error) in
                                    //                            print("Download complete: \(response!)")
                                    print("Download of \(fileName) complete.")
                                    self.downloadCount += 1
                                    if self.downloadCount == self.downloadTotal {
                                        DispatchQueue.main.async {
                                            self.dipView.alpha = 0.0
                                        }
                                    }
                                })
                            }
                        }
        })
    }
    
    func buildNewSetList() {
        newSetList.removeAll()
        for song in self.songItems {
            song.isInNewSetList = false
        }
        var scoreType = ""
        if self.chordSwitch.isOn {
            scoreType = "(CHORDS)"
        } else if self.leadSwitch.isOn {
            scoreType = "(LEAD)"
        }
        
        for song in self.songItems {
            var testTitle = ""
            if scoreType != "" {
                testTitle = song.title + "-\(song.keyName) \(scoreType)"
            }
            for np in self.npSongList {  // look for matches in the NextPage Song List
                if np == song.title {
                    let newEntry = NewSetItem(title: song.title, indexPath: IndexPath(row:0, section:0), isPCODownload: false, attachment: nil)
                    self.newSetList.append(newEntry)
                    song.isInNewSetList = true
                } else if np == testTitle {
                    let newEntry = NewSetItem(title: testTitle, indexPath: IndexPath(row:0, section:0), isPCODownload: false, attachment: nil)
                    self.newSetList.append(newEntry)
                    song.isInNewSetList = true
                }
                if song.isInNewSetList { break }
            }
            if song.isInNewSetList {
                continue
            } else { // pick something from the attachments we have in PCO
                if scoreType != "" { // look for a match based on score type
                    for a in song.attachments {
                        if a.filename.range(of: scoreType) != nil {
                            let title = String(a.filename.dropLast(4))
                            let newEntry = NewSetItem(title: title, indexPath: IndexPath(row:0, section:0), isPCODownload: true, attachment: a)
                            self.newSetList.append(newEntry)
                            markAttachmentCell(for: a)
                            song.isInNewSetList = true
                            break
                        }
                    }
                } else { // otherwise, just pick the first available
                    if song.attachments.count > 0 {
                        let attachment = song.attachments.first
                        let name = attachment?.filename
                        // mark attachment in collection view
                        let title = String(name!.dropLast(4))
                        let newEntry = NewSetItem(title: title, indexPath: IndexPath(row:0, section:0), isPCODownload: true, attachment: attachment)
                        self.newSetList.append(newEntry)
                        markAttachmentCell(for: attachment!)
                        song.isInNewSetList = true
                    }
                }
            }
        }
        // Make selections based on setting of Leads or Chords switches
        // 1. Look for matches in NextPage Song List and add hits
        // 2. Look for attachments and add to new set highlighed in blue, and select in CollectionView
        // 3. refresh table
        
        self.newSetTableView.reloadData()
        
        var enable = true
        
        for song in self.songItems {
            if !song.isInNewSetList {
                enable = false
                break
            }
        }

        self.createSetListButton.isEnabled = enable
    }
    
    func markAttachmentCell(for attachment : Attachment) {
        
        self.collectionView.selectItem(at: attachment.indexPath, animated: false, scrollPosition: .centeredHorizontally)
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
                            self.pcoTableView.reloadData()
                            self.getSongAttachments()
                            self.didGetSongs = true
                        }
                    }
                }
        })
    }
    
    func indexAttachments() {
        
        for song in songItems {
            for attachment in song.attachments {
                let section = songItems.index(of: song)
                let row = song.attachments.index(of: attachment)
                attachment.indexPath = IndexPath(row: row!, section: section!)
            }
        }
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
                                        let indexPath = IndexPath(row: 0, section: 0)

//                                        print("Song:\(song.title):Attachment ID: \(attachmentID):filename \(filename):url \(aurl)")
                                        let a = Attachment(id : attachmentID, filename : filename, contentType : contentType, url : aurl, indexPath : indexPath)
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
                                        let indexPath = IndexPath(row: 0, section: 0)
                                        let a = Attachment(id : attachmentID, filename : filename, contentType : pcoType, url : aurl, indexPath : indexPath)
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
                            self.indexAttachments()
                            self.pcoTableView.reloadData()
                            self.collectionView.reloadData()

                            self.buildNewSetList()
                        }
                    }
            })
        }
    }
    
    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch tableView {
        case self.newSetTableView:
            return newSetTableViewCell(tableView, cellForRowAt: indexPath)
        case self.npSongTableView:
            return npSongTableViewCell(tableView, cellForRowAt: indexPath)
        default:
            return pcoTableViewCell(tableView, cellForRowAt: indexPath)
        }
    }
    
    func pcoTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
        detailLabel.text = "Key: " + song.keyName + ", Seq: " + String(song.sequence) + ", Attachments: " + attachments
        
        if cell.accessoryView == nil {
            let ai = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            ai.startAnimating()
            cell.accessoryView = ai
        }
        
        cell.accessoryView?.tag = 1000 + song.sequence
        
        return cell
    }

    func newSetTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewSetCell", for:indexPath)

        let label = cell.viewWithTag(1000) as! UILabel
        
        let setItem = self.newSetList[indexPath.row]
        
        label.text = setItem.title

        if setItem.isPCODownload {
            cell.backgroundColor = UIColor.blue
        }
        
        return cell
    }

    func npSongTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NPSongCell", for:indexPath)

        let label = cell.viewWithTag(1000) as! UILabel
        
        let npSong = self.npSongList[indexPath.row]
        
        label.text = npSong

        return cell
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch tableView {
        case self.pcoTableView:
            return self.songItems.count
        case self.newSetTableView:
            return self.newSetList.count
        case self.npSongTableView:
            return self.npSongList.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = ""

        if section == 0 {
            switch tableView {
            case self.pcoTableView:
                title = "PCO Set List"
            case self.newSetTableView:
                title = "New Set"
            case self.npSongTableView:
                title = "NextPage Song List"
                default:
                title = ""
            }
        }

        return title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.pcoTableView {
            self.pcoTableView.deselectRow(at: indexPath, animated: true)
            self.selectedSongIndex = indexPath.row
      //      performSegue(withIdentifier: "ShowAttachments", sender: nil)
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (tableView == self.newSetTableView) && (editingStyle == .delete)  {
            self.newSetList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    // MARK: - CollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.songItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.songItems[section].attachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
            case UICollectionElementKindSectionHeader:
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                                 withReuseIdentifier: "SongHeaderView",
                                                                                 for: indexPath) as! SongHeaderView
                headerView.titleLabel.text = songItems[(indexPath as NSIndexPath).section].title
                return headerView
            default:
                assert(false, "Unexpected element kind")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AttachmentCell",
                                                      for: indexPath)
        cell.backgroundColor = UIColor.lightGray
        let song = self.songItems[indexPath.section]
        let attachment = song.attachments[indexPath.row]
        let label = cell.viewWithTag(2000) as! UILabel
        let filename = attachment.filename
        label.text = filename
        let imgView = cell.viewWithTag(2001) as! UIImageView
        
        if filename.lowercased().range(of:"lead") != nil {
            imgView.image = UIImage(named:"pco_lead")
        } else if filename.lowercased().range(of:"chord") != nil {
            imgView.image = UIImage(named:"pco_chords")
        } else {
            imgView.image = UIImage(named:"pco_lyrics")
        }
        
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

