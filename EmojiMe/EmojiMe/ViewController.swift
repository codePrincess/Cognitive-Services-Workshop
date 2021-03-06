//
//  ViewController.swift
//  EmojiMe
//
//  Created by Alexander Repty on 20.05.16.
//  Copyright © 2016 maks apps. All rights reserved.
//

import UIKit

import Social

extension Array {
    func randomElement() -> Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Properties
    
    var image: UIImage? = nil {
        didSet {
            self.imageView.image = self.image
        }
    }
    var emojis: [CognitiveServicesEmotionResult]? = nil {
        didSet {
            if nil == self.image {
                return
            }
            
            if let results = self.emojis {
                UIGraphicsBeginImageContext(self.image!.size)
                self.image?.drawInRect(CGRect(origin: CGPointZero, size: self.image!.size))
                
                for result in results {
                    var availableEmojis = [String]()
                    switch result.emotion {
                        case .Anger:
                            availableEmojis.append("😡")
                            availableEmojis.append("😠")
                        case .Contempt:
                            availableEmojis.append("😤")
                        case .Disgust:
                            availableEmojis.append("😷")
                            availableEmojis.append("🤐")
                        case .Fear:
                            availableEmojis.append("😱")
                        case .Happiness:
                            availableEmojis.append("😝")
                            availableEmojis.append("😀")
                            availableEmojis.append("😃")
                            availableEmojis.append("😄")
                            availableEmojis.append("😆")
                            availableEmojis.append("😊")
                            availableEmojis.append("🙂")
                            availableEmojis.append("☺️")
                        case .Neutral:
                            availableEmojis.append("😶")
                            availableEmojis.append("😐")
                            availableEmojis.append("😑")
                        case .Sadness:
                            availableEmojis.append("🙁")
                            availableEmojis.append("😞")
                            availableEmojis.append("😟")
                            availableEmojis.append("😔")
                            availableEmojis.append("😢")
                            availableEmojis.append("😭")
                        case .Surprise:
                            availableEmojis.append("😳")
                            availableEmojis.append("😮")
                            availableEmojis.append("😲")
                    }
                    
                    let emoji = availableEmojis.randomElement()
                    
                    let maximumSize = result.frame.size
                    let string = emoji as NSString
                    let startingFontSize = 8192.0

                    var actualFontSize = startingFontSize
                    var stepping = actualFontSize
                    repeat {
                        stepping /= 2.0
                        if stepping < 1.0 {
                            break
                        }
                        
                        let font = UIFont.systemFontOfSize(CGFloat(actualFontSize))
                        let calculatedSize = string.sizeWithAttributes([NSFontAttributeName: font])
                        
                        if calculatedSize.width > maximumSize.width {
                            actualFontSize -= stepping
                        } else {
                            actualFontSize += stepping
                        }
                    } while true
                    
                    let font = UIFont.systemFontOfSize(CGFloat(actualFontSize))
                    string.drawInRect(result.frame, withAttributes: [NSFontAttributeName: font])
                }
                
                self.image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }
    }
    
    // MARK: IBOutlets
    
    @IBOutlet weak var stepOneButton: UIButton!
    @IBOutlet weak var stepTwoButton: UIButton!
    @IBOutlet weak var stepThreeButton: UIButton!
    
    @IBOutlet weak var stepOneLabel: UILabel!
    @IBOutlet weak var stepTwoLabel: UILabel!
    @IBOutlet weak var stepThreeLabel: UILabel!
    
    @IBOutlet weak var stepOneSpinner: UIActivityIndicatorView!
    @IBOutlet weak var stepTwoSpinner: UIActivityIndicatorView!
    @IBOutlet weak var stepThreeSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var serviceSelectionControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: IBActions
    
    @IBAction func chooseImage(sender: AnyObject) {
        self.image = nil
        self.emojis = nil
        
        self.validateCurrentStep()
        
        self.stepOneLabel.text = ""
        self.stepTwoLabel.text = ""
        self.stepThreeLabel.text = ""
        self.stepOneSpinner.startAnimating()
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        imagePickerController.sourceType = .PhotoLibrary
        
        self.presentViewController(
            imagePickerController,
            animated: true,
            completion: nil
        )
    }
    
    @IBAction func emojiMeImage(sender: AnyObject) {
        self.emojis = nil
        
        self.validateCurrentStep()
        
        self.stepTwoLabel.text = ""
        self.stepTwoSpinner.startAnimating()
        
        let manager = CognitiveServicesManager()
        manager.retrievePlausibleEmotionsForImage(self.image!) { (result, error) -> (Void) in
            dispatch_async(dispatch_get_main_queue(), { 
                self.stepTwoSpinner.stopAnimating()
                
                if let _ = error {
                    self.stepTwoLabel.text = "😱"
                    return
                }
                
                self.emojis = result
                self.validateCurrentStep()
            })
        }
    }
    
    @IBAction func shareImage(sender: AnyObject) {
        self.stepThreeLabel.text = ""
        self.stepThreeSpinner.startAnimating()
        
        let serviceType = self.serviceSelectionControl.selectedSegmentIndex == 0 ? SLServiceTypeTwitter : SLServiceTypeFacebook
        let composeViewController = SLComposeViewController(forServiceType: serviceType)
        composeViewController.addImage(self.image!)
        
        composeViewController.completionHandler = { (result) in
            self.stepThreeSpinner.stopAnimating()
            
            switch result {
            case .Cancelled:
                self.stepThreeLabel.text = "🙁"
            case .Done:
                self.stepThreeLabel.text = "😃"
            }
        }
        
        self.presentViewController(
            composeViewController,
            animated: true,
            completion: nil
        )
    }

    // MARK: Private Methods
    
    private func validateCurrentStep() {
        self.stepOneSpinner.stopAnimating()
        self.stepTwoSpinner.stopAnimating()
        self.stepThreeSpinner.stopAnimating()
        
        if let _ = self.image {
            // We have selected an image, update our status accordingly and enable the next step's button.
            self.stepOneLabel.text = "😃"
            self.stepTwoButton.enabled = true
        } else {
            self.stepTwoLabel.text = ""
            self.stepThreeLabel.text = ""
            self.stepTwoButton.enabled = false
            self.stepThreeButton.enabled = false
        }
        
        if let _ = self.emojis {
            // We have received a list of categories, update our status accordingly and enable the next step's button.
            self.stepTwoLabel.text = "😃"
            self.stepThreeButton.enabled = true
        } else {
            self.stepThreeLabel.text = ""
            self.stepThreeButton.enabled = false
        }
    }
    
    // MARK: UIImagePickerControllerDelegate Methods
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        self.stepOneLabel.text = "🙁"
        self.validateCurrentStep()
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        if let image = info[UIImagePickerControllerOriginalImage] as! UIImage? {
            self.image = image
        } else {
            self.stepOneLabel.text = "😱"
        }
        
        self.validateCurrentStep()
    }
}

