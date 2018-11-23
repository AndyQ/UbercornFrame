//
//  RemoteServer.swift
//  GameFrame
//
//  Created by Andy Qua on 22/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Starscream

class RemoteServer {


    var socket : WebSocket!
    
    init() {
        
    }
    
    func connect() {
//        socket = WebSocket(url: URL(string: "ws://localhost:8765/")!)
        socket = WebSocket(url: URL(string: "ws://display.local:8765/")!)
        socket.delegate = self
        socket.connect()

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
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
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
