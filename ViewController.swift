import UIKit
import AVFoundation
import CoreLocation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
    
    // MARK: - Properties
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    private var address: String = "Cargando dirección..."
    private var previewTimer: Timer?
    private let geocoder = CLGeocoder()
    
    // Session Management
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var videoDeviceInput: AVCaptureDeviceInput!
    
    // UI State
    private var isGridVisible = false
    private var flashMode: AVCaptureDevice.FlashMode = .auto
    private var currentZoomFactor: CGFloat = 1.0
    
    // MARK: - UI Components
    private let topBlurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThinMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin)
        button.setImage(UIImage(systemName: "circle.inset.filled", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black
        imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        imageView.layer.borderWidth = 1.5
        return imageView
    }()
    
    private let infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "info.circle.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let gridButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "grid"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let flashButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bolt.badge.a.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.rotate.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "nsra.png")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let gridView: GridView = {
        let view = GridView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let zoomSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1.0
        slider.maximumValue = 5.0
        slider.value = 1.0
        slider.minimumTrackTintColor = .systemYellow
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.alpha = 0 // Hidden initially
        return slider
    }()
    
    private let shutterView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupLocationManager()
        setupCamera()
        setupUI()
        setupGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
        super.viewWillDisappear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
        shutterView.frame = view.bounds
        updatePreviewLayerOrientation()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                videoDeviceInput = videoInput
            }
        } catch { return }
        
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    private func setupUI() {
        view.addSubview(gridView)
        view.addSubview(topBlurView)
        view.addSubview(captureButton)
        view.addSubview(imageView)
        view.addSubview(logoImageView)
        view.addSubview(zoomSlider)
        view.addSubview(shutterView)
        
        let controlStack = UIStackView(arrangedSubviews: [flashButton, gridButton, switchCameraButton, infoButton])
        controlStack.axis = .horizontal
        controlStack.distribution = .equalSpacing
        controlStack.alignment = .center
        controlStack.spacing = 24
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        topBlurView.contentView.addSubview(controlStack)
        
        NSLayoutConstraint.activate([
            // Top Blur Container
            topBlurView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            topBlurView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topBlurView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
            topBlurView.heightAnchor.constraint(equalToConstant: 60),
            
            controlStack.leadingAnchor.constraint(equalTo: topBlurView.contentView.leadingAnchor, constant: 20),
            controlStack.trailingAnchor.constraint(equalTo: topBlurView.contentView.trailingAnchor, constant: -20),
            controlStack.centerYAnchor.constraint(equalTo: topBlurView.contentView.centerYAnchor),
            
            // Logo (Floating)
            logoImageView.topAnchor.constraint(equalTo: topBlurView.bottomAnchor, constant: 10),
            logoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logoImageView.widthAnchor.constraint(equalToConstant: 35),
            logoImageView.heightAnchor.constraint(equalToConstant: 35),
            
            // Grid
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Capture Button
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            captureButton.widthAnchor.constraint(equalToConstant: 90),
            captureButton.heightAnchor.constraint(equalToConstant: 90),
            
            // Zoom Slider
            zoomSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            zoomSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            zoomSlider.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -40),
            
            // Image Preview (Small thumb)
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            imageView.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Add targets
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        captureButton.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        infoButton.addTarget(self, action: #selector(showInfoAlert), for: .touchUpInside)
        gridButton.addTarget(self, action: #selector(toggleGrid), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        zoomSlider.addTarget(self, action: #selector(zoomSliderChanged(_:)), for: .valueChanged)
    }
    
    private func setupGestures() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    // MARK: - Actions
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }
    
    @objc private func toggleGrid() {
        isGridVisible.toggle()
        gridView.isHidden = !isGridVisible
        gridButton.tintColor = isGridVisible ? .systemYellow : .white
        feedbackGenerator()
    }
    
    @objc private func toggleFlash() {
        feedbackGenerator()
        switch flashMode {
        case .auto:
            flashMode = .on
            flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
            flashButton.tintColor = .systemYellow
        case .on:
            flashMode = .off
            flashButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
            flashButton.tintColor = .white
        case .off:
            flashMode = .auto
            flashButton.setImage(UIImage(systemName: "bolt.badge.a.fill"), for: .normal)
            flashButton.tintColor = .white
        @unknown default: break
        }
    }
    
    @objc private func switchCamera() {
        feedbackGenerator()
        sessionQueue.async {
            let currentPosition = self.videoDeviceInput.device.position
            let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else { return }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                self.captureSession.beginConfiguration()
                self.captureSession.removeInput(self.videoDeviceInput)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoDeviceInput = newInput
                } else {
                    self.captureSession.addInput(self.videoDeviceInput)
                }
                self.captureSession.commitConfiguration()
                
                DispatchQueue.main.async {
                    self.currentZoomFactor = 1.0
                    self.zoomSlider.value = 1.0
                    self.hideZoomSlider()
                }
            } catch { print(error) }
        }
    }
    
    @objc private func zoomSliderChanged(_ sender: UISlider) {
        updateZoom(factor: CGFloat(sender.value))
        showZoomSlider()
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            showZoomSlider()
        }
        if gesture.state == .changed {
            let factor = currentZoomFactor * gesture.scale
            updateZoom(factor: factor)
        } else if gesture.state == .ended {
            currentZoomFactor = min(max(currentZoomFactor * gesture.scale, 1.0), 5.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.hideZoomSlider()
            }
        }
    }
    
    private func updateZoom(factor: CGFloat) {
        let device = videoDeviceInput.device
        do {
            try device.lockForConfiguration()
            let zoom = min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor, 5.0)
            device.videoZoomFactor = zoom
            device.unlockForConfiguration()
            
            DispatchQueue.main.async {
                self.zoomSlider.value = Float(zoom)
            }
        } catch { print(error) }
    }
    
    private func showZoomSlider() {
        UIView.animate(withDuration: 0.3) { self.zoomSlider.alpha = 1.0 }
    }
    
    private func hideZoomSlider() {
        UIView.animate(withDuration: 0.3) { self.zoomSlider.alpha = 0.0 }
    }
    
    private func feedbackGenerator() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    @objc private func capturePhoto() {
        feedbackGenerator()
        UIView.animate(withDuration: 0.05, animations: { self.shutterView.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.1) { self.shutterView.alpha = 0 }
        }
        
        sessionQueue.async {
            guard let connection = self.photoOutput.connection(with: .video) else { return }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = self.previewLayer.connection?.videoOrientation ?? .portrait
            }
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = self.flashMode
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error { print(error); return }
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let watermarkedImage = self.addWatermark(image: image, location: self.currentLocation ?? CLLocation())
            DispatchQueue.main.async {
                self.imageView.image = watermarkedImage
                self.imageView.isHidden = false
                self.imageView.alpha = 0
                self.imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    self.imageView.alpha = 1
                    self.imageView.transform = .identity
                })
                
                self.previewTimer?.invalidate()
                self.previewTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                    UIView.animate(withDuration: 0.5, animations: {
                        self.imageView.alpha = 0
                        self.imageView.transform = CGAffineTransform(translationX: -100, y: 0)
                    }) { _ in
                        self.imageView.isHidden = true
                    }
                }
                UIImageWriteToSavedPhotosAlbum(watermarkedImage, nil, nil, nil)
            }
        }
    }
    
    // MARK: - Watermark
    private func addWatermark(image: UIImage, location: CLLocation) -> UIImage {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let watermarkText = """
        Latitud: \(location.coordinate.latitude)
        Longitud: \(location.coordinate.longitude)
        Elevación: \(location.altitude) m
        Precisión: \(location.horizontalAccuracy) m
        Fecha: \(dateFormatter.string(from: Date()))
        Dirección: \(address)
        """
        
        let fontSize: CGFloat = image.size.width * 0.025
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white,
            .backgroundColor: UIColor.black.withAlphaComponent(0.4)
        ]
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        let textPadding: CGFloat = image.size.width * 0.03
        let textHeight: CGFloat = image.size.height * 0.15
        let textRect = CGRect(x: textPadding, y: image.size.height - textHeight - textPadding, width: image.size.width - 2 * textPadding, height: textHeight)
        
        watermarkText.draw(in: textRect, withAttributes: textAttributes)
        
        if let logo = UIImage(named: "nsra.png") {
            let logoSize: CGFloat = image.size.width * 0.12
            let logoRect = CGRect(x: image.size.width - logoSize - textPadding, y: textPadding, width: logoSize, height: logoSize)
            logo.draw(in: logoRect, blendMode: .normal, alpha: 0.9)
        }
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? image
    }
    
    // MARK: - Location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        if let location = currentLocation {
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
                if let placemark = placemarks?.first {
                    self?.address = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea, placemark.country]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { print(error) }
    
    // MARK: - Helpers
    @objc private func showInfoAlert() {
        feedbackGenerator()
        let currentYear = Calendar.current.component(.year, from: Date())
        let alert = UIAlertController(title: "NS TagCam", message: """
                Versión Premium
                Desarrollado por:
                Ing. Elián Hernández Olarte
                Email: Jernelx7@gmail.com
                Web: www.jernelsystems.com
                
                Copyright © \(currentYear) JernelSystems. All rights reserved.
                """, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Visitar Sitio Web", style: .default, handler: { _ in
            if let url = URL(string: "https://www.jernelsystems.com") {
                UIApplication.shared.open(url)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cerrar", style: .cancel))
        present(alert, animated: true)
    }

    private func updatePreviewLayerOrientation() {
        guard let connection = previewLayer?.connection else { return }
        let orientation = UIDevice.current.orientation
        if orientation.isValidInterfaceOrientation {
            switch orientation {
            case .portrait: connection.videoOrientation = .portrait
            case .landscapeLeft: connection.videoOrientation = .landscapeRight
            case .landscapeRight: connection.videoOrientation = .landscapeLeft
            case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
            default: connection.videoOrientation = .portrait
            }
        }
    }
}
