//
//  SCNMathHelper.swift
//  ARKitApp
//
//  Created by Steve Kerney on 8/7/17.
//  Copyright © 2017 d4rkz3r0. All rights reserved.
//

import SceneKit

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3
{
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

extension SCNVector3
{
    func length() -> Float { return sqrtf(x * x + y * y + z * z) }
    
    func distanceTo(_ vector: SCNVector3) -> Float
    {
        return SCNVector3(x: self.x - vector.x, y: self.y - vector.y, z: self.z - vector.z).length()
    }
}
