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

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.songTitleLabel.text = self.songTitle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func test(openUrl : String) {
//       let url = "https://api.planningcenteronline.com/services/v2/service_types/541380/plans/34970735/items/482233555/attachments/46788848/open"
        let http = Http()
        http.authzModule = self.authzModule
        http.request(method: .post,
                     path: openUrl,
            completionHandler: {(response, error) in
                if (error != nil) {
                    print("Error -> \(error!.localizedDescription)")
                } else {
                    print("\(response!)")
                    if let jsonResult = response as? Dictionary<String, Any>,
                        let attachmentData = jsonResult["data"] as? Dictionary<String, Any>,
                        let attributes = attachmentData["attributes"] as? Dictionary<String, Any>,
                        let attachmentURL = attributes["attachment_url"] as? String {
                        print("attachmentURL: \(attachmentURL)")
                        self.getPCOAttachment(attachmentUrl: attachmentURL)
//                        http.download(url: attachmentURL,
//                                      method: .post,
//                                      progress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)  in
//                                        print("bytesWritten: \(bytesWritten), totalBytesWritten: \(totalBytesWritten), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
//                        }, completionHandler: { (response, error) in
//                            print("Download complete: \(response!)")
//                        })

                    }
                }
        })

    }
    
    func getPCOAttachment(attachmentUrl : String) {
       
//        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
//        print("\(documents)")
//        print("\(attachmentUrl)")
        
        let http = Http()
        //http.authzModule = self.authzModule
        
        http.download(url: attachmentUrl,
                      method: .post,
                      progress: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)  in
                        print("bytesWritten: \(bytesWritten), totalBytesWritten: \(totalBytesWritten), totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        }, completionHandler: { (response, error) in
            print("Download complete: \(response!)")
        })
    }
    
    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        let attachment = self.attachmentList[indexPath.row]
        test(openUrl: attachment.url)
        //getPCOAttachment(attachmentUrl: attachment.url)
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

}
