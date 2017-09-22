//
//  FeedNewsCell.swift
//  VKTestApp
//
//  Created by User on 22/09/2017.
//  Copyright © 2017 User. All rights reserved.
//

import Foundation
import UIKit

class FeedNewsCell: UITableViewCell {
    
    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var repostLabel: UILabel!
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>(dataSourceDelegate: D, forRow row: Int) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row
        collectionView.reloadData()
    }
}
