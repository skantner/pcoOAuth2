//
//  AttachmentsViewController.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/9/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import UIKit
import AeroGearHttp
import AeroGearOAuth2

class AttachmentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var songTitleLabel: UILabel!
    
    var attachmentList : [Attachment]!
    var songTitle : String!
    var authzModule: AuthzModule!

    override func viewDidLoad() {
        super.viewDidLoad()
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("Documents dir:\(documentsURL)")
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.songTitleLabel.text = self.songTitle
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
                        print("Downloading \(fileName)...")
                        let s3http = Http()
                        s3http.download(url: attachmentUrl,
                                      method: .get,
                                      progress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)  in
                                        print("bytesWritten: \(bytesWritten), totalBytesWritten: \(totalBytesWritten), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
                        }, completionHandler: { (response, error) in
//                            print("Download complete: \(response!)")
                            print("Download complete.")
                        })
                    }
                }
        })
    }
    
    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let attachment = self.attachmentList[indexPath.row]
        getPCOAttachment(openUrl: attachment.url, fileName: attachment.filename)
    }
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachmentCell", for:indexPath)
        let label = cell.viewWithTag(1000) as! UILabel
        let attachment = self.attachmentList[indexPath.row]
        label.text = attachment.filename
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.attachmentList.count
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Houskeeping
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
