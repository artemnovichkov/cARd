//
//  ViewController.swift
//  cARd
//
//  Created by Artem Novichkov on 03/08/2017.
//  Copyright © 2017 Rosberry. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var planes = [OverlayPlane]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.delegate = self
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        sceneView.addGestureRecognizer(recognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    fileprivate func addCardNode() {
        let plane = SCNPlane(width: 0.12065, height: 0.085725)
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = UIImage(named: "201407150120_OB_A81_FRONT")
        plane.materials = [material]
        
        let cardNode = SCNNode(geometry: plane)
        cardNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: plane, options: nil))
        cardNode.position = SCNVector3(0, 0, -0.5)
        
        sceneView.scene.rootNode.addChildNode(cardNode)
    }
    
    @objc func tap(recognizer: UIGestureRecognizer) {
        let touchLocation = recognizer.location(in: sceneView)
        let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        guard let result = results.first else {
            return
        }
        
        let position = SCNVector3(result.worldTransform.columns.3.x,
                                  result.worldTransform.columns.3.y,
                                  result.worldTransform.columns.3.z)
        
        addCard(withPosition: position, width: 0.1016, height: 0.0762)
    }
    
    func addCard(withPosition position: SCNVector3, width: Float, height: Float) {
        let cardNode = Card(width: width, height: height)
        cardNode.position = position
        sceneView.scene.rootNode.addChildNode(cardNode)
        
        //Animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            cardNode.progress += 0.025
            if cardNode.secondFrontNode!.eulerAngles.z > Float.pi {
                timer.invalidate()
            }
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        let plane = OverlayPlane(anchor: planeAnchor)
//        plane.isHidden = true
        planes.append(plane)
        print("START")
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        let plane = self.planes.filter { $0.anchor.identifier == anchor.identifier }.first
        
        if plane == nil {
            return
        }
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }
}

final class Card: SCNNode {
    
    let width: Float
    let height: Float
    
    var firstFrontNode: SCNNode!
    var firstBackNode: SCNNode!
    var secondFrontNode: SCNNode!
    var secondBackNode: SCNNode!
    
    var progress = 0.0 {
        didSet {
            let angleDelta: Float = 0.03
            if firstBackNode.eulerAngles.z < 0 {
                firstFrontNode.eulerAngles = SCNVector3Make(firstFrontNode.eulerAngles.x,
                                                                     firstFrontNode.eulerAngles.y,
                                                                     firstFrontNode.eulerAngles.z + angleDelta)
                firstBackNode.eulerAngles = SCNVector3Make(firstBackNode.eulerAngles.x,
                                                                    firstBackNode.eulerAngles.y,
                                                                    firstBackNode.eulerAngles.z + angleDelta)
            }
            else {
                secondFrontNode.eulerAngles = SCNVector3Make(secondFrontNode.eulerAngles.x,
                                                                      secondFrontNode.eulerAngles.y,
                                                                      secondFrontNode.eulerAngles.z + angleDelta)
                secondBackNode.eulerAngles = SCNVector3Make(secondBackNode.eulerAngles.x,
                                                                     secondBackNode.eulerAngles.y,
                                                                     secondBackNode.eulerAngles.z + angleDelta)
            }
        }
    }
    
    init(width: Float, height: Float) {
        self.width = width
        self.height = height
        super.init()
        initialize()
    }
    
    func initialize() {
        let insideImage = #imageLiteral(resourceName: "201407150141_OB_A81_INSIDE")
        guard let inside = insideImage.split() else {
            return
        }
        //first front plane
        let firstFrontPlane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let frontMaterial = SCNMaterial()
        frontMaterial.diffuse.contents = #imageLiteral(resourceName: "201407150120_OB_A81_FRONT")
        firstFrontPlane.materials = [frontMaterial]
        
        //first back plane
        let firstBackPlane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let insideLeftMaterial = SCNMaterial()
        insideLeftMaterial.diffuse.contents = inside.left
        firstBackPlane.materials = [insideLeftMaterial]
        
        //second front plane
        let secondFrontPlane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let insideRightMaterial = SCNMaterial()
        insideRightMaterial.diffuse.contents = inside.right
        secondFrontPlane.materials = [insideRightMaterial]
        
        //second back plane
        let secondBackPlane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let backMaterial = SCNMaterial()
        backMaterial.diffuse.contents = #imageLiteral(resourceName: "201407150104_OB_A81_BACK")
        secondBackPlane.materials = [backMaterial]
        
        //Front node
        firstFrontNode = SCNNode(geometry: firstFrontPlane)
        firstFrontNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: firstFrontPlane, options: nil))
        firstFrontNode?.position = position
        firstFrontNode?.eulerAngles = SCNVector3Make(-Float.pi / 2, 0, 0)
        firstFrontNode?.pivot = SCNMatrix4MakeTranslation(-width / 2, 0, 0)
        addChildNode(firstFrontNode!)
        
        //first back node
        firstBackNode = SCNNode(geometry: firstBackPlane)
        firstBackNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: firstBackPlane, options: nil))
        firstBackNode?.position = position
        firstBackNode?.eulerAngles = SCNVector3Make(-Float.pi / 2, 0, -Float.pi)
        firstBackNode?.pivot = SCNMatrix4MakeTranslation(width / 2, 0, 0)
        addChildNode(firstBackNode!)
        
        //second front node
        secondFrontNode = SCNNode(geometry: secondFrontPlane)
        secondFrontNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: secondFrontPlane, options: nil))
        secondFrontNode?.position = position
        secondFrontNode?.eulerAngles = SCNVector3Make(-Float.pi / 2, 0, 0)
        secondFrontNode?.pivot = SCNMatrix4MakeTranslation(-width / 2, 0, 0)
        addChildNode(secondFrontNode!)
        
        //second back node
        secondBackNode = SCNNode(geometry: secondBackPlane)
        secondBackNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: secondBackPlane, options: nil))
        secondBackNode?.position = position
        secondBackNode?.eulerAngles = SCNVector3Make(-Float.pi / 2, 0, -Float.pi)
        secondBackNode?.pivot = SCNMatrix4MakeTranslation(width / 2, 0, 0)
        addChildNode(secondBackNode!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
