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
        let insideImage = #imageLiteral(resourceName: "201407150141_OB_A81_INSIDE")
        guard let inside = insideImage.split() else {
            return
        }
        //Front plane
        let frontPlane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let frontMaterial = SCNMaterial()
        frontMaterial.diffuse.contents = UIImage(named: "201407150120_OB_A81_FRONT")
        frontPlane.materials = [frontMaterial]
        
        //Inside left plane
        let insideLeftPlane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let insideLeftMaterial = SCNMaterial()
        insideLeftMaterial.diffuse.contents = inside.left
        insideLeftPlane.materials = [insideLeftMaterial]
        
        //Inside right plane
        let insideRightPlane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let insideRightMaterial = SCNMaterial()
        insideRightMaterial.diffuse.contents = inside.right
        insideRightPlane.materials = [insideRightMaterial]
        
        //Front node
        let frontNode = SCNNode(geometry: frontPlane)
        frontNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: frontPlane, options: nil))
        frontNode.position = position
        frontNode.eulerAngles = SCNVector3Make(Float(-Double.pi) / 2, 0, 0)
        frontNode.pivot = SCNMatrix4MakeTranslation(-width / 2, 0, 0)
        sceneView.scene.rootNode.addChildNode(frontNode)
        
        //Inside left node
        let insideLeftNode = SCNNode(geometry: insideLeftPlane)
        insideLeftNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: insideLeftPlane, options: nil))
        insideLeftNode.position = position
        insideLeftNode.eulerAngles = SCNVector3Make(Float(-Double.pi) / 2, 0, Float(-Double.pi))
        insideLeftNode.pivot = SCNMatrix4MakeTranslation(width / 2, 0, 0)
        sceneView.scene.rootNode.addChildNode(insideLeftNode)
        
        //Inside right node
        let insideRightNode = SCNNode(geometry: insideRightPlane)
        insideRightNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: insideRightPlane, options: nil))
        insideRightNode.position = position
        insideRightNode.eulerAngles = SCNVector3Make(Float(-Double.pi) / 2, 0, 0)
        insideRightNode.pivot = SCNMatrix4MakeTranslation(-width / 2, 0, 0)
        sceneView.scene.rootNode.addChildNode(insideRightNode)
        
        //Animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let angleDelta: Float = 0.03
            frontNode.eulerAngles = SCNVector3Make(frontNode.eulerAngles.x,
                                                   frontNode.eulerAngles.y,
                                                   frontNode.eulerAngles.z + angleDelta)
            insideLeftNode.eulerAngles = SCNVector3Make(insideLeftNode.eulerAngles.x,
                                                    insideLeftNode.eulerAngles.y,
                                                    insideLeftNode.eulerAngles.z + angleDelta)
            if insideLeftNode.eulerAngles.z > 0 {
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
        plane.isHidden = true
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
