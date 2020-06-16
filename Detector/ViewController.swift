//
//  ViewController.swift
//  Detector
//
//  Created by Salah Khaled on 6/6/20.
//  Copyright © 2020 Salah Khaled. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Social
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var viewDesc: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var viewImage: UIView!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var thumbImage: UIImageView!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    var classificationResults : [VNClassificationObservation] = []
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        setupView()
        
    }
    

    private func setupView() {
        viewImage.layer.cornerRadius = 10.0
        viewDesc.layer.cornerRadius = 10.0
    }
    
    func detect(image: CIImage) {
        
        // Load the ML model through its generated class
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("can't load ML model")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first
                else {
                    fatalError("unexpected result type from VNCoreMLRequest")
            }
            DispatchQueue.main.async {
                let array = topResult.identifier.split(separator: ",")
                self.requestInfo(imageName: String(array.first ?? "").capitalized)
                self.navigationItem.title = String(array.first ?? "").capitalized
                self.navigationController?.navigationBar.isTranslucent = false
            }
            
        
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
    
    func requestInfo(imageName: String) {
        
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : imageName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "500",
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                
                let imageJson: JSON = JSON(response.result.value!)
                let pageID = imageJson["query"]["pageids"][0].stringValue
                let imageDesc = imageJson["query"]["pages"][pageID]["extract"].stringValue
                
                print("response: \(response)")
                
                self.descLabel.text = imageDesc
                self.descLabel.isHidden = false
                self.viewDesc.isHidden = false
                self.viewImage.isHidden = false
                self.thumbImage.isHidden = false
                
                let thumbURL = imageJson["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                self.thumbImage.sd_setImage(with: URL(string: thumbURL))
                
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            
            imageView.image = image
            imagePicker.dismiss(animated: true, completion: nil)
            guard let ciImage = CIImage(image: image) else {
                fatalError("couldn't convert uiimage to CIImage")
            }
            detect(image: ciImage)
        }
    }
    
    
    @IBAction func cameraTapped(_ sender: Any) {
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    return input.rawValue
}
