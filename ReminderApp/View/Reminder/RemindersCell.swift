//
//  RemindersCellTableViewCell.swift
//  ReminderApp
//
//  Created by ikame on 8/25/25.
//

import UIKit



class RemindersCell: UITableViewCell, UITextViewDelegate {

    
    @IBOutlet weak var inforButton: UIButton!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var title: UITextView!
    @IBOutlet weak var note: UITextView!
    @IBOutlet weak var cardView: UIView!
    
    
    // Callbacks để VC nhận thay đổi
    var onToggleDone: (() -> Void)?
    var onTitleChanged: ((String) -> Void)?
    var onNoteChanged:  ((String) -> Void)?
    var onReturnFromTitle: (() -> Void)?
    var onHeightChange: (() -> Void)?
    var onInfoTapped: (() -> Void)?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cardView.backgroundColor = .neutral5
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        selectionStyle = .none

                // TextView tự giãn
        title.delegate = self
        note.delegate = self
        
        title.isScrollEnabled = false
        note.isScrollEnabled = false

        title.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        note.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 8, right: 0)

        title.setContentHuggingPriority(.required, for: .vertical)
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        note.setContentHuggingPriority(.required, for: .vertical)
        note.setContentCompressionResistancePriority(.required, for: .vertical)

        title.returnKeyType = .next
        note.returnKeyType = .default
        
    }

    func configure(with item: ReminderItem) {
        title.text = item.title
        note.text  = item.note
        updateCheckImage(isDone: item.isDone)
        }

    func configure(with obj: ReminderObject) {
         title.text = obj.title
         note.text  = obj.note ?? ""
         updateCheckImage(isDone: obj.isDone)
     }
    
        private func updateCheckImage(isDone: Bool) {
            let name = isDone ? "checkmark.circle.fill" : "circle"
            checkButton.setImage(UIImage(systemName: name), for: .normal)
        }

        @IBAction func checkTapped(_ sender: UIButton) {
            onToggleDone?()
        }
    
    @IBAction func inforTapped(_ sender: Any) {
        onInfoTapped?()
    }
    
    func textView(_ textView: UITextView,
                      shouldChangeTextIn range: NSRange,
                      replacementText text: String) -> Bool {
            if textView == title && text == "\n" {
                onReturnFromTitle?()
                return false
            }
            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView == title {
                onTitleChanged?(textView.text)
            } else {
                onNoteChanged?(textView.text)
            }
            onHeightChange?() // báo VC cập nhật chiều cao cell
        }
    }
