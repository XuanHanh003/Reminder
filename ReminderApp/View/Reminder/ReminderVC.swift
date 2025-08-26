//
//  RemindersListVC.swift
//  ReminderApp
//
//  Created by ikame on 8/25/25.
//

import UIKit
import RealmSwift

struct ReminderItem {
    var id: ObjectId? = nil
    var title: String = ""
    var note:  String = ""
    var isDone: Bool  = false
}

class ReminderVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var addReminder: UIButton!
    
    private let realm = try! Realm() // [Realm]

        private var items: [ReminderItem] = [] {
            didSet { updateEmptyState() }
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            setupNavigationBar()
            searchBar.searchBarStyle = .minimal
            searchBar.backgroundImage = UIImage()

            // Table setup
            tableView.dataSource = self
            tableView.delegate   = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.keyboardDismissMode = .onDrag
            tableView.tableFooterView = UIView()

            // ĐĂNG KÝ NIB CHO CELL (tránh lỗi "unable to dequeue...")
            tableView.register(UINib(nibName: "RemindersCell", bundle: nil),
                               forCellReuseIdentifier: "RemindersCell")

            // [Realm] nạp dữ liệu đã lưu để list không trống khi mở app
            loadFromRealm()
            updateEmptyState()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // [Realm] sau khi đóng sheet Edit → đồng bộ lại list
            loadFromRealm()
        }

        // [Realm] đọc tất cả, sort theo createdAt cũ→mới (giữ thứ tự đơn giản)
        private func loadFromRealm() {
            let objs = realm.objects(ReminderObject.self)
                .sorted(byKeyPath: "createdAt", ascending: true)
            items = objs.map { o in
                ReminderItem(id: o._id, title: o.title, note: o.note ?? "", isDone: o.isDone)
            }
            tableView.reloadData()
        }

        func setupNavigationBar() {
            self.title = "Reminders"
            navigationController?.navigationBar.titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.neutral1]
        }

        // Nút + New Reminder (GIỮ NGUYÊN)
        @IBAction func onTapAddReminder(_ sender: Any) {
            items.insert(ReminderItem(), at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.performBatchUpdates({
                tableView.insertRows(at: [indexPath], with: .automatic)
            }, completion: { _ in
                if let cell = self.tableView.cellForRow(at: indexPath) as? RemindersCell {
                    cell.title.becomeFirstResponder() // focus vào UITextView "title"
                }
            })
        }

        // Empty state "No Reminders"
        private func updateEmptyState() {
            if items.isEmpty {
                let label = UILabel()
                label.text = "No Reminders"
                label.textAlignment = .center
                label.textColor = .tertiaryLabel
                tableView.backgroundView = label
            } else {
                tableView.backgroundView = nil
            }
        }

        // [Realm] đảm bảo item ở index đã được lưu; nếu chưa thì tạo object và gán id
        @discardableResult
        private func ensurePersistedItem(at index: Int) -> ObjectId {
            var it = items[index]
            if let id = it.id { return id }

            let obj = ReminderObject()
            obj.title = it.title.trimmingCharacters(in: .whitespacesAndNewlines)
            obj.note  = it.note.isEmpty ? nil : it.note
            obj.isDone = it.isDone
            obj.createdAt = Date()
            obj.updatedAt = Date()
            try! realm.write { realm.add(obj) }

            items[index].id = obj._id
            return obj._id
        }

        private func presentNewReminder(for indexPath: IndexPath) {
            view.endEditing(true)

            // [Realm] nếu item đang là “nháp”, tạo object trước để sheet edit cùng một bản ghi
            let id = ensurePersistedItem(at: indexPath.row)

            let vc = NewReminderVC(nibName: "NewReminderVC", bundle: nil)
            vc.title = "New Reminder" // tiêu đề trên navigation bar
            vc.reminderId = id        // [Realm] truyền ObjectId sang màn sau

            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.prefersLargeTitles = false

            if #available(iOS 15.0, *) {
                nav.modalPresentationStyle = .pageSheet
                if let sheet = nav.sheetPresentationController {
                    sheet.detents = [.large()]                 // chỉ large -> mở full chiều cao
                    sheet.selectedDetentIdentifier = .large
                    sheet.prefersGrabberVisible = true
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                }
            } else {
                nav.modalPresentationStyle = .fullScreen
            }

            present(nav, animated: true)
        }
    }

    // MARK: - DataSource & Delegate
    extension ReminderVC: UITableViewDataSource, UITableViewDelegate {
        func numberOfSections(in tableView: UITableView) -> Int { 1 }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            items.count
        }

        func tableView(_ tableView: UITableView,
                       cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "RemindersCell",
                for: indexPath
            ) as? RemindersCell else { return UITableViewCell() }

            let item = items[indexPath.row]
            cell.configure(with: item)

            // Callbacks
            cell.onToggleDone = { [weak self, weak cell] in
                guard let self = self else { return }
                self.items[indexPath.row].isDone.toggle()

                // [Realm] ghi lại
                let id = self.items[indexPath.row].id ?? self.ensurePersistedItem(at: indexPath.row)
                if let live = self.realm.object(ofType: ReminderObject.self, forPrimaryKey: id) {
                    try? self.realm.write {
                        live.isDone = self.items[indexPath.row].isDone
                        live.updatedAt = Date()
                    }
                }
                cell?.configure(with: self.items[indexPath.row])
            }

            cell.onTitleChanged = { [weak self] text in
                guard let self = self else { return }
                self.items[indexPath.row].title = text
                // [Realm] nếu đã có id thì cập nhật live
                if let id = self.items[indexPath.row].id,
                   let live = self.realm.object(ofType: ReminderObject.self, forPrimaryKey: id) {
                    try? self.realm.write { live.title = text; live.updatedAt = Date() }
                }
            }

            cell.onNoteChanged = { [weak self] text in
                guard let self = self else { return }
                self.items[indexPath.row].note = text
                if let id = self.items[indexPath.row].id,
                   let live = self.realm.object(ofType: ReminderObject.self, forPrimaryKey: id) {
                    try? self.realm.write {
                        live.note = text.isEmpty ? nil : text
                        live.updatedAt = Date()
                    }
                }
            }

            cell.onReturnFromTitle = { [weak cell] in
                cell?.note.becomeFirstResponder()
            }

            cell.onHeightChange = { [weak self] in
                guard let self = self else { return }
                UIView.setAnimationsEnabled(false)
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
                UIView.setAnimationsEnabled(true)
            }

            cell.onInfoTapped = { [weak self, weak cell] in
                guard let self = self,
                      let cell = cell,
                      let ip = self.tableView.indexPath(for: cell) else { return }
                self.presentNewReminder(for: ip)

            return cell
        }
    }
