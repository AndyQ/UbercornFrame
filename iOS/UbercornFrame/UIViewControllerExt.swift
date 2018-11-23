//
//  UIViewControllerExt.swift
//  UbercornFrame
//
//  Created by Andy Qua on 23/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func alert(_ message: String, title: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
