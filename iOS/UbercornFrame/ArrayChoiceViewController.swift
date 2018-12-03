//
//  ArrayChoiceViewController.swift
//  UbercornFrame
//
//  Created by Andy Qua on 20/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

class AlwaysPresentAsPopover : NSObject, UIPopoverPresentationControllerDelegate {
    
    // `sharedInstance` because the delegate property is weak - the delegate instance needs to be retained.
    private static let sharedInstance = AlwaysPresentAsPopover()
    
    private override init() {
        super.init()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    static func configurePresentation(forController controller : UIViewController) -> UIPopoverPresentationController {
        controller.modalPresentationStyle = .popover
        let presentationController = controller.presentationController as! UIPopoverPresentationController
        presentationController.delegate = AlwaysPresentAsPopover.sharedInstance
        return presentationController
    }
    
}

class ArrayChoiceTableViewController : UITableViewController {
    
    typealias SelectionHandler = (String) -> Void
    
    private let values : [String]
    private let onSelect : SelectionHandler?
    
    init(_ values : [String], scroll: Bool = false, onSelect : SelectionHandler? = nil) {
        self.values = values
        self.onSelect = onSelect
        
        super.init(style: .plain)
        self.tableView.isScrollEnabled = scroll
        
        // Calc preferred size
        let h : CGFloat = CGFloat(min( self.values.count * 44, 500 ))
        var w : CGFloat = 0
        let font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        for str in values {
            w = max(w, str.width(withConstrainedHeight:44, font:font)+40)
        }
        self.preferredContentSize = CGSize(width:min(w, 300), height:h)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        cell.textLabel!.text = self.values[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true)
        onSelect?(values[indexPath.row])
    }
}
