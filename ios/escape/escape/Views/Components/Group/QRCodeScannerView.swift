//
//  QRCodeScannerView.swift
//  escape
//
//  Created by Copilot on 2025/11/07.
//

import AVFoundation
import SwiftUI

struct QRCodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedCode: String
    @State private var isScanning = true
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                QRScannerViewController(
                    scannedCode: $scannedCode,
                    isScanning: $isScanning,
                    onCodeScanned: { code in
                        scannedCode = code
                        dismiss()
                    }
                )
                .ignoresSafeArea()

                // Overlay UI
                VStack {
                    Spacer()

                    // Scanning frame overlay
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("brandOrange"), lineWidth: 3)
                        .frame(width: 250, height: 250)

                    Text(
                        "group.join.qr_instruction", bundle: .main, comment: "Position QR code within the frame"
                    )
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .padding(.top, 20)

                    Spacer()
                }
            }
            .navigationTitle(
                String(localized: "group.join.scan_qr", bundle: .main, comment: "Scan QR Code")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "setting.cancel", bundle: .main)) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - QR Scanner View Controller

struct QRScannerViewController: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanning: Bool
    var onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerController, context _: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        @Binding var scannedCode: String
        var onCodeScanned: (String) -> Void
        private var hasScanned = false

        init(scannedCode: Binding<String>, onCodeScanned: @escaping (String) -> Void) {
            _scannedCode = scannedCode
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(
            _: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject],
            from _: AVCaptureConnection
        ) {
            guard !hasScanned,
                  let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue
            else {
                return
            }

            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            DispatchQueue.main.async {
                self.onCodeScanned(stringValue)
            }
        }
    }
}

class QRScannerController: UIViewController {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession?.canAddInput(videoInput) ?? false {
            captureSession?.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession?.canAddOutput(metadataOutput) ?? false {
            captureSession?.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
    }

    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
}
