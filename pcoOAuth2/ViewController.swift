//
//  ViewController.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 2/19/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import UIKit

// PCO Client ID = 3c4a2ee10fae6870972de58cfc661341348c0e5dc5b0727fa9fb669b388f565b
// PCO Secret = 896b9f9605027405d465a9a9c82b9d6613ec5eeffbb8c77b7be96b73e597f873

// https://api.planningcenteronline.com/oauth/authorize
// https://api.planningcenteronline.com/oauth/token
// scope = services
// 1
import AeroGearHttp
import AeroGearOAuth2

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    
    func iTunesURL(searchText: String) -> URL {
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let urlString = String(format:"https://itunes.apple.com/search?term=%@", encodedText)
        let url = URL(string: urlString)
        return url!
    }
    
    
    @IBAction func goPressed() {
        
  //      let config = Config(baseURL: "https://api.planningcenteronline.com/oauth/authorize",
                            
        let url = iTunesURL(searchText: "Hillsong")
        print ("URL: '\(url)'")
        if let data = performStoreRequest(with: url) {
            let results = parse(data: data)
            print ("Results: '\(results)'")
        }
        
        
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

