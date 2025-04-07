import UIKit
import AVFoundation
import CoreLocation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
    
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var address: String = "Cargando dirección..."
    var previewTimer: Timer?
    let geocoder = CLGeocoder()

    let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "lente"), for: .normal) // Usa el ícono lente.png
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        return button
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true // Ocultar la imagen inicialmente
        return imageView
    }()
    
    let infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "info_icon"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(showInfoAlert), for: .touchUpInside)
        return button
    }()
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "nsra.png") // Usa el logo nsra.png
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupCamera()
        setupUI()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer.frame = view.layer.bounds
        updatePreviewLayerOrientation()
    }

    func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error al crear entrada de cámara: \(error)")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("No se pudo agregar entrada de cámara.")
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            print("No se pudo agregar salida de foto.")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func setupUI() {
        view.addSubview(captureButton)
        view.addSubview(imageView)
        view.addSubview(infoButton)
        view.addSubview(logoImageView) // Agregar el UIImageView del logo
        
        NSLayoutConstraint.activate([
            // Restricciones del logo en la parte superior
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 50), // Ajusta el tamaño según sea necesario
            logoImageView.heightAnchor.constraint(equalToConstant: 50), // Ajusta el tamaño según sea necesario
            
            // Restricciones del botón de captura
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.widthAnchor.constraint(equalToConstant: 50), // Ajusta el ancho según sea necesario
            captureButton.heightAnchor.constraint(equalToConstant: 50), // Ajusta la altura según sea necesario
            
            // Restricciones del imageView
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9),
            
            // Restricciones del botón de información
            infoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            infoButton.widthAnchor.constraint(equalToConstant: 40),
            infoButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func capturePhoto() {
        guard let connection = photoOutput.connection(with: .video) else { return }

        // Ajustar la orientación del video
        if let videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) {
            connection.videoOrientation = videoOrientation
        }

        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        if let location = currentLocation {
            // Obtener la dirección para la ubicación actual
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                if let error = error {
                    print("Error al obtener la dirección: \(error)")
                    self?.address = "Dirección desconocida"
                } else if let placemark = placemarks?.first {
                    self?.address = [placemark.thoroughfare, placemark.locality, placemark.administrativeArea, placemark.country]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error al obtener la ubicación: \(error.localizedDescription)")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let currentLocation = currentLocation else { return }

        if let image = UIImage(data: imageData) {
            // Procesar la imagen
            let watermarkedImage = addWatermark(image: image, location: currentLocation)

            DispatchQueue.main.async {
                self.imageView.image = watermarkedImage
                self.imageView.isHidden = false // Mostrar la imagen

                // Iniciar el temporizador para ocultar la imagen después de 1 segundo
                self.previewTimer?.invalidate()
                self.previewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    self.imageView.isHidden = true
                }
            }

            // Guardar la imagen en la galería con la orientación original
            UIImageWriteToSavedPhotosAlbum(watermarkedImage, nil, nil, nil)
        }
    }
    
    func addWatermark(image: UIImage, location: CLLocation) -> UIImage {
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
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20),
            .foregroundColor: UIColor.white,
            .backgroundColor: UIColor.black.withAlphaComponent(0.7)
        ]
        
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        let textPadding: CGFloat = 20.0
        let textRect = CGRect(x: textPadding, y: image.size.height - 180 - textPadding, width: image.size.width - 2 * textPadding, height: 180)
        
        watermarkText.draw(in: textRect, withAttributes: textAttributes)
        
        guard let logo = UIImage(named: "nsra.png") else {
            print("Error: No se pudo cargar el logo.")
            return image
        }
        
        let logoSize: CGFloat = 80.0
        let logoRect = CGRect(x: image.size.width - logoSize - textPadding, y: textPadding, width: logoSize, height: logoSize)
        
        logo.draw(in: logoRect, blendMode: .normal, alpha: 1.0)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result ?? image
    }
    
    @objc func showInfoAlert() {
        let alert = UIAlertController(title: "Información", message: """
                Desarrollado por: 
                Ing. Elián Hernández Olarte
                Email: Jernelx7@gmail.com
                Whatsapp: +521 993455110
                Copyright © 2024 Jernel Olart. All rights reserved.
                """, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func updatePreviewLayerOrientation() {
        guard let connection = previewLayer.connection else { return }
        
        switch UIDevice.current.orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        default:
            connection.videoOrientation = .portrait
        }
    }
}
