//
//  RemoteServer.swift
//  UbercornFrame
//
//  Created by Andy Qua on 22/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation
import Starscream

class RemoteServer {

    private var socket : WebSocket?
    private var apiKey : String = ""
    private var didConnectCallback : ((Bool)->())?
    
    var receivedMessage : ((String)->())?
    var receivedData : ((Data)->())?
    
    var connected = false


    var isConnected : Bool {
        return socket != nil && self.connected
    }
    var error : String = ""
    var code : UInt16 = 0

    init() {
        
    }
    
    func connect( hostName : String, port: Int, apiKey: String, didConnect: ((Bool)->())? ) {
        self.apiKey = apiKey
        self.didConnectCallback = didConnect
        let request = URLRequest(url: URL(string: "ws://\(hostName):\(port)/")!)
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func disconnect() {
        didConnectCallback = nil
        socket?.disconnect()
        socket = nil
    }
    
    func sendCommand( _ cmd : String ) {
        if let socket = socket {
            socket.write(string: cmd) //example on how to write text over the socket!
        }
    }

    func sendDataCommand( cmd: String, data : Data ) {
        if let socket = socket {
            socket.write(string: cmd) 
            socket.write(data: data) //example on how to write text over the socket!
        }
    }
}

extension RemoteServer : WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
            case .connected(let headers):
                print("websocket is connected - \(headers)")
                sendCommand( "CONNECT \(apiKey)" )
                didConnectCallback?(true)
                self.connected = true
            case .disconnected(let reason, let code):
                didConnectCallback?(false)
                didConnectCallback = nil
                self.connected = false
                print("websocket did disconnected - \(reason) : \(code)")
                self.code = code
                self.error = reason
                self.socket = nil
            case .text(let string):
                print("websocket receive message - \(string)")
                receivedMessage?(string)
            case .binary(let data):
                print("websocket recevied data")
                receivedData?(data)
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                connected = false
            case .error(let err):
                connected = false
                print( "Got error - \(err?.localizedDescription ?? "Unknown error")")
        }
    }
}
