//
//  ViewController.swift
//  UbercornFrame
//
//  Created by Andy Qua on 19/11/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit
import MobileCoreServices

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

class ViewController: UIViewController {
    static let menuItems = ["New file", "Load file", "Save file", "Debug pasteboard", "Paste image", "Disconnect from Ubercorn Frame", "Connect to Ubercorn Frame", "Settings"]

    @IBOutlet weak var verticalStackView: UIStackView!
    @IBOutlet weak var paletteView: PaletteView!

    @IBOutlet weak var frameLabel: UILabel!
    @IBOutlet weak var frameDelayLabel: UILabel!
    @IBOutlet weak var connectedLabel: UILabel!

    var cells = [[UIView]]()
    var lastTouchedX : Int = -1
    var lastTouchedY : Int = -1

    var currentColor : UIColor!
    
    var remoteServer : RemoteServer = RemoteServer()
    
    let animation = Animation()
    
    var animating = false
    var frameIndex : Int = -1 {
        didSet {
        }
    }
    
    var currentFrame : ImageFrame {
        return animation.currentFrame
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named:"image.png")!
        let cgImage = image.cgImage!
        if let rawData = image.cgImage!.dataProvider?.data,
            let buf =  CFDataGetBytePtr(rawData) {
            let length = CFDataGetLength(rawData)

            var l = 0
            for y in 0 ..< 160 {
                for x in 0 ..< 160 {
                    if buf[l] != 0 {
                        print( "\(x/10),\(y/10) - \(buf[l])" )
                    }
                    l += 1
                }
            }
            print( "len - \(length)" )
            
        }
        
        buildFrame()
        
        animation.frameChanged = { [unowned self] (frameNr) in
            self.frameLabel.text = "\(self.animation.frameIndex+1) / \(self.animation.numberOfFrames)"
            self.frameDelayLabel.text = "\(self.currentFrame.delay)ms"

        }
        
        
        paletteView.colorChanged = { [unowned self] (color) in
            self.currentColor = color
        }

        paletteView.changePalettePressed = { [unowned self] in
            let items = PaletteManager.instance.getAllPaletteNames()
            let controller = ArrayChoiceTableViewController(items, scroll:true) { [unowned self] (name) in
                self.paletteView.setPalette(name: name)
            }
            self.showPopup(controller, sourceView: self.paletteView )
        }
        paletteView.setPalette(name: PaletteManager.instance.initialPalette )
        
        self.frameDelayLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.changeFrameDelayPressed(_:))))
        
        frameIndex = 0
    }

    override func viewDidAppear(_ animated: Bool) {
        frameToView(self.currentFrame)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LocalFileViewController {
            
            vc.selectedItem = { [unowned self] (url) in
                self.loadFile(fromURL: url)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}


// MARK: UI interactions
extension ViewController {

    @objc func cellTapped( _ gr : UITapGestureRecognizer ) {
        guard let cell = gr.view else { return }
        
        cell.backgroundColor = .random()
    }


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self.view) else { return }
        
        guard let v = self.view.hitTest(p, with: nil) else { return }
        guard let (x,y) = cells.indices(of: v) else { return }
        
        if x != lastTouchedX || y != lastTouchedY {
            setPixel( x:x, y:y, c:currentColor)
        }
        lastTouchedX = x
        lastTouchedY = y
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self.view) else { return }
        
        guard let v = self.view.hitTest(p, with: nil) else { return }
        guard let (x,y) = cells.indices(of: v) else { return }
        
        if x != lastTouchedX || y != lastTouchedY {
            setPixel( x:x, y:y, c:currentColor)
        }
        lastTouchedX = x
        lastTouchedY = y
    }
    
    @IBAction func playPausePressed( _ sender: Any ) {
        if let btn = sender as? UIButton, let title = btn.title(for: .normal) {
            if title == "Play" {
                btn.setTitle("Stop", for: .normal)
                animating = true
                doAnimation()
            } else {
                btn.setTitle("Play", for: .normal)
                animating = false
            }
        }
    }
    
    @IBAction func changeFrameDelayPressed( _ gr: UITapGestureRecognizer ) {
        var items = [String]()
        for i in stride(from:10, to:110, by:10) {
            items.append( "\(i)ms")
        }
        for i in stride(from:100, to:1050, by:50) {
            items.append( "\(i)ms")
        }
        let controller = ArrayChoiceTableViewController(items, scroll:true) { [unowned self] (name) in
            self.animation.currentFrame.delay = Int(name.replacingOccurrences(of: "ms", with: "")) ?? 0
            self.frameDelayLabel.text = "\(self.currentFrame.delay)ms"
        }
        
        self.showPopup(controller, sourceView: gr.view! )
    }

    @IBAction func clearPressed( _ sender: Any ) {
        clearView(color:currentColor)
    }
    
    @IBAction func addFramePressed( _ sender: Any ) {
        addFrame()
    }
    
    @IBAction func duplicateFramePressed( _ sender: Any ) {
        duplicateFrame()
    }
    
    @IBAction func deleteFramePressed( _ sender: Any ) {
        deleteFrame()
    }
    
    @IBAction func prevFramePressed( _ sender: Any ) {
        prevFrame()
    }
    
    @IBAction func nextFramePressed( _ sender: Any ) {
        nextFrame()
    }
    
    @IBAction func upPressed( _ sender: Any ) {
        moveUp()
    }
    
    @IBAction func downPressed( _ sender: Any ) {
        moveDown()
    }
    
    @IBAction func leftPressed( _ sender: Any ) {
        moveLeft()
    }
    
    @IBAction func rightPressed( _ sender: Any ) {
        moveRight()
    }
    

    @IBAction func didSelectMenu( _ sender: Any ) {
        var items = ViewController.menuItems
        if remoteServer.isConnected {
            items.removeAll() { $0.hasPrefix("Connect")}
        } else {
            items.removeAll() { $0.hasPrefix("Disconnect")}
        }
        
        
        let controller = ArrayChoiceTableViewController(items) { [unowned self] (name) in
            if name == "New file" {
                self.setFrames( frames: [ImageFrame()] )
            } else if name == "Load file" {
                self.loadFile()
            } else if name == "Save file" {
                self.saveFile("image.gif")
            } else if name == "Connect to Ubercorn Frame" {
                self.connectToUbercornFrame()
            } else if name == "Disconnect from Ubercorn Frame" {
                self.disconnectFromUbercornFrame()
            } else if name == "Settings" {
                self.performSegue(withIdentifier: "showSettings", sender: self)
            } else if name == "Paste image" {
                self.handlePasteImage()
            } else if name == "Debug pasteboard" {
                UIPasteboard.general.debug()
            }
        }
        
        self.showPopup(controller, sourceView: sender as! UIBarButtonItem )
    }
}

// MARK: Remote comms
extension ViewController {
    func connectToUbercornFrame() {
        let d = UserDefaults.standard
        let hostName = d.string(forKey: "hostName") ?? ""
        let port = d.integer(forKey: "port")

        if hostName == "" || port <= 0 {
            self.performSegue(withIdentifier: "showSettings", sender: self)
        } else {
            remoteServer.connect(hostName: hostName, port:port, didConnect:{ [unowned self] (connected) in
                if connected {
                    self.connectedLabel.isHidden = false
                    self.sendFrameChange(frame:self.currentFrame)
                } else {
                    self.connectedLabel.isHidden = true
                    self.alert( "Unable to connect to Ubercorn Frame.  Is the player app running?" )
                }
            })
        }
    }
    
    func disconnectFromUbercornFrame() {
        remoteServer.disconnect()
        self.connectedLabel.isHidden = true
    }
    
    func sendPixelChange( x: Int, y: Int, color : UIColor ) {
        if let rgb = color.rgb() {
            let cmd = "SET \(x) \(y) \(rgb[0]) \(rgb[1]) \(rgb[2])"
            remoteServer.sendCommand(cmd)
        }
    }
    
    func sendFrameChange( frame : ImageFrame ) {
        let colors = (frame.pixels.flatMap { $0 })
        let rgbpixels : [[UInt8]] = colors.map { $0.rgb()! }
        let rawpixels = rgbpixels.flatMap { $0 }

        let data = rawpixels.withUnsafeBufferPointer {Data(buffer: $0)}
        remoteServer.sendDataCommand(cmd:"FRAME", data:data)
    }
}

// MARK: Activity Menu
extension ViewController : UIPopoverPresentationControllerDelegate{
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension ViewController {
    private func showPopup(_ controller: UIViewController, sourceView: UIView) {
        let presentationController = AlwaysPresentAsPopover.configurePresentation(forController: controller)
        presentationController.sourceView = sourceView
        presentationController.sourceRect = sourceView.bounds
        presentationController.permittedArrowDirections = [.down, .up]
        self.present(controller, animated: true)
    }

    private func showPopup(_ controller: UIViewController, sourceView: UIBarButtonItem) {
        let presentationController = AlwaysPresentAsPopover.configurePresentation(forController: controller)
        presentationController.barButtonItem = sourceView
        presentationController.permittedArrowDirections = [.down, .up]
        self.present(controller, animated: true)
    }
}

// MARK: Create and init controls
extension ViewController {
    func buildFrame() {
        
        cells = Array(repeating: Array(repeating: UIView(), count: 16), count: 16)

        for y in 0 ..< 16 {
            var row = [UIView]()
            
            for x in 0 ..< 16 {
                let v = UIView()
                v.backgroundColor = .black
                let iv = UIImageView(image: UIImage(named: "mask"))
                iv.translatesAutoresizingMaskIntoConstraints = false
                v.addSubview(iv)
                
                
                let viewsDict = ["iv": iv];
                v.addConstraints( NSLayoutConstraint.constraints(
                    withVisualFormat: "H:|[iv]|", options: [], metrics: nil, views: viewsDict))
                v.addConstraints( NSLayoutConstraint.constraints(
                    withVisualFormat: "V:|[iv]|", options: [], metrics: nil, views: viewsDict))
                
                row.append(v)
                cells[x][y] = v
            }
            
            let sv = UIStackView(arrangedSubviews: row)
            sv.alignment = .fill
            sv.distribution = .fillEqually
            sv.axis = .horizontal
            verticalStackView.addArrangedSubview(sv)
        }
    }
}


// MARK: Frame management functions
extension ViewController {
    
    func doAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(currentFrame.delay)/1000, execute: {
            if self.animating {
                self.nextFrame()
                self.doAnimation()
            }
        })

    }
    
    func frameToView( _ frame: ImageFrame ) {
        for x in 0 ..< 16 {
            for y in 0 ..< 16 {
                if cells.count > 0 {
                    cells[x][y].backgroundColor = frame.pixels[x][y]
                }
            }
        }
        
        sendFrameChange(frame:frame)
    }
    
    func frameFromView( ) -> ImageFrame {
        let frame = ImageFrame()
        for x in 0 ..< 16 {
            for y in 0 ..< 16 {
                frame.pixels[x][y] = cells[x][y].backgroundColor!
            }
        }
        
        return frame
    }
    
    func setFrames( frames : [ImageFrame] ) {
        let f = animation.setFrames( frames )
        self.frameToView(f)
    }
    
    func addFrame() {
        let f = animation.addNewFrameAfterCurrentPosition()
        self.frameToView(f)
    }

    func duplicateFrame() {
        _ = animation.duplicateFrame()
    }
    
    func deleteFrame() {
        let f = animation.deleteFrame()
        
        self.frameToView(f)
    }
    
    func nextFrame() {
        let f = animation.nextFrame()
        self.frameToView(f)
    }

    func prevFrame() {
        let f = animation.prevFrame()
        self.frameToView(f)
    }
}

// MARK: Drawing Functions
extension ViewController {
    func clearView( color: UIColor ) {
        for x in 0 ..< 16 {
            for y in 0 ..< 16 {
                cells[x][y].backgroundColor = color
                currentFrame.pixels[x][y] = color
            }
        }
        sendFrameChange(frame:currentFrame)
    }
    
    func setPixel( x : Int, y : Int, c : UIColor ) {
        cells[x][y].backgroundColor = c
        currentFrame.pixels[x][y] = c
        
        sendPixelChange(x: x, y: y, color: c)
    }
    
    func moveUp() {
        var tmpRow = [UIColor]()
        var p = currentFrame.pixels
        for x in 0 ..< 16 {
            for y in 0 ..< 16 {
                if y == 0 {
                    tmpRow.append(p[x][y])
                } else {
                    currentFrame.pixels[x][y-1] = p[x][y]
                }
                if y == 15 {
                    currentFrame.pixels[x][y] = tmpRow[x]
                }
            }
        }
        self.frameToView(currentFrame)
    }
    
    func moveDown() {
        var tmpRow = [UIColor]()
        var p = currentFrame.pixels
        for x in 0 ..< 16 {
            for y in stride(from:15, to:-1, by:-1) {
                if y == 15 {
                    tmpRow.append(p[x][y])
                } else {
                    currentFrame.pixels[x][y+1] = p[x][y]
                }
                if y == 0 {
                    currentFrame.pixels[x][y] = tmpRow[x]
                }
            }
        }
        self.frameToView(currentFrame)
    }
    
    func moveLeft() {
        var tmpRow = [UIColor]()
        var p = currentFrame.pixels
        for x in 0 ..< 16 {
            for y in 0 ..< 16 {
                if x == 0 {
                    tmpRow.append(p[x][y])
                } else {
                    currentFrame.pixels[x-1][y] = p[x][y]
                }
                if x == 15 {
                    currentFrame.pixels[x][y] = tmpRow[y]
                }
            }
        }
        self.frameToView(currentFrame)

    }

    func moveRight() {
        var tmpRow = [UIColor]()
        var p = currentFrame.pixels
        for x in stride(from:15, to:-1, by:-1) {
            for y in 0 ..< 16 {
                if x == 15 {
                    tmpRow.append(p[x][y])
                } else {
                    currentFrame.pixels[x+1][y] = p[x][y]
                }
                if x == 0 {
                    currentFrame.pixels[x][y] = tmpRow[y]
                }
            }
        }
        self.frameToView(currentFrame)

    }
}


// MARK: File handling
extension ViewController : UIDocumentPickerDelegate {
    
    func saveFile( _ fileName : String ) {
        
        showSubmitTextFieldAlert(title: "Save file", message: "Enter filename", placeholder: "filename") { [unowned self] (name) in
            guard var name = name else { return }
            
            if !name.hasSuffix(".gif") {
                name += ".gif"
            }
            
            let imageData = self.animation.generateGif()
            let url = getDocsFolderURL().appendingPathComponent(name)
            do {
                // write data
                try imageData.write(to: url)
            } catch {
                print( "Error - \(error)" )
            }
        }
    }
    func shareFile() {
        
        let imageData = animation.generateGif()
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "Image.gif" )
        
        do {
            // write data
            try imageData.write(to: url)
            
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError ) in
                
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    print("error deleting file \(error)" )
                }
            }
            
            present(activityViewController, animated: true, completion: nil)
        } catch {
            print( "Error - \(error)" )
        }
    }
    
    func loadFile() {
  
        self.performSegue(withIdentifier: "loadFile", sender: self)

/*
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeImage)], in: .import)
        //Call Delegate
        documentPicker.delegate = self
        self.present(documentPicker, animated: true)
*/
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("import result : /(url)")
        loadFile(fromURL:url)
    }
    
    public func loadFile( fromURL url:URL ) {
        if let frames = UIImage.gifImage(withURL:url) {
            setFrames( frames: frames)
        }

    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
    
    func handlePasteImage() {
        let pb = UIPasteboard.general
        var url : URL?
        var imageData : Data?
        var type : String?
        
        // see if we have a type of file
        if let value = pb.value(forPasteboardType: "com.apple.pasteboard.promised-file-content-type" ) {
            type = String(data:value as! Data, encoding:.utf8)!
        }
        if let value = pb.value(forPasteboardType: "public.url" ) as? String,
            let fileURL = URL(string:value) {
            url = fileURL
        } else if let value = pb.value(forPasteboardType: "public.file-url" ) as? String,
            let fileURL = URL(string:value) {
            url = fileURL
        } else if let value = pb.value(forPasteboardType: "public.text" ) as? String,
            let fileURL = URL(string:value) {
            url = fileURL
        } else if let value = pb.data(forPasteboardType: "com.apple.icns" ) {
            imageData = value
        } else if let data = pb.data(forPasteboardType: "public.image") {
            imageData = data
        }

/*
        for item in pb.items {
            for (key,value) in item {
                print( "Item name - \(key)")
                if key == "public.url" {
                    url = URL(string:value as! String)
                } else if key == "public.file-url" {
                    url = URL(string:value as! String)
                } else if key == "com.apple.pasteboard.promised-file-content-type" {
                    type = String(data:value as! Data, encoding:.utf8)!
                } else if let image = pb.image {
                    imageData = image
                }
//                print( "Item value - \(value)")
            }
        }
*/
        
        if let url = url {
            if let frames = UIImage.gifImage(withURL:url) {
                self.setFrames( frames: frames)
            }
            
        } else if let imageData = pb.data(forPasteboardType: "public.image") {
            let image = pb.image
            if let frames = UIImage.gifImage(withData:imageData) {
                self.setFrames( frames: frames)
            }
        }

    }
}


extension ViewController {
    func showSubmitTextFieldAlert(title: String,
                                  message: String,
                                  placeholder: String,
                                  completion: @escaping (_ userInput: String?) -> Void) {
        
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = placeholder
            textField.clearButtonMode = .whileEditing
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (action) in
            let userInput = alertController.textFields?.first?.text
            completion(userInput)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(nil)
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }

}
