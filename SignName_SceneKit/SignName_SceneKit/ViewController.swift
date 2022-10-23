//
//  ViewController.swift
//  SignName_SceneKit
//
//  Created by Jeon Jimin on 2022/08/29.
//

import UIKit
import SceneKit
import ARKit
import Vision
import CoreML
import RealityKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var textOberlay: UITextField!
    
    @IBOutlet weak var firstBtn: UIButton!
    @IBOutlet weak var secondBtn: UIButton!
    @IBOutlet weak var thirdBtn: UIButton!
    
    @IBOutlet weak var nextBtn: UIButton!
    
    var nameArray:[String] = ["","",""]
    var last = ""
    
    
    let frameCounter = 7
    var handPosePredictionInterval = 1
    
    
    var visionRequests = [VNRequest]()
    
    var currentBuffer: CVPixelBuffer?
    
    var string = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        firstBtn.layer.cornerRadius = 10
        firstBtn.backgroundColor = .btnBackground
        
        secondBtn.layer.cornerRadius = 10
        secondBtn.backgroundColor = .btnBackground
        
        thirdBtn.layer.cornerRadius = 10
        thirdBtn.backgroundColor = .btnBackground
        
        textOberlay.backgroundColor = .textBackground
        textOberlay.layer.cornerRadius = 10
        
        nextBtn.layer.cornerRadius = 10

        //MARK: - UI
        setButton()

    }
    
    func setButton() {
        
        if nameArray[0] == "" {
            firstBtn.isHidden = true
        } else {
            firstBtn.isHidden = false
        }
        if nameArray[1] == "" {
            secondBtn.isHidden = true
        } else {
            secondBtn.isHidden = false
        }
        if nameArray[2] == "" {
            thirdBtn.isHidden = true
        } else {
            thirdBtn.isHidden = false
        }
        
        firstBtn.titleLabel?.text = self.nameArray[0]
        secondBtn.titleLabel?.text = self.nameArray[1]
        thirdBtn.titleLabel?.text = self.nameArray[2]
        
        firstBtn.setTitle(self.nameArray[0], for: .normal)
        secondBtn.setTitle(self.nameArray[1], for: .normal)
        thirdBtn.setTitle(self.nameArray[2], for: .normal)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARBodyTrackingConfiguration()
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }


    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
    
    // MARK: - HIDE STATUS BAR
    override var prefersStatusBarHidden : Bool { return true }
    
    @IBAction func TouchBtn(_ sender: UIButton) {
        if nameArray[sender.tag] == "Space" {
            string += "_"
        } else if nameArray[sender.tag] == "Nothing" {
            string += ""
        }else {
            string += nameArray[sender.tag]
        }
        textOberlay.text = string
    }
    
    @IBAction func nextBtn(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "SecondView", bundle: nil)
        guard let secondViewController = storyboard.instantiateViewController(withIdentifier: "SecondViewController") as? SecondViewController else { return }
        secondViewController.string = string

        navigationController?.pushViewController(secondViewController, animated: true)
        
    }
    
    
}

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        let pixelBuffer = frame.capturedImage
        let defaultConfig = MLModelConfiguration()
        let signLanguagePrediction = try? SignLanguageDetection_E (configuration: defaultConfig)
        
        let handPoseRequest = VNDetectHumanHandPoseRequest()
        
        handPoseRequest.revision = VNDetectHumanHandPoseRequestRevision1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([handPoseRequest])
        } catch {
            assertionFailure("Human pose request filaed: \(error)")
        }
        
        guard let handPoses = handPoseRequest.results, !handPoses.isEmpty else {
            return
        }
        
        let handObservation = handPoses.first
        
        if handPosePredictionInterval > 7 {
            handPosePredictionInterval = 1
        }

        if frameCounter % handPosePredictionInterval == 0 {
            print("**frame \(frameCounter) , \(handPosePredictionInterval)")
            guard let keypointsMultiArray = try? handObservation?.keypointsMultiArray() else { fatalError() }
            guard let handPosePrediction = try? signLanguagePrediction?.prediction(poses: keypointsMultiArray) else { return }
            let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label]!
            
            print("**label \(handPosePrediction.label)")

            if confidence > 0.9 {
                renderHandPoseEffect(name: handPosePrediction.label)
            }
        }
        handPosePredictionInterval += 1
    }
    
    func renderHandPoseEffect(name: String) {
        print(nameArray.count)
        if last != name {
            if nameArray.count > 2 {
                nameArray.removeFirst()
            }
            switch name {
            case "Space" :
                nameArray.append("_")
            case "Nothing" :
                break
            default:
                nameArray.append(name)
            }
            last = name
            if string.count > 10 {
                string = ""
            }
            setButton()
        }
    }
}
