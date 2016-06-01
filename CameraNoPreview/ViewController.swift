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
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
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
            self.view.layer.insertSublayer(previewLayer!, below: previewButton.layer)
            previewLayer?.frame = self.view.layer.frame
            previewLayer?.hidden = true
            captureSession.startRunning()
        } catch {
            print("error: \(error)")
        }
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

