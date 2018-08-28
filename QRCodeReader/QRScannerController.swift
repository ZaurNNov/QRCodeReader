//
//  QRScannerController.swift
//  QRCodeReader


import UIKit
import AVFoundation

@available(iOS 11.1, *)
class QRScannerController: UIViewController {

    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr,
                                      AVMetadataObject.ObjectType.face]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the back-facing camera for capturing videos
        
        // for iPhone 6S:
        // but not work: .builtInDuoCamera / .builtInTelephotoCamera / .builtInDualCamera / .builtInTrueDepthCamera
        // work:  .builtInWideAngleCamera
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        let devicesCount = deviceDiscoverySession.devices.count
        if (devicesCount > 0) {
            let devices = deviceDiscoverySession.devices
            for device in devices {
                print(device.debugDescription)
            }
        }
        
        let captureDevice = deviceDiscoverySession.devices.first
        
        if (captureDevice == nil) {
            print("** 1 ** Failed to get device")
            print(deviceDiscoverySession.debugDescription)
            return
        }
        
        print("check point")
        
        do {
            // get instance AVDeviceInput class using the previous device obj
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            // set the input device on the capture session
            captureSession.addInput(input)
            
            // init AVMetadataOutput obj and set it as the output device to the capture session
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self as AVCaptureMetadataOutputObjectsDelegate, queue: DispatchQueue.main)
//            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr] // only QR
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes // all known types
            
            // init QR Code Frame (buckground layer and cgrecrzero bounds)
            qrCodeFrameView = UIView()
            qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView?.layer.borderWidth = 5
            view.addSubview(qrCodeFrameView!)
            
        } catch {
            // if any error - print it
            print(error.localizedDescription)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // start capture session
        captureSession.startRunning()
        
        view.bringSubview(toFront: messageLabel)
        view.bringSubview(toFront: topbar)
        
    }

    // MARK: - Helper Method
    func launchApp(decodeURL: String){
        
        if presentedViewController != nil {
            return
        }
        
        if let url = URL(string: decodeURL) {
            
            if UIApplication.shared.canOpenURL(url) {
                
                let alertPromt = UIAlertController(title: "Open App", message: "You're going to open \(decodeURL)", preferredStyle: .actionSheet)
                let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
                    
                    UIApplication.shared.open(url, options: [ : ], completionHandler: nil)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertPromt.addAction(confirmAction)
                alertPromt.addAction(cancelAction)
                present(alertPromt, animated: true, completion: nil)
            }
        }
    }
}

@available(iOS 11.1, *)
extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObject array is not nil and it containts at least one obj
        
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // get the metadata obj
        let metadataObj = metadataObjects.first as! AVMetadataMachineReadableCodeObject
        
        // catch code!
        if metadataObj.stringValue != nil {
            messageLabel.text = metadataObj.stringValue
        }
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // we known obj
            // create frame (and pul to front)
            if let barCodeObj = videoPreviewLayer?.transformedMetadataObject(for: metadataObj) {
                qrCodeFrameView?.frame = barCodeObj.bounds
                view.bringSubview(toFront: qrCodeFrameView!)
            }
            
            if let openAppString = metadataObj.stringValue {
                launchApp(decodeURL: openAppString)
            }
        }
    }
}
