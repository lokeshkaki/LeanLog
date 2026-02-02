//
//  BarcodeScannerViewController.swift
//  LeanLog
//

import UIKit
import AVFoundation
import AudioToolbox

final class BarcodeScannerViewController: UIViewController {

    // Callbacks
    var onCodeScanned: ((String) -> Void)?
    var onManualTap: (() -> Void)?
    var onCloseTap: (() -> Void)?

    // AVFoundation
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.leanlog.camera.session") // serial queue
    private let metadataOutput = AVCaptureMetadataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var device: AVCaptureDevice?
    private var isConfigured = false

    // Debug: set true to validate pipeline; switch to false to use windowed ROI
    private var useFullFrameROIForDebug = true

    // UI
    private let dimView = UIView()
    private let scanWindow = UIView()
    private let closeButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let torchButton = UIButton(type: .system)
    private let manualButton = UIButton(type: .system)

    private var torchOn = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        requestPermissionAndConfigure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        setVideoOrientationIfNeeded()
        layoutUI()
        updateROI()
    }

    // MARK: - Permission + Config

    private func requestPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    if granted { self.configureSession() } else { self.onCloseTap?() }
                }
            }
        default:
            onCloseTap?()
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.session.commitConfiguration()
                return
            }
            self.device = camera

            do {
                try camera.lockForConfiguration()
                if camera.isFocusModeSupported(.continuousAutoFocus) { camera.focusMode = .continuousAutoFocus }
                if camera.isExposureModeSupported(.continuousAutoExposure) { camera.exposureMode = .continuousAutoExposure }
                camera.isSubjectAreaChangeMonitoringEnabled = true
                camera.unlockForConfiguration()
            } catch {}

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) { self.session.addInput(input) }
                else { self.session.commitConfiguration(); return }
            } catch {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
                self.metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                let wanted: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .upce, .code128, .code39, .qr]
                self.metadataOutput.metadataObjectTypes = wanted.filter {
                    self.metadataOutput.availableMetadataObjectTypes.contains($0)
                }
            } else {
                self.session.commitConfiguration()
                return
            }

            self.session.commitConfiguration()
            self.isConfigured = true

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let layer = AVCaptureVideoPreviewLayer(session: self.session)
                layer.videoGravity = .resizeAspectFill
                layer.frame = self.view.bounds
                self.view.layer.insertSublayer(layer, at: 0)
                self.previewLayer = layer
                self.setVideoOrientationIfNeeded()
                self.updateROI()
                self.logDiagnostics()
            }
        }
    }

    // MARK: - Orientation + ROI

    private func setVideoOrientationIfNeeded() {
        guard let conn = previewLayer?.connection, conn.isVideoOrientationSupported else { return }
        conn.videoOrientation = .portrait
    }

    private func updateROI() {
        guard let layer = previewLayer else { return }

        if useFullFrameROIForDebug {
            metadataOutput.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
            return
        }

        let width = view.bounds.width * 0.75
        let height: CGFloat = 200
        let x = (view.bounds.width - width) / 2
        let y = (view.bounds.height - height) / 2
        let rect = CGRect(x: x, y: y, width: width, height: height)
        metadataOutput.rectOfInterest = layer.metadataOutputRectConverted(fromLayerRect: rect)
    }

    private func logDiagnostics() {
        print("Available metadata types:", metadataOutput.availableMetadataObjectTypes)
        print("Session running:", session.isRunning)
        if let layer = previewLayer {
            print("Preview frame:", layer.frame, "ROI:", metadataOutput.rectOfInterest)
        }
    }

    // MARK: - UI

    private func setupUI() {
        // Dim overlay with cutout frame drawn in layoutUI
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addSubview(dimView)

        scanWindow.layer.borderColor = UIColor.white.cgColor
        scanWindow.layer.borderWidth = 3
        scanWindow.layer.cornerRadius = 16
        view.addSubview(scanWindow)

        // Top-left close
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 22
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Bottom status
        statusLabel.text = "Point camera at barcode"
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.textAlignment = .center
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        statusLabel.layer.cornerRadius = 20
        statusLabel.clipsToBounds = true
        view.addSubview(statusLabel)

        // Bottom controls: torch and manual
        torchButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        torchButton.tintColor = .white
        torchButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        torchButton.layer.cornerRadius = 24
        torchButton.addTarget(self, action: #selector(torchTapped), for: .touchUpInside)
        view.addSubview(torchButton)

        manualButton.setTitle("Manual", for: .normal)
        manualButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        manualButton.tintColor = .white
        manualButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        manualButton.layer.cornerRadius = 24
        manualButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        manualButton.addTarget(self, action: #selector(manualTapped), for: .touchUpInside)
        view.addSubview(manualButton)
    }

    private func layoutUI() {
        dimView.frame = view.bounds

        let width = view.bounds.width * 0.75
        let height: CGFloat = 200
        let x = (view.bounds.width - width) / 2
        let y = (view.bounds.height - height) / 2
        scanWindow.frame = CGRect(x: x, y: y, width: width, height: height)

        // Dim mask cutout
        let path = UIBezierPath(rect: view.bounds)
        path.append(UIBezierPath(roundedRect: scanWindow.frame, cornerRadius: 16).reversing())
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        dimView.layer.mask = mask

        // Top close
        closeButton.frame = CGRect(x: 20, y: view.safeAreaInsets.top + 8, width: 44, height: 44)

        // Bottom status + controls
        let statusWidth = view.bounds.width - 80
        statusLabel.frame = CGRect(x: 40, y: scanWindow.frame.maxY + 20, width: statusWidth, height: 44)

        let bottomY = view.bounds.height - view.safeAreaInsets.bottom - 76
        let torchSize: CGFloat = 56
        torchButton.frame = CGRect(x: 40, y: bottomY, width: torchSize, height: torchSize)
        let manualW: CGFloat = 120
        manualButton.frame = CGRect(x: view.bounds.width - manualW - 40, y: bottomY, width: manualW, height: 56)
    }

    // MARK: - Actions

    @objc private func closeTapped() { onCloseTap?() }
    @objc private func manualTapped() { onManualTap?() }

    @objc private func torchTapped() {
        torchOn.toggle()
        guard let device, device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = torchOn ? .on : .off
        device.unlockForConfiguration()
        torchButton.setImage(UIImage(systemName: torchOn ? "bolt.fill" : "bolt.slash.fill"), for: .normal)
    }
}

// MARK: - Delegate

extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = obj.stringValue else { return }
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        sessionQueue.async { [weak self] in self?.session.stopRunning() }
        onCodeScanned?(code)
    }
}
