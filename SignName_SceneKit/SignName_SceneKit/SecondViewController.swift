//
//  SecondViewController.swift
//  SignName_SceneKit
//
//  Created by 전지민 on 2022/09/01.
//

import UIKit
import SceneKit
import ARKit
import Vision
import CoreML
import RealityKit

protocol VirtualContentController: ARSCNViewDelegate {
    /// The root node for the virtual content.
    var contentNode: SCNNode? { get set }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
}

class SecondViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var string = ""
    
    let visionQueue = DispatchQueue(label: "com.viseo.ARML.visionqueue")
    
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private var evidenBuffer = [HandGestureProcessor.PointsPair]()
    private var isFirstSegment = true
    private var lastObservationTimestamp = Date()
    private var gestureProcessor = HandGestureProcessor()
    
    private var lastDistance = 0.0
    private var lastPositinon = CGPoint(x: 0, y: 0)
    private var lastVector: SCNVector3?
    
    let handAnchorEntity = AnchorEntity()
    var hand: BodyTrackedEntity?
    
    
//    MARK: - SCNNode properties
    lazy var textNode = SCNText(string: string, extrusionDepth: 1)
    var contentNode: SCNNode?
    
    override func loadView() {
        super.loadView()
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.delegate = self
        sceneView.session.run(configuration)

        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let text = SCNText(string: string, extrusionDepth: 1)
        let material = SCNMaterial()
        let color = [UIColor.purple, UIColor.deepblue, UIColor.skyblue].randomElement()
        material.diffuse.contents = color
        material.lightingModel = .physicallyBased
        // We want our ball to look metallic
        material.metalness.contents = 1.0
        // And shiny
        material.roughness.contents = 0.0
//        material.blendMode = .
//        material.transparencyMode = .dualLayer
        textNode.materials = [material]
        contentNode = SCNNode()
        guard let contentNode = contentNode else {
            return
        }
        contentNode.position = SCNVector3(0, 0, -0.3)
        contentNode.scale = SCNVector3(0.001, 0.001, 0.001)
        contentNode.geometry = textNode
        sceneView.scene.rootNode.addChildNode(contentNode)
        sceneView.automaticallyUpdatesLighting = true
        
        sceneView.autoenablesDefaultLighting = true
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
     
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }


    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
    
    // MARK: - ARSessionDelegate
    
    func renderer(_ renderer: SCNNode, nodeFor anchor: ARAnchor) -> SCNNode? {
        contentNode = SCNNode()
        contentNode?.geometry = textNode
        
        return contentNode
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
    
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        let request = VNDetectHumanHandPoseRequest(completionHandler: bodyPoseHandler)
        request.maximumHandCount = 1
        
        do {
            try requestHandler.perform([request])

            guard let observation = handPoseRequest.results?.first else { return }
            let thumbPoints: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint] = try observation.recognizedPoints(.thumb)
            guard let thumbTipPoint: VNRecognizedPoint = thumbPoints[.thumbTip] else { return }
            let indexPoints: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint] = try observation.recognizedPoints(.indexFinger)
            guard let indexTipPint: VNRecognizedPoint = indexPoints[.indexTip] else { return }
            print("thumbPoints \(thumbTipPoint) \(indexTipPint)")
        } catch {
            print("unable to perform the request: \(error)")
        }
    }
    
    func bodyPoseHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanHandPoseObservation] else { return }
        observations.forEach {
            processObservation($0)
        }
    }

    func processObservation(_ observation: VNHumanHandPoseObservation) {
        do  {
            let thumbPoints: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint] = try observation.recognizedPoints(.thumb)
            
            let indexPoints: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint] = try observation.recognizedPoints(.indexFinger)
            
            let thumbTipP: VNRecognizedPoint = thumbPoints[.thumbTip]!
            let indexTipP: VNRecognizedPoint = indexPoints[.indexTip]!
            
            lastDistance = thumbTipP.distance(indexTipP)
            lastPositinon = CGPoint.midPoint(p1: thumbTipP.location, p2: indexTipP.location)
            
            print("***thumb \(thumbTipP), index \(indexTipP), \(thumbTipP.x ), ---- \(lastDistance)--\(lastPositinon)")
            
        } catch {
            print(error)
        }
        setScale()
    }
    
    func setScale() {
        print("setscale")
        DispatchQueue.main.async { [self] in
            var intDistance = lastDistance * 10
            intDistance = round(intDistance)
            intDistance = intDistance / 100
            let scale = SCNVector3(intDistance, intDistance, 0.01)
            let position = SCNVector3(lastPositinon.y - 0.3, -lastPositinon.x, -1)
            print("setscale \(String(describing: contentNode?.position))---\(String(describing: position))")
            
            contentNode?.position = position
            let action = SCNAction.scale(to: intDistance, duration: 0.3)
//            let action2 = SCNAction.transform
            contentNode?.runAction(action)
        }
    }
    
}

