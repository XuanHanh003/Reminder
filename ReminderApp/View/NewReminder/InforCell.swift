//
//  InforCell.swift
//  ReminderApp
//
//  Created by ikame on 8/26/25.
//

import UIKit

class InforCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var title: UITextView!
    @IBOutlet weak var note: UITextView!

 
    override func awakeFromNib() {
            super.awakeFromNib()

            // Card style
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            cardView.backgroundColor = .secondarySystemBackground
            cardView.layer.cornerRadius = 16
            cardView.layer.masksToBounds = true
            selectionStyle = .none

            // TextView tự giãn (không cuộn)
            [title, note].forEach {
                $0?.isScrollEnabled = false
                $0?.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
                $0?.setContentHuggingPriority(.required, for: .vertical)
                $0?.setContentCompressionResistancePriority(.required, for: .vertical)
            }
            title.returnKeyType = .next
            note.returnKeyType  = .default
        }

        func configure(title: String, note: String) {
            self.title.text = title
            self.note.text  = note
        }
    }
