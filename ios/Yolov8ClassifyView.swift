import ExpoModulesCore
import Vision
import WebKit
import UIKit
import AVFoundation

class Yolov8ClassifyView: ExpoView, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var previewView = UIView()
    private let onResult = EventDispatcher()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let session = AVCaptureSession()
    private var bufferSize: CGSize = .zero
    private var requests = [VNRequest]()

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        setupCapture()
        setupOutput()
        setupVision()
        setupPreviewLayer()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer!)
        addSubview(previewView)
    }

    private func setupVision() {
        guard let modelURL = Bundle.main.url(forResource: "yolov8x-cls", withExtension: "mlmodelc") else {
            fatalError("Failed to find ML model.")
        }

        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let classification = VNCoreMLRequest(model: visionModel, completionHandler: handleClassification)
            self.requests = [classification]
        } catch {
            fatalError("Model loading went wrong: \(error)")
        }
    }

    private func handleClassification(request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.sorted(by: { $0.confidence > $1.confidence }).first {
                self?.onResult(["classification": topResult.identifier])
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewView.frame = bounds
        previewLayer?.frame = previewView.bounds
    }

    private func setupCapture() {
        guard let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first,
              let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            fatalError("Could not create video device input.")
        }

        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        guard session.canAddInput(deviceInput) else {
            fatalError("Could not add video device input to the session.")
        }

        session.addInput(deviceInput)
        setupBufferSize(for: videoDevice)
        session.commitConfiguration()
    }

    private func setupBufferSize(for videoDevice: AVCaptureDevice) {
        do {
            try videoDevice.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions(videoDevice.activeFormat.formatDescription)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice.unlockForConfiguration()
        } catch {
            fatalError("\(error)")
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            fatalError("Could not get image buffer from sample buffer.")
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            fatalError("\(error)")
        }
    }

    private func setupOutput() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

        guard session.canAddOutput(videoDataOutput) else {
            fatalError("Could not add video data output to the session.")
        }

        session.addOutput(videoDataOutput)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    }
}