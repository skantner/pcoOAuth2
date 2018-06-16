//
//  PlanItemsViewController.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/6/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

//TODO:
// 1. Add/remove from NP song list by tapping on cells
// 2. Activity indicator during attachment downloads
// 3. Add/remove from new set by tapping on collectionView attachments
// 4. Cloud download symbol indicating attachemnt will be downloaded instead of using blue background color

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
    var npSongList = [NPSongItem]()
    var newSetList = [NewSetItem]()
    var dipView = UIView()
    var downloadTotal = 0
    var downloadCount = 0
    var disconnected = false


    @IBOutlet weak var pcoTableView: UITableView!
    @IBOutlet weak var npSongTableView: UITableView!
    @IBOutlet weak var newSetTableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var leadSwitch: UISwitch!
    @IBOutlet weak var chordSwitch: UISwitch!
    @IBOutlet weak var createSetListButton: UIButton!
    @IBOutlet weak var rebuildButton: UIButton!
    @IBOutlet weak var newSetNavBar: UINavigationBar!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        print ("PlanID:\(planID):ServiceTypeID:\(serviceTypeID):ServiceTypeName:\(serviceTypeName)")
        self.navigationItem.title = self.schedDate
        
        self.collectionView.allowsMultipleSelection = true
        
        buildFakeNPSongList()
        
        npSongTableView.estimatedRowHeight = 44.0
        npSongTableView.rowHeight = UITableViewAutomaticDimension
        
        self.leadSwitch.isOn = true
        self.chordSwitch.isOn = false
//        self.createSetListButton.isEnabled = false
        
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
        
        newSetTableView.isEditing = true
        
     //   self.newSetNav.navigationItem.rightBarButtonItem = self.editButtonItem

    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didGetSongs {
            if !disconnected {
                getPlanSongs()
            } else {
                buildFakePCOSetList()
            }
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
        
        if !setlistComplete() {
            let alert = UIAlertController(title: "Set List Not Complete",
                                                     message: "The new set list does not include all of the songs in the PCO set list. Do you still want to create it?",
                                                     preferredStyle: .alert)
            let yes = UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                self.createSetList()
            })
            let no = UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                return
            })
            
            alert.addAction(yes)
            alert.addAction(no)

            self.present(alert, animated: true, completion: nil)
        } else {
            createSetList()
        }
    }
    
    func createSetList() {
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
        print("\(writePath)")
        
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
            for np in self.npSongList {  // look for matches in the NextPage Song List first...
                if np.title == song.title {
                    let newEntry = NewSetItem(title: song.title, id:"", indexPath: IndexPath(row:0, section:0), isPCODownload: false, isNPLocalSong: true, attachment: nil)
                    self.newSetList.append(newEntry)
                    song.isInNewSetList = true
                    np.isInNewSetList = true
                } else if np.title == testTitle {
                    let newEntry = NewSetItem(title: testTitle, id:"", indexPath: IndexPath(row:0, section:0), isPCODownload: false, isNPLocalSong: true, attachment: nil)
                    self.newSetList.append(newEntry)
                    song.isInNewSetList = true
                    np.isInNewSetList = true
                }
                if song.isInNewSetList { break }
            }
            if song.isInNewSetList {
                continue
            } else { // if not in NP, try to pick something from the attachments we have in PCO
                if scoreType != "" { // First look for a match based on score type...
                    for a in song.attachments {
                        if a.filename.range(of: scoreType) != nil {
                            let title = String(a.filename.dropLast(4))
                            let id = song.itemID
                            let newEntry = NewSetItem(title: title, id: id, indexPath: a.collectionIndexPath, isPCODownload: true, isNPLocalSong: false, attachment: a)
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
                        let id = song.itemID
                        let newEntry = NewSetItem(title: title, id: id, indexPath: (attachment?.collectionIndexPath)!, isPCODownload: true, isNPLocalSong: false, attachment: attachment)
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
        self.npSongTableView.reloadData()
        
        validateNewSet()
        
    }
    
    func validateNewSet() {
        var enable = true
        
        for song in self.songItems {
            if !song.isInNewSetList {
                enable = false
                break
            }
        }
        
//        self.createSetListButton.isEnabled = enable
        self.pcoTableView.reloadData()
    }

    func setlistComplete() -> Bool {
        var complete = true
        
        for song in self.songItems {
            if !song.isInNewSetList {
                complete = false
                break
            }
        }

        return complete
    }

    
    func markAttachmentCell(for attachment : Attachment) {
        
        self.collectionView.selectItem(at: attachment.collectionIndexPath, animated: false, scrollPosition: .centeredHorizontally)
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
    
    func buildFakePCOSetList() {
        var songItem = SongItem(itemID : "0", title : "Here In The Presence", keyName : "B", sequence : 0)
        self.songItems.append(songItem)
        songItem = SongItem(itemID : "1", title : "The Lion And The Lamb", keyName : "B", sequence : 1)
        self.songItems.append(songItem)
        songItem = SongItem(itemID : "2", title : "Not For a Moment", keyName : "Ab", sequence : 2)
        self.songItems.append(songItem)
        songItem = SongItem(itemID : "3", title : "Even So Come", keyName : "C", sequence : 3)
        self.songItems.append(songItem)
        songItem = SongItem(itemID : "4", title : "Fullness", keyName : "C", sequence : 4)
        self.songItems.append(songItem)
        self.pcoTableView.reloadData()
        self.buildNewSetList()
    }
    
    func buildFakeNPSongList() {
        var npSong = NPSongItem(title: "Even So Come", isInNewSetList: false)
        npSongList.append(npSong)
        npSong = NPSongItem(title: "FullnessFriends", isInNewSetList: false)
        npSongList.append(npSong)
        npSong = NPSongItem(title: "Here In The Presence-B (LEAD)", isInNewSetList: false)
        npSongList.append(npSong)
        npSong = NPSongItem(title: "Here In The Presence-B (CHORDS)", isInNewSetList: false)
        npSongList.append(npSong)
    }
    
    func indexAttachments() {
        
        for song in songItems {
            for attachment in song.attachments {
                let section = songItems.index(of: song)
                let row = song.attachments.index(of: attachment)
                attachment.collectionIndexPath = IndexPath(row: row!, section: section!)
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
            if !self.disconnected {
                ai.startAnimating()

            }
            cell.accessoryView = ai
        }
        
        if song.isInNewSetList {
            cell.contentView.backgroundColor = .white
            label.textColor = .black
            detailLabel.textColor = .black
        } else {
            cell.contentView.backgroundColor = UIColor.init(red: 0.5803921569, green: 0.0666666667, blue: 0, alpha: 0.5)
            label.textColor = .white
            label.backgroundColor = .clear
            detailLabel.textColor = .white
            detailLabel.backgroundColor = .clear
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
            cell.backgroundColor = GlobalVariables.pcoBlue
            label.textColor = .white
        } else if setItem.isNPLocalSong {
            cell.backgroundColor = GlobalVariables.npGreen
            label.textColor = .white
        } else {
            cell.backgroundColor = .white
            label.textColor = .black
        }
        
        cell.showsReorderControl = true
        
        return cell
    }

    func npSongTableViewCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NPSongCell", for:indexPath)

        let label = cell.viewWithTag(1000) as! UILabel
        
        let npSong = self.npSongList[indexPath.row]
        
        label.text = npSong.title
        
        if npSong.isInNewSetList {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let moveItem = self.newSetList[sourceIndexPath.row]
        self.newSetList.remove(at: sourceIndexPath.row)
        self.newSetList.insert(moveItem, at: destinationIndexPath.row)
        
        newSetTableView.reloadData()
    }

//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        if tableView == self.pcoTableView {
//            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30))
//            if (section == 0) {
//                headerView.backgroundColor = GlobalVariables.pcoBlue
//            } else {
//                headerView.backgroundColor = UIColor.clear
//            }
//            return headerView
//
//        }
//        return nil
//    }
    
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
        } else if tableView == self.npSongTableView {
            if let cell = self.npSongTableView.cellForRow(at: indexPath) {
                self.npSongTableView.deselectRow(at: indexPath, animated: true)
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                    // delete from newSetTable
                } else {
                    cell.accessoryType = .checkmark
                    // add to newSetTable
                }
                // check to see if set is valid (complete)
            }
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (tableView == self.newSetTableView) && (editingStyle == .delete)  {
            let newItem = self.newSetList[indexPath.row]
            self.newSetList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            for songItem in songItems {
                if songItem.itemID == newItem.itemID {
                    songItem.isInNewSetList = false
                    for a in songItem.attachments {
                        self.collectionView.deselectItem(at: a.collectionIndexPath, animated: false)
                    }
                    break
                }
            }

            validateNewSet()
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
        let song = self.songItems[indexPath.section]
        let title = String(song.attachments[indexPath.row].filename.dropLast(4))
        let newEntry = NewSetItem(title: title, id: song.itemID, indexPath: indexPath, isPCODownload: true, isNPLocalSong: false, attachment: song.attachments[indexPath.row])
        self.newSetList.insert(newEntry, at: 0)
        song.isInNewSetList = true
        self.newSetTableView.reloadData()
        validateNewSet()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        for (x, newItem) in newSetList.enumerated() {
            if newItem.collectionIndexPath == indexPath {
                newSetList.remove(at: x)
                for songItem in songItems {
                    if songItem.itemID == newItem.itemID {
                        songItem.isInNewSetList = false
                        break
                    }
                }
                newSetTableView.reloadData()
                validateNewSet()
                break
            }
        }
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

