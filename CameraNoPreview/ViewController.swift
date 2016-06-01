//
//  ViewController.swift
//  CameraNoPreview
//
//  Created by Dan Sinclair on 01/06/2016.
//  Copyright © 2016 Dan Sinclair. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var videoCaptureOutput = AVCaptureMovieFileOutput()
    
    var captureDevice : AVCaptureDevice?
    
    var isRecording: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            print(device)
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if captureDevice != nil {
            beginSession()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func beginSession() {
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            
            captureSession.addOutput(videoCaptureOutput)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.view.layer.addSublayer(previewLayer!)
            previewLayer?.frame = self.view.layer.frame
            previewLayer?.hidden = true
            captureSession.startRunning()
        } catch {
            print("error: \(error)")
        }
    }
    
    func configureDevice() {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                device.focusMode = .Locked
                device.unlockForConfiguration()
            } catch {
                print("error configuring device: \(error)")
            }
            
        }
    }
    
    func updateDeviceSettings(focusValue : Float, isoValue : Float) {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                device.setFocusModeLockedWithLensPosition(focusValue, completionHandler: nil)
                
                let minISO = device.activeFormat.minISO
                let maxISO = device.activeFormat.maxISO
                let clampedISO = isoValue * (maxISO - minISO) + minISO
                
                device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: clampedISO, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                print("cannot lock for configuration: \(error)")
            }

        }
    }
    
    func touchPercent(touch : UITouch) -> CGPoint {
        // Get the dimensions of the screen in points
        let screenSize = UIScreen.mainScreen().bounds.size
        
        // Create an empty CGPoint object set to 0, 0
        var touchPer = CGPointZero
        
        // Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
        touchPer.x = touch.locationInView(self.view).x / screenSize.width
        touchPer.y = touch.locationInView(self.view).y / screenSize.height
        
        // Return the populated CGPoint
        return touchPer
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchPer = touchPercent(touches.first!)
        updateDeviceSettings(Float(touchPer.x), isoValue: Float(touchPer.y))
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touchPer = touchPercent(touches.first!)
        updateDeviceSettings(Float(touchPer.x), isoValue: Float(touchPer.y))
    }

    @IBAction func previewPressed(sender: AnyObject) {
        
        previewLayer?.hidden = !(previewLayer?.hidden)!
        
        let title = previewLayer?.hidden == true ? "Show Preview" : "Hide Preview"
        previewButton.setTitle(title, forState: .Normal)
        
    }
    
    @IBAction func recordPressed(sender: AnyObject) {
        
        if isRecording {
            videoCaptureOutput.stopRecording()
        } else {
            let fileManager = NSFileManager.defaultManager()
            let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            let documentsDirectory = urls.first
            
            let outputPath = documentsDirectory?.URLByAppendingPathComponent("\(NSProcessInfo.processInfo().globallyUniqueString).mov")
            
            videoCaptureOutput.startRecordingToOutputFileURL(outputPath, recordingDelegate: self)
        }
        
        isRecording = !isRecording

    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        recordButton.setTitle("Stop Recording", forState: .Normal)
        print("started capture to \(fileURL!)")
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if error != nil {
            print("Error: \(error)")
        }
        print("finished capture to \(outputFileURL!)")
        
        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path!, nil, nil, nil)

        recordButton.setTitle("Start Recording", forState: .Normal)
    }
}

