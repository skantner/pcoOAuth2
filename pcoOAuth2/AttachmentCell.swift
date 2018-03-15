//
//  AttachmentCell.swift
//  pcoOAuth2
//
//  Created by Scott Kantner on 3/14/18.
//  Copyright © 2018 Kantner Research And Technology. All rights reserved.
//

import UIKit

class AttachmentCell: UICollectionViewCell {
   
    override var isSelected: Bool{
        didSet{
            if self.isSelected
            {
                self.contentView.backgroundColor = UIColor.green
            } else {
                self.contentView.backgroundColor = UIColor.lightGray
            }
        }
    }
}
