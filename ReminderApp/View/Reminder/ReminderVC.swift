//
//  RemindersListVC.swift
//  ReminderApp
//
//  Created by ikame on 8/25/25.
//

import UIKit

class ReminderVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBAction func addReminder(_ sender: Any) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        searchBar.searchBarStyle = .minimal     
            searchBar.backgroundImage = UIImage()

        // Do any additional setup after loading the view.
    }

    func setupNavigationBar() {
        self.title = "Reminders"
        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.neutral1]
    }
    
}
