//
//  FeedData.swift
//  VKTestApp
//
//  Created by User on 21/09/2017.
//  Copyright © 2017 User. All rights reserved.
//

import Foundation
import  SwiftyJSON

struct FeedData {
    
    var profilePhoto: String
    var profileName: String
    var text: String
    var likes: String
    var reposts: String
    var mainPhoto: String?
    var attachments: [JSON]?
    
    init(profilePhoto: String, profileName: String, text: String, likes: String, reposts: String, mainPhoto: String?, attachments: [JSON]?) {
        self.profileName = profileName
        self.profilePhoto = profilePhoto
        self.text = text
        self.likes = likes
        self.reposts = reposts
        self.mainPhoto = mainPhoto
        self.attachments = attachments
    }
}
