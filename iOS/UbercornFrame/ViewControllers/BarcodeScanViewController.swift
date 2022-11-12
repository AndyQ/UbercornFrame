//
//  BarCodeScannableUIViewController.swift
//  Scanner
//
//  Created by Andy Qua on 16/01/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit
import AVFoundation

class BarcodeScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // AV Capture (Barcode scanning)
    var session: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView:UIView?
    var lastBarcode = ""

    // Need to provide these!
    var scannedBarcode : ((String)->())?
    
    override func viewWillAppear(_ animated: Bool) {
        self.scanBarcode()
    }

    func scanBarcode() {
        
        if session == nil {
            if setupCaptureDevice() {
                // Start capturing
                startScanning()
            }
        } else {
            stopScanning()
        }
    }
    
    func setupCaptureDevice() -> Bool {
        // Create input object.
        guard let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video),
            let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                return false
        }
        
        // Create a session object.
        session = AVCaptureSession()
        
        // Add input to the session.
        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        } else {
            scanningNotPossible()
        }
        
        // Create output object.
        let metadataOutput = AVCaptureMetadataOutput()
        
        // Add output to the session.
        if (session.canAddOutput(metadataOutput)) {
            session.addOutput(metadataOutput)
            
            // Send captured data to the delegate object via a serial queue.
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Set barcode type for which to scan: QR
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            scanningNotPossible()
            return false
        }
        
        // Add previewLayer and have it show the video data.
        previewLayer = AVCaptureVideoPreviewLayer(session: session);
        previewLayer.frame = self.view.layer.bounds;
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        self.view.layer.addSublayer(previewLayer)
        
        let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: self.view.layer.bounds)
        metadataOutput.rectOfInterest = rectOfInterest
        
        let w :CGFloat  = self.view.bounds.width - 40
        let h :CGFloat = self.view.bounds.height
        let x :CGFloat  = 10
        let y :CGFloat = (h/2) - 2
        
        
        // Add scanning line
        
        qrCodeFrameView = UIView(frame:CGRect(x:x, y:y, width:w-20, height:2))
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            qrCodeFrameView.isHidden = true
            self.view.addSubview(qrCodeFrameView)
            self.view.bringSubviewToFront(qrCodeFrameView)
        }
        
        return true
    }
    
    func startScanning() {
        
        UIApplication.shared.isIdleTimerDisabled = true
        lastBarcode = ""
        if session != nil {
            DispatchQueue.global(qos:.default).async {
                self.session.startRunning()
            }

        }
    }
    
    func pauseScanning() {
        UIApplication.shared.isIdleTimerDisabled = false
        if session != nil {
            session.stopRunning()
        }
    }
    
    func stopScanning() {
        UIApplication.shared.isIdleTimerDisabled = false
        if session != nil {
            session.stopRunning()
            session = nil
            previewLayer.removeFromSuperlayer()
            qrCodeFrameView?.removeFromSuperview()
        }
    }
    
    func scanningNotPossible() {
        // Let the user know that scanning isn't possible with the current device.
        let alert = UIAlertController(title: "Can't Scan.", message: "Let's try a device equipped with a camera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        session = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  self.previewLayer?.connection  {
            let previewLayerConnection : AVCaptureConnection = connection
            let metadataOutput : AVCaptureMetadataOutput = self.previewLayer?.session?.outputs[0] as! AVCaptureMetadataOutput
            
            // Force Portrait mode only
            if previewLayerConnection.isVideoOrientationSupported {
                updatePreviewLayer(layer: previewLayerConnection, metadataOutput: metadataOutput, orientation: .portrait)
            }
        }
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, metadataOutput : AVCaptureMetadataOutput, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        
        previewLayer.frame = self.view.layer.bounds;
        
        let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: self.view.layer.bounds)
        metadataOutput.rectOfInterest = rectOfInterest
        
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if metadataObjects.count == 0 {
            let w :CGFloat  = self.view.bounds.width - 40
            let h :CGFloat = self.view.bounds.height
            let x :CGFloat  = 10
            let y :CGFloat = (h/2) - 2

            qrCodeFrameView?.isHidden = true
            qrCodeFrameView?.frame = CGRect(x:x, y:y, width:w-20, height:2)

            //messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the first object from the metadataObjects array.
        for barcodeData in metadataObjects {
            // Turn it into machine readable code
            let barcodeReadable = barcodeData as? AVMetadataMachineReadableCodeObject;
            if let readableCode = barcodeReadable {
                
                let barCodeObject = previewLayer?.transformedMetadataObject(for: barcodeData)
                qrCodeFrameView?.isHidden = false
                qrCodeFrameView?.frame = barCodeObject!.bounds
                
                if let barcode = readableCode.stringValue {
                    if barcode != lastBarcode {
                        lastBarcode = barcode
                        // Mark bag as loaded
                        DispatchQueue.main.async(execute: { [unowned self] in
                            self.scannedBarcode?( barcode )
                        })
                    }
                }
            }
        }
    }
}
