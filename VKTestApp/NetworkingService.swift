//
//  NetworkingService.swift
//  VKTestApp
//
//  Created by User on 21/09/2017.
//  Copyright © 2017 User. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Locksmith

class NetworkingService {
    
    static let shared = NetworkingService()
    
    private init() {}
    
    func getNews(completionHandler: @escaping ([FeedData]) -> Void) {
        guard let lockSmithDic = Locksmith.loadDataForUserAccount(userAccount: "VKTestAccount")
            else {return}
        
        Alamofire.request("https://api.vk.com/method/newsfeed.get?oauth=1&return_banned=1&max_photos=10&start_from=0&count=50&v=5.60&access_token=\(lockSmithDic["access_token"]!)").responseJSON { (responce) in
            
            let json = JSON(responce.value!)
            let items = json["response"]["items"].arrayValue
            let groupes = json["response"]["groups"].arrayValue
            let profiles = json["response"]["profiles"].arrayValue
            var i = 1
            var feedArr = [FeedData]()
            for _ in 0...items.count/2-1  {
                let type = items[i]["type"].stringValue
                var sourceID = items[i]["source_id"].stringValue
                var source = Int(sourceID)! > 0 ? profiles : groupes
                sourceID = sourceID.replacingOccurrences(of: "-", with: "")
                source = source.filter { $0["id"].stringValue == sourceID }
                let profilePhoto = source[0]["photo_50"].stringValue
                let firstName = source[0]["first_name"].stringValue
                let lastName = source[0]["last_name"].stringValue
                let profileName = firstName == "" ? source[0]["name"].stringValue :
                    firstName + " " + lastName
                if type == "wall_photo" {
                    let photos = items[i]["photos"].dictionaryValue["items"]?.arrayValue
                    
                    for photo in photos!{
                        var mainPhoto = photo["photo_807"].stringValue
                        if mainPhoto == "" {
                            mainPhoto = photo["photo_604"].stringValue
                        }
                        let likes = photo["likes"]["count"].stringValue
                        let reposts = photo["reposts"]["count"].stringValue
                        let text = photo["text"].stringValue
                        feedArr.append(FeedData.init(profilePhoto: profilePhoto, profileName: profileName, text: text, likes: likes, reposts: reposts, mainPhoto: mainPhoto, attachments: nil))
                    }
                    i+=2
                    continue
                }
                let likes = items[i]["likes"]["count"].stringValue
                let reposts = items[i]["reposts"]["count"].stringValue
                let text = items[i]["text"].stringValue
                let attachments = items[i]["attachments"].arrayValue.filter({ $0["type"].stringValue == "photo" || $0["type"].stringValue == "video"})
                feedArr.append(FeedData.init(profilePhoto: profilePhoto, profileName: profileName, text: text, likes: likes, reposts: reposts, mainPhoto: nil, attachments: attachments))
                i+=2
            }
            print(feedArr)
            completionHandler(feedArr)
        }
    }
    
    func logOut(completionHandler: @escaping () -> Void) {
        Alamofire.request("https://api.vk.com/oauth/logout").responseJSON { (responce) in
            print(responce.value ?? "")
            URLCache.shared.removeAllCachedResponses()
            URLCache.shared.diskCapacity = 0
            URLCache.shared.memoryCapacity = 0
            
            if let cookies = HTTPCookieStorage.shared.cookies {
                for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
            do {
                try Locksmith.deleteDataForUserAccount(userAccount: "VKTestAccount")
            } catch {
                print("Can't delete VK info")
            }
            completionHandler()
        }
    }
}
