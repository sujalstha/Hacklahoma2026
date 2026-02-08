import SwiftUI
import AVFoundation
import UIKit
import AudioToolbox


struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedCode: String?
    
    @State private var isAuthorized = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            if isAuthorized {
                ScannerViewController(scannedCode: $scannedCode, dismiss: dismiss)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding()
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Text("Scan Barcode")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.white)
                        
                        Text("Position the barcode within the frame")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("Camera Access Required")
                        .font(.title2)
                        .bold()
                    
                    Text("Please enable camera access in Settings to scan barcodes")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .onAppear {
            checkCameraAuthorization()
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    isAuthorized = granted
                }
            }
        default:
            isAuthorized = false
        }
    }
}

// MARK: - Scanner View Controller

struct ScannerViewController: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    let dismiss: DismissAction
    
    func makeUIViewController(context: Context) -> ScannerUIViewController {
        let controller = ScannerUIViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerUIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, ScannerDelegate {
        @Binding var scannedCode: String?
        let dismiss: DismissAction
        
        init(scannedCode: Binding<String?>, dismiss: DismissAction) {
            self._scannedCode = scannedCode
            self.dismiss = dismiss
        }
        
        func didFindCode(_ code: String) {
            scannedCode = code
            dismiss()
        }
        
        func didSurfaceError(_ error: Error) {
            print("Scanner error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Scanner Delegate

protocol ScannerDelegate: AnyObject {
    func didFindCode(_ code: String)
    func didSurfaceError(_ error: Error)
}

// MARK: - Scanner UI View Controller

class ScannerUIViewController: UIViewController {
    weak var delegate: ScannerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScanner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    private func setupScanner() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didSurfaceError(ScannerError.noCameraAvailable)
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didSurfaceError(error)
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.didSurfaceError(ScannerError.invalidInput)
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .pdf417, .qr, .upce, .code128, .code39, .code93
            ]
        } else {
            delegate?.didSurfaceError(ScannerError.invalidOutput)
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}

// MARK: - Metadata Output Delegate

extension ScannerUIViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFindCode(stringValue)
        }
    }
}

// MARK: - Scanner Errors

enum ScannerError: Error {
    case noCameraAvailable
    case invalidInput
    case invalidOutput
    
    var localizedDescription: String {
        switch self {
        case .noCameraAvailable:
            return "No camera available on this device"
        case .invalidInput:
            return "Could not add video input"
        case .invalidOutput:
            return "Could not add metadata output"
        }
    }
}
