//
//  RemoteServer.swift
//  UbercornFrame
//
//  Created by Andy Qua on 22/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Starscream

class RemoteServer {


    var socket : WebSocket?
    var didConnectCallback : ((Bool)->())?
    
    var isConnected : Bool {
        return socket != nil && socket!.isConnected
    }
    
    init() {
        
    }
    
    func connect( hostName : String, port: Int, didConnect: ((Bool)->())? ) {
        self.didConnectCallback = didConnect
        socket = WebSocket(url: URL(string: "ws://\(hostName):\(port)/")!)
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
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
        sendCommand( "CONNECT" )
        didConnectCallback?(true)
//        didConnectCallback = nil
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        didConnectCallback?(false)
        didConnectCallback = nil
        print("websocket did disconnected")
        self.socket = nil
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("websocket receive message - \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("websocket recevied data")
    }
}
