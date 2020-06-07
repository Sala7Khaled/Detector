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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var viewDesc: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    var classificationResults : [VNClassificationObservation] = []
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        setupView()
        
    }
    

    private func setupView() {
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
        "prop" : "extracts",
        "exintro" : "",
        "explaintext" : "",
        "titles" : imageName,
        "indexpageids" : "",
        "redirects" : "1",
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                
                let imageJson: JSON = JSON(response.result.value!)
                let pageID = imageJson["query"]["pageids"][0].stringValue
                let imageDesc = imageJson["query"]["pages"][pageID]["extract"].stringValue
                
                print("response: \(response)")
                print("imageJson: \(imageJson)")
                print("pageID: \(pageID)")
                print("imageDesc: \(imageDesc)" )
                
                
                self.descLabel.text = imageDesc
                self.descLabel.isHidden = false
                self.viewDesc.isHidden = false
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
