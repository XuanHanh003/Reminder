//
//  DatePickerCell.swift
//  ReminderApp
//
//  Created by ikame on 8/26/25.
//

import UIKit

class DatePickerCell: UITableViewCell {
    static let reuseID = "DatePickerCell"

    @IBOutlet weak var picker: UIDatePicker!
    var onDateChanged: ((Date) -> Void)?

        override func awakeFromNib() {
            super.awakeFromNib()
            selectionStyle = .none
            backgroundColor = .clear
            if #available(iOS 14.0, *) {
                picker.preferredDatePickerStyle = .inline
            }
            picker.addTarget(self, action: #selector(change), for: .valueChanged)
        }

        func configure(date: Date) { picker.date = date }
        @objc private func change() { onDateChanged?(picker.date) }
    }

