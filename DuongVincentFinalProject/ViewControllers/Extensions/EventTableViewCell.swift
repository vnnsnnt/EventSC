//
//  EventTableViewCell.swift
//  DuongVincentFinalProject
//
//  Created by Vincent Duong on 4/29/23.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventDescription: UILabel!
    @IBOutlet weak var eventDateTime: UILabel!
    @IBOutlet weak var eventLocation: UILabel!
    @IBOutlet weak var bookmarkIndicator: UIImageView!
    @IBOutlet weak var notificationIndicator: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
