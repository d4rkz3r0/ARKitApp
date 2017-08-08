//
//  SCNNodeHelper.swift
//  ARKitApp
//
//  Created by Steve Kerney on 8/7/17.
//  Copyright © 2017 d4rkz3r0. All rights reserved.
//

import SceneKit
import ARKit

//Model Loading with SceneKit
func nodeWithModelName(_ modelName: String) -> SCNNode { return SCNScene(named: modelName)!.rootNode.clone(); }

//Plane Creation
func createPlaneNode(center: vector_float3, extent: vector_float3) -> SCNNode
{
    let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z));
    
    let planeMaterial = SCNMaterial();
    planeMaterial.diffuse.contents = UIColor.blue.withAlphaComponent(0.3);
    plane.materials = [planeMaterial];
    let planeNode = SCNNode(geometry: plane);
    planeNode.position = SCNVector3Make(center.x, 0, center.z);
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0);
    
    return planeNode;
}

//Update Plane with new orientation (Merging Planes)
func updatePlaneNode(_ node: SCNNode, center: vector_float3, extent: vector_float3)
{
    let geometry = node.geometry as! SCNPlane;
    
    geometry.width = CGFloat(extent.x);
    geometry.height = CGFloat(extent.z);
    node.position = SCNVector3Make(center.x, 0, center.z);
}

// MARK: Measuring Tool Funcs
//Sphere Endpoint Node Creation
func createSphereNode(radius: CGFloat) -> SCNNode
{
    let sphere = SCNSphere(radius:radius);
    sphere.firstMaterial?.diffuse.contents = UIColor.green;
    
    return SCNNode(geometry: sphere);
}

//Connecting Line Node Creation
func createLineNode(fromNode: SCNNode, toNode: SCNNode) -> SCNNode
{
    let indices: [Int32] = [0, 1];
    
    let source = SCNGeometrySource(vertices: [fromNode.position, toNode.position]);
    let element = SCNGeometryElement(indices: indices, primitiveType: .line);
    
    let line = SCNGeometry(sources: [source], elements: [element]);
    let lineNode = SCNNode(geometry: line);
    
    let planeMaterial = SCNMaterial();
    planeMaterial.diffuse.contents = UIColor.red;
    line.materials = [planeMaterial];
    
    return lineNode;
}

//Clear SceneKit Nodes
func removeChildren(inNode node: SCNNode)
{
    for node in node.childNodes
    {
        node.removeFromParentNode();
    }
}
