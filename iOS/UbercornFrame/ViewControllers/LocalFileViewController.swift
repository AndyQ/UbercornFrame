//
//  LocalFileViewController.swift
//  UbercornFrame
//
//  Created by Andy Qua on 26/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

class LocalFileViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var items = [URL]()
    
    typealias FileSelectionHandler = (URL) -> Void
    var selectedItem : FileSelectionHandler?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            items = try FileManager.default.contentsOfDirectory(at: getDocsFolderURL(), includingPropertiesForKeys: nil, options: [])
            items = items.filter { ["gif","bmp","png","jpg"].contains($0.pathExtension) }
            items.sort { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            alert("Error loading files - \(error)" )
        }
    }
    
    @IBAction func editPressed(_ sender: Any) {
        self.tableView.isEditing.toggle()
    }
}

extension LocalFileViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        cell.textLabel!.text = items[indexPath.row].lastPathComponent
        return cell
    }
}

extension LocalFileViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItem?( items[indexPath.row] )
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try? FileManager.default.removeItem(at: self.items[indexPath.row])
            self.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
