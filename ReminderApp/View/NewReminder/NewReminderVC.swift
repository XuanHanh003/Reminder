//
//  NewReminderVC.swift
//  ReminderApp
//
//  Created by ikame on 8/25/25.
//

import UIKit
import RealmSwift
class NewReminderVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    // Realm
       private let realm = try! Realm()
       var reminderId: ObjectId?               // nil = create, có giá trị = edit
       private var reminder: ReminderObject?   // object live khi edit

       private enum Row { case titleNote, dateRow, datePicker, tag }
       private var rows: [Row] = [.titleNote, .dateRow, .tag]

       private var itemTitle = ""
       private var itemNote  = ""
       private var isDateOn  = false
       private var selectedDate = Date()

       private let df: DateFormatter = {
           let d = DateFormatter()
           d.dateStyle = .medium
           d.timeStyle = .none
           return d
       }()

       override func viewDidLoad() {
           super.viewDidLoad()
           view.backgroundColor = .systemBackground

           // Nếu edit → load object + bind sẵn dữ liệu
           if let id = reminderId,
              let obj = realm.object(ofType: ReminderObject.self, forPrimaryKey: id) {
               reminder = obj
               itemTitle = obj.title
               itemNote  = obj.note ?? ""
               if let d = obj.dueDate {
                   isDateOn = true
                   selectedDate = d
                   rows = [.titleNote, .dateRow, .datePicker, .tag]
               }
           }

           // Nav bar
           navigationItem.leftBarButtonItem = UIBarButtonItem(
               title: "Cancel", style: .plain, target: self, action: #selector(dismissSelf))
           navigationItem.rightBarButtonItem = UIBarButtonItem(
               title: "Done", style: .done, target: self, action: #selector(doneTapped))

           // Table
           tableView.dataSource = self
           tableView.delegate   = self
           tableView.backgroundColor = .systemGroupedBackground
           tableView.separatorStyle = .singleLine
           tableView.rowHeight = UITableView.automaticDimension
           tableView.estimatedRowHeight = 140
           tableView.keyboardDismissMode = .onDrag

           tableView.register(UINib(nibName: "InforCell", bundle: nil),
                              forCellReuseIdentifier: "InforCell")
           tableView.register(UINib(nibName: "DatePickerCell", bundle: nil),
                              forCellReuseIdentifier: DatePickerCell.reuseID)
       }

       @objc private func dismissSelf() { dismiss(animated: true) }

       @objc private func doneTapped()  {
           let trimmed = itemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
           guard !trimmed.isEmpty else {
               let ac = UIAlertController(title: "Title is required", message: nil, preferredStyle: .alert)
               ac.addAction(UIAlertAction(title: "OK", style: .default))
               present(ac, animated: true)
               return
           }

           if let r = reminder {
               // EDIT
               try? realm.write {
                   r.title = trimmed
                   r.note  = itemNote.isEmpty ? nil : itemNote
                   r.dueDate = isDateOn ? selectedDate : nil
                   r.updatedAt = Date()
               }
           } else {
               // CREATE
               let obj = ReminderObject()
               obj.title = trimmed
               obj.note  = itemNote.isEmpty ? nil : itemNote
               obj.dueDate = isDateOn ? selectedDate : nil
               obj.createdAt = Date()
               obj.updatedAt = Date()
               try? realm.write { realm.add(obj) }
           }

           dismiss(animated: true)
       }

       private func toggleDateRow(on: Bool) {
           isDateOn = on
           rows = [.titleNote, .dateRow] + (on ? [.datePicker] : []) + [.tag]
           UIView.setAnimationsEnabled(false)
           tableView.reloadData()
           UIView.setAnimationsEnabled(true)
       }
   }

   // MARK: - DataSource/Delegate
   extension NewReminderVC: UITableViewDataSource, UITableViewDelegate {

       func numberOfSections(in tableView: UITableView) -> Int { 1 }
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

       func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
           switch rows[ip.row] {
           case .titleNote:
               guard let cell = tv.dequeueReusableCell(withIdentifier: "InforCell", for: ip) as? InforCell
               else { return UITableViewCell() }
               cell.title.text = itemTitle
               cell.note.text  = itemNote
               cell.title.delegate = self
               cell.note.delegate  = self
               cell.title.tag = 1
               cell.note.tag  = 2
               if itemTitle.isEmpty && ip.row == 0 {
                   DispatchQueue.main.async { cell.title.becomeFirstResponder() }
               }
               return cell

           case .dateRow:
               let id = "DateRowCell"
               let cell = tv.dequeueReusableCell(withIdentifier: id) ??
                          UITableViewCell(style: .value1, reuseIdentifier: id)
               cell.selectionStyle = .none
               cell.imageView?.image = UIImage(systemName: "calendar")
               cell.textLabel?.text = "Date"
               cell.detailTextLabel?.text = isDateOn ? df.string(from: selectedDate) : "Today"
               let sw = UISwitch()
               sw.isOn = isDateOn
               sw.addTarget(self, action: #selector(dateSwitchChanged(_:)), for: .valueChanged)
               cell.accessoryView = sw
               return cell

           case .datePicker:
               let cell = tv.dequeueReusableCell(withIdentifier: DatePickerCell.reuseID, for: ip) as! DatePickerCell
               cell.configure(date: selectedDate)
               cell.onDateChanged = { [weak self] d in
                   guard let self = self else { return }
                   self.selectedDate = d
                   if let idx = self.rows.firstIndex(of: .dateRow) {
                       tv.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
                   }
               }
               return cell

           case .tag:
               let id = "TagCell"
               let cell = tv.dequeueReusableCell(withIdentifier: id) ??
                          UITableViewCell(style: .value1, reuseIdentifier: id)
               cell.textLabel?.text = "Tag"
               cell.detailTextLabel?.text = "None"
               cell.imageView?.image = UIImage(systemName: "tag")
               cell.accessoryType = .disclosureIndicator
               return cell
           }
       }

       @objc private func dateSwitchChanged(_ sw: UISwitch) { toggleDateRow(on: sw.isOn) }
   }

   // MARK: - UITextViewDelegate
   extension NewReminderVC: UITextViewDelegate {
       func textViewDidChange(_ textView: UITextView) {
           if textView.tag == 1 { itemTitle = textView.text }
           else if textView.tag == 2 { itemNote = textView.text }

           UIView.setAnimationsEnabled(false)
           tableView.beginUpdates()
           tableView.endUpdates()
           UIView.setAnimationsEnabled(true)
       }

       func textView(_ textView: UITextView,
                     shouldChangeTextIn range: NSRange,
                     replacementText text: String) -> Bool {
           if textView.tag == 1 && text == "\n" {
               if let cell = textView.superview(of: InforCell.self) {
                   cell.note.becomeFirstResponder()
               }
               return false
           }
           return true
       }
   }

   // MARK: - Tìm superview theo loại
   private extension UIView {
       func superview<T: UIView>(of type: T.Type) -> T? {
           var v: UIView? = self
           while let current = v {
               if let match = current as? T { return match }
               v = current.superview
           }
           return nil
       }
   }
