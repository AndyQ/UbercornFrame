//
//  SettingsViewController.swift
//  UbercornFrame
//
//  Created by Andy Qua on 23/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit
import Starscream

class SettingsViewController: UIViewController {
    @IBOutlet weak var txtHostName : UITextField!
    @IBOutlet weak var txtPort : UITextField!

    var socket : WebSocket!
    var hostName : String = ""
    var port : Int = 8765
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let d = UserDefaults.standard
        self.hostName = d.string(forKey: "hostName") ?? ""
        self.port = d.integer(forKey: "port")
        
        self.txtHostName.text = self.hostName
        self.txtPort.text = "\(self.port == -1 ? 8765 : self.port)"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _ = validateAndStoreDetails()
    }
    
    func validateAndStoreDetails( showAlert : Bool = false) -> Bool {
        guard let host = txtHostName.text, host != "" else {
                if showAlert {
                    alert("Invalid or missing hostname" )
                }
                return false
        }
        guard let portstr = txtPort.text, let portNr = Int(portstr), portNr > 0 else {
                if showAlert {
                    alert("Invalid or missing port")
                }
                return false
        }
        
        self.hostName = host
        self.port = portNr
        
        let d = UserDefaults.standard
        d.set(host, forKey: "hostName")
        d.set(portNr, forKey: "port")
                
        return true
    }

    @IBAction func testPressed( _ sender : Any ) {
        
        guard validateAndStoreDetails( showAlert: true) else { return }
        
        socket = WebSocket(url: URL(string: "ws://\(self.hostName):\(self.port)")!)
        socket.onConnect = { [unowned self] in
            print( "Connected!" )
            self.socket.disconnect()
        }
        socket.onDisconnect = { [unowned self] (error: Error?) in
            var errorMsg : String? = nil
            if let error = error as? Starscream.ErrorType {
                let code = error._code
                if code != 1000 {
                    errorMsg = "Unable to connect to UbercornFrame on \(self.hostName):\(self.port)) - is it running?\n\(error)"
                }
            }
            
            if let errorMsg = errorMsg {
                self.alert( errorMsg)
            } else {
                self.alert( "Successfully connected to UbercornFrame on \(self.hostName):\(self.port))" )
            }
        }
        socket.connect()

    }
}
