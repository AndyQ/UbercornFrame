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
    static let menuItems = ["New file", "Load file", "Save file", "Paste image", "Create palette from image", "Disconnect from Ubercorn Frame", "Connect to Ubercorn Frame", "Settings"]

    @IBOutlet weak var verticalStackView: UIStackView!
    @IBOutlet weak var paletteScrollView: UIScrollView!
    @IBOutlet weak var paletteView: PaletteView!
    @IBOutlet weak var sendToUbercornButton: UIButton!

    @IBOutlet weak var frameLabel: UILabel!
    @IBOutlet weak var frameDelayLabel: UILabel!
    @IBOutlet weak var connectedLabel: UILabel!

    var cells = [[UIView]]()
    var lastTouchedX : Int = -1
    var lastTouchedY : Int = -1

    var currentColor : UIColor!
    var pickingColor : Bool = false
    
    var remoteServer : RemoteServer = RemoteServer()
    
    let animation = Animation()
    
    var animating = false
    
    var currentFrame : ImageFrame {
        return animation.currentFrame
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildFrame()
        
        animation.frameChanged = { [unowned self] (frameNr) in
            self.frameLabel.text = "\(frameNr+1) / \(self.animation.numberOfFrames)"
            self.frameDelayLabel.text = "\(self.currentFrame.delay)ms"
        }
        
        
        paletteView.colorChanged = { [unowned self] (color) in
            self.currentColor = color
        }

        paletteView.changePalette = { [unowned self] in
            let items = PaletteManager.instance.getAllPaletteNames()
            let controller = ArrayChoiceTableViewController(items, scroll:true) { [unowned self] (name) in
                if let p = PaletteManager.instance.getPalette(name) {
                    self.paletteView.setPalette(palette: p)
                }
            }
            self.showPopup(controller, sourceView: self.paletteView, rect:self.paletteView.bounds )
        }

        paletteView.showPage = { [unowned self] (page) in
            // Force scrollview to show button if necessary
            var rect = self.paletteScrollView.bounds
            rect.origin.x = rect.size.width * CGFloat(page)
            rect.origin.y = 0
            self.paletteScrollView.scrollRectToVisible(rect, animated: true)
        }
        
        paletteView.chooseColor = { [unowned self] (source, rect) in
            let colorPickerVC = ColorPickerViewController()
            colorPickerVC.delegate = self.paletteView
            colorPickerVC.modalPresentationStyle = .popover
            self.showPopup(colorPickerVC, sourceView: source, rect:rect )
        }
        
        paletteView.pickColor = { [unowned self] () in
            self.pickingColor = true
        }

        paletteView.setPalette(palette: PaletteManager.instance.initialPalette )
        
        self.frameDelayLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.changeFrameDelayPressed(_:))))
        
        self.animation.frameChanged?(self.animation.frameIndex)
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
            if pickingColor {
                pickingColor = false
                let color = getPixelColor( x:x, y:y )
                paletteView.colorSelectionChanged( selectedColor:color )
                
            }else {
                setPixel( x:x, y:y, c:currentColor)
            }
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchedX = -1
        lastTouchedY = -1

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
        
        self.showPopup(controller, sourceView: gr.view!, rect:gr.view!.bounds )
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
    
    @IBAction func saveToUbercornPressed( _ sender: Any ) {
        saveFile(saveLocally: false)
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
                self.saveFile()
            } else if name == "Connect to Ubercorn Frame" {
                self.connectToUbercornFrame()
            } else if name == "Disconnect from Ubercorn Frame" {
                self.disconnectFromUbercornFrame()
            } else if name == "Settings" {
                self.performSegue(withIdentifier: "showSettings", sender: self)
            } else if name == "Paste image" {
                self.handlePasteImage()
            } else if name == "Create palette from image" {
                self.createPaletteFromImage()
            }
        }
        
        self.showPopup(controller, sourceView: sender as! UIBarButtonItem )
    }
    
    func createPaletteFromImage() {
        if let p = PaletteManager.instance.createPalette(fromImageFrames: self.animation.frames) {
            self.paletteView.setPalette(palette: p)
        }
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
                    self.sendToUbercornButton.isHidden = false
                    self.sendFrameChange(frame:self.currentFrame)
                } else {
                    self.connectedLabel.isHidden = true
                    self.sendToUbercornButton.isHidden = true
                    self.alert( "Unable to connect to Ubercorn Frame.  Is the player app running?" )
                }
            })
        }
    }
    
    func disconnectFromUbercornFrame() {
        remoteServer.disconnect()
        self.connectedLabel.isHidden = true
        self.sendToUbercornButton.isHidden = true
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
    private func showPopup(_ controller: UIViewController, sourceView: UIView, rect: CGRect) {
        let presentationController = AlwaysPresentAsPopover.configurePresentation(forController: controller)
        presentationController.sourceView = sourceView
        presentationController.sourceRect = rect
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
    
    func getPixelColor( x : Int, y : Int ) -> UIColor {
        let c = currentFrame.pixels[x][y]
        return c
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
    
    func saveFile( saveLocally: Bool = true ) {
        
        showSubmitTextFieldAlert(title: "Save file", message: "Enter filename", placeholder: "filename") { [unowned self] (name) in
            guard var name = name else { return }
            
            if !name.hasSuffix(".gif") {
                name += ".gif"
            }
            
            let imageData = self.animation.generateGif()
            
            if saveLocally {
                let url = getDocsFolderURL().appendingPathComponent(name)
                do {
                    // write data
                    try imageData.write(to: url)
                } catch {
                    print( "Error - \(error)" )
                }
            } else {
                if self.remoteServer.isConnected {
                    self.remoteServer.sendDataCommand(cmd:"SAVE:\(name)", data:imageData)
                }

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
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("import result : /(url)")
        loadFile(fromURL:url)
    }
    
    public func loadFile( fromURL url:URL ) {
        if url.pathExtension == "zip" {
            handleZipURL( url )
        } else {
            if let frames = UIImage.gifImage(withURL:url) {
                setFrames( frames: frames)
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
    
    func handlePasteImage() {
        let pb = UIPasteboard.general
        var url : URL?
        
        if let value = pb.value(forPasteboardType: "public.url" ) as? String,
            let fileURL = URL(string:value) {
            url = fileURL
        } else if let value = pb.value(forPasteboardType: "public.file-url" ) as? String,
            let fileURL = URL(string:value) {
            url = fileURL
        } else if let value = pb.value(forPasteboardType: "public.text" ) as? String,
            let fileURL = URL(string:value) {
            url = fileURL
        }

        if let url = url {
            if url.pathExtension == "zip" {
                handleZipURL( url )
            }
            else if let frames = UIImage.gifImage(withURL:url) {
                self.setFrames( frames: frames)
            }
        } else if let imageData = pb.data(forPasteboardType: "public.image") {
            if let frames = UIImage.gifImage(withData:imageData) {
                self.setFrames( frames: frames)
            }
        }
    }
    
    func handleZipURL( _ url: URL ) {
        print( "Extracting \(url)" )
        let zf = GameFrameArchiveHandler(zipFileURL: url)
        
        if zf.foundImages.count == 1, let key = zf.foundImages.keys.first, let frames = zf.foundImages.values.first {
            setFrames( frames:frames)

            let animation = Animation(frames:frames)
            let imageData = animation.generateGif()
            let url = getDocsFolderURL().appendingPathComponent(key).appendingPathExtension("gif")
            do {
                try imageData.write(to: url)
            } catch {
            }

        } else {
            // Save all images
            var message = "Following images found have been saved to documents:"
            var failed = ""
            for (key, frames) in zf.foundImages {
                let animation = Animation(frames:frames)
                let imageData = animation.generateGif()
                
                let url = getDocsFolderURL().appendingPathComponent(key).appendingPathExtension("gif")
                do {
                    try imageData.write(to: url)
                    
                    message += "\n   \(key)"
                } catch {
                    failed += "\n   \(key)"
                }
            }
            
            if failed != "" {
                message += "\n\nThe following files couldn't be saved:" + failed
            }
            
            alert( message, title:"Saved files" )
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
