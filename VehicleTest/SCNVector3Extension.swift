//
//  SCNVector3Extension.swift
//  SwiftSceneKitVehicleDemo
//
//  Created by Matteo Cocon on 18/01/15.
//  Copyright (c) 2015 Matteo Cocon. All rights reserved.
//

import SceneKit

extension SCNVector3 {
    
    mutating func normalize() {
        self = self / length()
    }
    
    func length() -> Float {
        return sqrtf((self.x * self.x) + (self.y * self.y) + (self.z * self.z))
    }
    
    func crossProduct(other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            x: (self.y * other.z) - (self.z * other.y),
            y: (self.z * other.x) - (self.x * other.z),
            z: (self.x * other.y) - (self.y * other.x))
    }
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func += (inout left: SCNVector3, right: SCNVector3) {
    left = left + right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3(x: left.x / right, y: left.y / right, z: left.z / right)
}


/*  
*   vector_mix(x,y,t)
*   If t is not in the range [0,1], the result is
*   undefined.  Otherwise the result is x+(y-x)*t,
*   which linearly interpolates between x and y.
*/
func vector_mix( camPos:SCNVector3, targetPos:SCNVector3, cameraDamping:Float)->SCNVector3{
    var _cameraDamping = Float(0)
    if( cameraDamping < 0 ){
        _cameraDamping = 0
    } else if (cameraDamping > 1) {
        _cameraDamping = 1
    } else {
        _cameraDamping = cameraDamping
    }
    let retValueX = camPos.x * (1.0 - _cameraDamping) + targetPos.x * _cameraDamping
    let retValueY = camPos.y * (1.0 - _cameraDamping) + targetPos.y * _cameraDamping
    let retValueZ = camPos.z * (1.0 - _cameraDamping) + targetPos.z * _cameraDamping
    return SCNVector3Make(retValueX, retValueY, retValueZ)
}