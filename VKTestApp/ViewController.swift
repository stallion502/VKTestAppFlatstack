//
//  ViewController.swift
//  VKTestApp
//
//  Created by User on 21/09/2017.
//  Copyright © 2017 User. All rights reserved.
//

import UIKit
import Locksmith
import SDWebImage

class ViewController: UIViewController{

    let authURL = "https://oauth.vk.com/authorize?client_id=5440529&display=page&redirect_uri=http://vk.com&scope=friends,wall&response_type=token&v=5.68&state=123456"
    
    @IBOutlet weak var authWebView: UIWebView!
    @IBOutlet weak var tableView: UITableView!
    public var feedData: [FeedData]?
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(handleRefresh(_:)),for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addSubview(self.refreshControl)
        authWebView.delegate = self
        tableView.estimatedRowHeight = 450
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        if let _ = Locksmith.loadDataForUserAccount(userAccount: "VKTestAccount")
        {
            authWebView.isHidden = true
            NetworkingService.shared.getNews(completionHandler: { [weak self] (feedData) in
                self?.feedData = feedData
                self?.tableView.reloadData()
            })
        }
        else {
            authWebView.loadRequest(URLRequest(url: URL(string: authURL)!))
        }

    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        
        NetworkingService.shared.getNews(completionHandler: { [weak self] (feedData) in
            self?.feedData = feedData
            self?.tableView.reloadData()
        })
        refreshControl.endRefreshing()
    }
    
    @IBAction func logOutAction(_ sender: UIBarButtonItem) {
        
        NetworkingService.shared.logOut(completionHandler: { [unowned self] in
            self.feedData?.removeAll()
            self.authWebView.isHidden = false
            self.view.layoutIfNeeded()
            self.authWebView.loadRequest(URLRequest(url: URL(string: self.authURL)!))
        })
    }
    
}

extension ViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FeedNewsCell
        cell.heightConstraint.constant = 260
        cell.isUserInteractionEnabled = true
        let item = feedData?[indexPath.row]
        cell.likeLabel.text = item?.likes
        cell.repostLabel.text = item?.reposts
        cell.mainTextLabel.text = item?.text
        cell.profilePhoto.sd_setImage(with: URL(string: (item?.profilePhoto)!))
        cell.nameLabel.text = item?.profileName
        
        if (item?.mainPhoto == nil || item?.mainPhoto == "") && (item?.attachments?.count == 0 || item?.attachments == nil)
        {
            cell.heightConstraint.constant = 0
        }
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? FeedNewsCell
            else { return }
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
    }
    
}

extension ViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CVCell", for: indexPath) as! ImageCVCell
        
        if let attachment = feedData?[collectionView.tag].attachments?[indexPath.row].dictionaryValue {
            if attachment["type"] == "photo" {
                var stringURL = attachment["photo"]?["photo_807"].stringValue
                if stringURL == "" {
                    stringURL = attachment["photo"]?["photo_604"].stringValue
                }
                cell.myImageView.sd_setImage(with: URL(string: stringURL!))
            }
            else {
                cell.myImageView.image = #imageLiteral(resourceName: "video")
            }
        }
        else {
            let stringURL = feedData?[collectionView.tag].mainPhoto
            cell.myImageView.sd_setImage(with: URL(string: stringURL!))
        }
        return cell
    }
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ImageCVCell
        let newImageView = UIImageView(image: cell.myImageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action:  #selector(dismissFullscreenImage))
        newImageView.addGestureRecognizer(tap)
        self.view.addSubview(newImageView)
        
    }
    
    func dismissFullscreenImage(sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
    }
 /*
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
 */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfCells = 0
        if let _ = feedData?[collectionView.tag].mainPhoto {
            numberOfCells+=1
        }
        if let _ = feedData?[collectionView.tag].attachments?.count {
            numberOfCells += (feedData?[collectionView.tag].attachments?.count)!
        }
        return numberOfCells
    }

}


extension ViewController : UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        let absoluteString = webView.request?.url?.absoluteString

        if let match = absoluteString?.range(of:"(?<=access_token=)(.*)(?=&expires_in)", options: .regularExpression) {
            let accessToken = absoluteString?.substring(with: match)
            do {
                try Locksmith.saveData(data: ["access_token" : accessToken!], forUserAccount: "VKTestAccount")
            } catch {
                print("Error: Unable to save data")
            }
            webView.isHidden = true
            NetworkingService.shared.getNews(completionHandler: { [weak self] (feedData) in
                self?.feedData = feedData
                self?.tableView.reloadData()
            })
        }
        
        print("loaded")
    }
}
    
