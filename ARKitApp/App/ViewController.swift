//
//  ViewController.swift
//  ARKitApp
//
//  Created by Steve Kerney on 8/7/17.
//  Copyright © 2017 d4rkz3r0. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum FunctionState
{
    case none
    case placingObject(String)
    case measuring
}

class ViewController: UIViewController, ARSCNViewDelegate
{
    //MARK: IBOutlets
    //ARKit via SceneKit
    @IBOutlet var sceneView: ARSCNView!
    //Buttons
    @IBOutlet weak var addObjectButton: SelectableButton!
    @IBOutlet weak var addChairButton: SelectableButton!
    @IBOutlet weak var measureToolButton: SelectableButton!
    @IBOutlet weak var resetSessionButton: SelectableButton!
    //Labels
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var trackingStateLabel: UILabel!
    @IBOutlet weak var reticleView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    //MARK: Data
    var objects: [SCNNode] = [];
    var measuringNodes: [SCNNode] = [];
    var currentFunctionState: FunctionState = .none;
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        initUIElems();
        startARSession();
    }
}


//MARK: ARSession Delegate Functions
extension ViewController
{
    //Fatal Error, ie: Non A9 Processor
    func session(_ session: ARSession, didFailWithError error: Error)
    {
        // Present an error message to the user
        displayMessage(error.localizedDescription, label: messageLabel, duration: 2.0);
    }
    
    //Session was interrupted
    func sessionWasInterrupted(_ session: ARSession)
    {
        displayMessage("Session Interrupted", label: messageLabel, duration: 2.0);
    }
    
    //Reset session tracking and clear previous session nodes
    func sessionInterruptionEnded(_ session: ARSession)
    {
        displayMessage("Resuming Session...", label: messageLabel, duration: 2.0);
        removeAllObjects();
        startARSession(resetSession: true);
    }
}


//MARK: ARKit Renderer Delegate Functions
extension ViewController
{
    // Catch Automatically generated ARPlaneAnchors and render a plane at their location.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        DispatchQueue.main.async
            {
                if let planeAnchor = anchor as? ARPlaneAnchor
                {
                    #if DEBUG
                        let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent);
                        node.addChildNode(planeNode);
                    #endif
                }
                //Model added through touch input (ARAnchor)
                else
                {
                    //Current UI State
                    switch self.currentFunctionState
                    {
                    //Add Ship to Scene
                    case .placingObject(let modelName):
                        let modelClone = nodeWithModelName(modelName);
                        self.objects.append(modelClone);
                        node.addChildNode(modelClone);
                    //If Measuring Tool is selected...
                    case .measuring:
                        let sphereNode = createSphereNode(radius: 0.025);
                        self.objects.append(sphereNode);
                        node.addChildNode(sphereNode);
                        self.measuringNodes.append(node);
                    case .none:
                        break;
                    }
                }
        }
    }
    
    // Updates Debug Planes orientation.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
    {
        DispatchQueue.main.async
            {
                if let planeAnchor = anchor as? ARPlaneAnchor
                {
                    updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent);
                }
                else
                {
                    self.updateMeasuringNodes();
                }
        }
    }
    
    // Update called each frame
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        DispatchQueue.main.async
            {
                self.updateTrackingInfo();
                
                //High Quality Hit due to using existing plane.
                if let _ = self.sceneView.hitTest(self.viewCenterPoint, types: [.existingPlaneUsingExtent]).first
                {
                    self.reticleView.backgroundColor = UIColor.green;
                }
                //Low Quality Hit due to using feature point.
                else
                {
                    self.reticleView.backgroundColor = UIColor.gray;
                }
        }
    }
    
    // Removes a Plane from Scene
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor)
    {
        guard anchor is ARPlaneAnchor else { return; }
        
        removeChildren(inNode: node);
    }
}

//MARK: ARKit Helper Functions
extension ViewController
{
    private func startARSession(resetSession: Bool = false)
    {
        sceneView.delegate = self;
        
        let sessionConfiguration = ARWorldTrackingConfiguration();
        sessionConfiguration.planeDetection = .horizontal;
        sessionConfiguration.isLightEstimationEnabled = true;
        
        if resetSession
        {
            sceneView.session.run(sessionConfiguration, options: [ARSession.RunOptions.removeExistingAnchors, ARSession.RunOptions.resetTracking]);
        }
        else
        {
            sceneView.session.run(sessionConfiguration, options: []);
        }
        
        #if DEBUG
            sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints;
        #endif
    }
    
    func updateTrackingInfo()
    {
        guard let frame = sceneView.session.currentFrame else { return; }
        
        switch frame.camera.trackingState
        {
        case .normal:
            trackingStateLabel.text = "";
        case .notAvailable:
            trackingStateLabel.text = "No Tracking Data";
        case .limited(let reason):
            switch reason
            {
            case .excessiveMotion:
                trackingStateLabel.text = "Limited Tracking: Excessive Motion";
            case .insufficientFeatures:
                trackingStateLabel.text = "Limited Tracking: Insufficient Lighting";
            case .initializing:
                trackingStateLabel.text = "Initializing...";
            }
        }
    }
}


//MARK: Measuring Tool Functionality
extension ViewController
{
    func measure(fromNode: SCNNode, toNode: SCNNode)
    {
        let measuringLineNode = createLineNode(fromNode: fromNode, toNode: toNode);
        
        measuringLineNode.name = "Measuring Line";
        
        sceneView.scene.rootNode.addChildNode(measuringLineNode);
        objects.append(measuringLineNode);
        
        let distance = fromNode.position.distanceTo(toNode.position);
        
        let measurementValue = String(format: "%.2f", distance);
        
        distanceLabel.text = "Distance: \(measurementValue) meters.";
    }
    
    func updateMeasuringNodes()
    {
        guard measuringNodes.count > 1 else { return; }
        
        switch currentFunctionState
        {
        case .measuring:
            let firstNode = measuringNodes[0];
            let secondNode = measuringNodes[1];
            
            //Remove old measurement nodes and the measuring line node.
            if measuringNodes.count > 2
            {
                firstNode.removeFromParentNode();
                secondNode.removeFromParentNode();
                measuringNodes.removeFirst(2);
                
                for node in sceneView.scene.rootNode.childNodes
                {
                    if node.name == "Measuring Line"
                    {
                        node.removeFromParentNode();
                    }
                }
            }
            
            let showMeasuring = self.measuringNodes.count == 2;
            distanceLabel.isHidden = !showMeasuring;
            
            //Update meters and show on UI
            if showMeasuring
            {
                measure(fromNode: firstNode, toNode: secondNode);
            }
        default:
            return;
        }
    }
}


//MARK: UI Helper Functions + (IBActions)
extension ViewController
{
    @IBAction func addObjectButtonPressed(_ sender: Any)
    {
        currentFunctionState = .placingObject("models.scnassets/candle/candle.scn");
        selectButton(addObjectButton);
    }
    
     @IBAction func addChairButtonPressed(_ sender: Any)
     {
        currentFunctionState = .placingObject("models.scnassets/chair/chair.scn");
        selectButton(addChairButton);
    }
    
    @IBAction func measuringToolButtonPressed(_ sender: Any)
    {
        currentFunctionState = .measuring;
        selectButton(measureToolButton);
    }
    
    @IBAction func refreshSessionButtonPressed(_ sender: Any)
    {
        removeAllObjects();
        currentFunctionState = .none;
        distanceLabel.text = "";
        //startARSession(resetSession: true);
    }
    
    private func selectButton(_ button: UIButton)
    {
        deselectAllButtons();
        button.isSelected = true;
    }
    private func deselectAllButtons()
    {
        [addObjectButton, addChairButton, measureToolButton, resetSessionButton].forEach
            {
                $0?.isSelected = false;
            }
    }
    
    // Touch Input
    // Add new anchor at a HitScanned point from the viewCenter to either a plane or the furthest away feature point.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        //Add ARAnchor to existing Plane
        if let hit = sceneView.hitTest(viewCenterPoint, types: [.existingPlaneUsingExtent]).first
        {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform));
            return;
        }
        //Add Anchor to furthest away feature point.
        else if let hit = sceneView.hitTest(viewCenterPoint, types: [.featurePoint]).last
        {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform));
        }
    }
}


//MARK: ViewController Helper Functions
extension ViewController
{
    private func initUIElems()
    {
        trackingStateLabel.text = "";
        messageLabel.text = "";
        distanceLabel.text = "";
        distanceLabel.isHidden = true;
    }
}


//MARK: SceneKit Helper Functions
extension ViewController
{
    private func removeAllObjects()
    {
        for object in objects
        {
            object.removeFromParentNode();
        }
        objects = [];
    }
}
