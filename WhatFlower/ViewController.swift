//
//  ViewController.swift
//  WhatFlower
//
//  Created by Shay Dubrovsky on 21/11/2023.
//

import UIKit
import Vision
import PhotosUI
import CoreML
import Alamofire
import SDWebImage

class ViewController: UIViewController {
    
    var galleryPicker: PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images
        
        let photoPicker = PHPickerViewController(configuration: config)
        photoPicker.delegate = self
        
        return photoPicker
    }
    
    var cameraPicker: UIImagePickerController {
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        return cameraPicker
    }
    
    let wikiUrl = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func userSelectedPhoto(_ photo: UIImage) {
//        updateImage(photo)
        
        // classify
        detect(photo)
    }
    
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    func updateNavigationTitle(_ title: String) {
        DispatchQueue.main.async {
            self.navigationItem.title = title.capitalized
        }
    }
    
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pageimages",
            "exintro": "",
            "explaintext": "",
            "titles": flowerName,
            "indexpageids": "",
            "redirects": "1",
            "pithumbsize": "500"
        ]
        AF.request(wikiUrl, method: .get, parameters: parameters).responseDecodable(of: FlowerDetails.self) { response in
            switch response.result {
            case .success:
                guard let flower: FlowerDetails = response.value else { return }
                self.descriptionLabel.text = flower.query.pages.first?.value.extract
                if let source = flower.query.pages.first?.value.thumbnail.source {
                    self.imageView.sd_setImage(with: URL(string: source))
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func detect(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { fatalError("Could not convert to CIIamge") }
        
        guard let model = try? VNCoreMLModel(for: Flowers(configuration: MLModelConfiguration()).model) else {
            fatalError("Loading CoreML Model Failed.")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            let classification = request.results?.first as? VNClassificationObservation
            
            if let flower = classification?.identifier {
                self.updateNavigationTitle(flower)
                self.requestInfo(flowerName: flower)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }


    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(cameraPicker, animated: true)
    }
    
    @IBAction func galleryTapped(_ sender: UIBarButtonItem) {
        present(galleryPicker, animated: true)
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] else { fatalError("Picker didn't have an original image.")
        }
        
        guard let photo = originalImage as? UIImage else {
            fatalError("The (Camera) Image Picker's image isn't a/n \(UIImage.self) instance.")
        }
        
        self.userSelectedPhoto(photo)
    }
}

extension ViewController: PHPickerViewControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
            if let e = error {
                print("Photo picker error: \(e)")
            }
            
            guard let photo = object as? UIImage else {
                fatalError("The Photo Picker's image isn't a/n \(UIImage.self) instance.")
            }
            
            self.userSelectedPhoto(photo)
        }
    }
}
