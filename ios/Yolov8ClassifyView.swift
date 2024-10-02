import ExpoModulesCore
import Vision
import WebKit
import UIKit
import AVFoundation

enum Yolov8ClassifyViewError: Error {
    case mlModelNotFound
    case mlModelLoadingFailed(Error)
    case videoDeviceInputCreationFailed
    case cannotAddVideoInput
    case cannotAddVideoOutput
    case failedToLockVideoDevice(Error)
    case pixelBufferUnavailable
    case requestProcessingFailed(Error)
}

class Yolov8ClassifyView: ExpoView, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let previewView = UIView()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let onResult = EventDispatcher()
    private let session = AVCaptureSession()
    private var bufferSize: CGSize = .zero
    private var requests = [VNRequest]()

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        do {
            try setupCapture()
            try setupOutput()
            try setupVision()
            setupPreviewLayer()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        } catch {
            print("Error setting up capture session: \(error)")
        }
    }

    private func setupCapture() throws {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw Yolov8ClassifyViewError.videoDeviceInputCreationFailed
        }

        session.beginConfiguration()

        guard session.canAddInput(deviceInput) else {
            throw Yolov8ClassifyViewError.cannotAddVideoInput
        }

        session.addInput(deviceInput)
        setupBufferSize(for: videoDevice)
        session.commitConfiguration()
    }

    private func setupOutput() throws {
        let videoDataOutput = AVCaptureVideoDataOutput()
        let videoDataOutputQueue = DispatchQueue(
            label: "VideoDataOutput",
            qos: .userInitiated,
            attributes: [],
            autoreleaseFrequency: .workItem
        )

        guard session.canAddOutput(videoDataOutput) else {
            throw Yolov8ClassifyViewError.cannotAddVideoOutput
        }

        session.addOutput(videoDataOutput)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
            Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    }

    private func setupVision() throws {
        guard let modelURL = Bundle.main.url(
            forResource: "yolov8x-cls",
            withExtension: "mlmodelc"
        ) else {
            throw Yolov8ClassifyViewError.mlModelNotFound
        }

        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let classificationRequest = VNCoreMLRequest(
                model: visionModel,
                completionHandler: handleClassification
            )
            self.requests = [classificationRequest]
        } catch {
            throw Yolov8ClassifyViewError.mlModelLoadingFailed(error)
        }
    }

    private func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer
        previewView.layer.addSublayer(layer)
        addSubview(previewView)
    }

    private func setupBufferSize(for videoDevice: AVCaptureDevice) {
        do {
            try videoDevice.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions(
                videoDevice.activeFormat.formatDescription
            )
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice.unlockForConfiguration()
        } catch {
            print("Failed to lock video device for configuration: \(error)")
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewView.frame = bounds
        previewLayer?.frame = previewView.bounds
    }

    private func handleClassification(request: VNRequest, error: Error?) {
        if let results = request.results as? [VNClassificationObservation],
           let topResult = results.max(by: { $0.confidence < $1.confidence }) {
            DispatchQueue.main.async { [weak self] in
                self?.onResult(["classification": topResult.identifier])
            }
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Could not get image buffer from sample buffer.")
            return
        }

        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
            options: [:]
        )
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print("Failed to perform image request: \(error)")
        }
    }
}