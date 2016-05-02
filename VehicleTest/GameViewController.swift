//
//  GameViewController.swift
//  VehicleTest
//
//  Created by Oliver Dew on 22/04/2016.
//  Copyright (c) 2016 Salt Pig. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import ModelIO
import GLKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var cockpitCameraNode: SCNNode!
    var shoulderCameraNode: SCNNode!
    var vehicleNode: SCNNode!
    var vehicle: SCNPhysicsVehicle!
    var touchCount:Int = 0
    let motionManager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        setupDeviceMotion()
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        scnView.showsStatistics = true
        //scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.delegate = self
        scnView.playing = true
        
        // add a tap gesture recognizer
        //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GameViewController.handleTap(_:)))
        //scnView.addGestureRecognizer(tapGesture)
    }
    
    func setupScene() {
        scnScene = SCNScene(named: "art.scnassets/Level1.scn")
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
        let skyBox = MDLSkyCubeTexture(name: nil, channelEncoding: MDLTextureChannelEncoding.UInt8,
                                       textureDimensions: [Int32(160), Int32(160)], turbidity: 0.8, sunElevation: 0.55, upperAtmosphereScattering: 0.2, groundAlbedo: 2)
        scnScene.background.contents = skyBox.imageFromTexture()?.takeUnretainedValue() //160
        
        let concreteTexture = MDLTexture(named: "art.scnassets/concrete.png")!
        let concreteNormalMap = MDLNormalMapTexture(byGeneratingNormalMapWithTexture: concreteTexture, name: nil, smoothness: 0, contrast: 3.0)
        let floor = scnScene.rootNode.childNodeWithName("floor", recursively: true)!
        let floorMaterial = SCNMaterial()
        floorMaterial.lightingModelName = SCNLightingModelPhong
        floorMaterial.shininess = 0.1
        floorMaterial.normal.contents = concreteNormalMap.imageFromTexture()?.takeUnretainedValue()
        floorMaterial.normal.wrapS = SCNWrapMode.Repeat
        floorMaterial.normal.wrapT = SCNWrapMode.Repeat
        floorMaterial.normal.intensity = 1
        let transform = SCNMatrix4FromGLKMatrix4( GLKMatrix4MakeScale(2, 2, 2) )
        floorMaterial.normal.contentsTransform = transform
        floorMaterial.diffuse.contents = concreteTexture.imageFromTexture()?.takeUnretainedValue()
        floorMaterial.diffuse.wrapS = SCNWrapMode.Repeat
        floorMaterial.diffuse.wrapT = SCNWrapMode.Repeat
        floorMaterial.diffuse.contentsTransform = transform
        //floorMaterial.diffuse.
        floorMaterial.specular.contents = UIColor.whiteColor()
        floor.geometry?.firstMaterial = floorMaterial
        // retrieve the car node
        //carNode = scene.rootNode.childNodeWithName("ship", recursively: true)!
        vehicleNode = setupCar()
        
        // animate the 3d object
        //ship.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
    }
    
    func setupCamera() {
        cameraNode = scnScene.rootNode.childNodeWithName("camera", recursively: true)!
        let constraint = SCNLookAtConstraint(target: vehicleNode)
        constraint.gimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        
       // cockpitCameraNode = scnScene.rootNode.childNodeWithName("cockpitCamera", recursively: true)!
        //shoulderCameraNode = scnScene.rootNode.childNodeWithName("shoulderCamera", recursively: true)!
        
        scnView.pointOfView = cameraNode
        
        let lightNode = scnScene.rootNode.childNodeWithName("spotLight", recursively: true)!
        lightNode.constraints = [constraint]
//        cameraNode.camera = SCNCamera()
//        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
//        scnScene.rootNode.addChildNode(cameraNode)
        
        // create and add an ambient light to the scene
//        let ambientLightNode = SCNNode()
//        ambientLightNode.light = SCNLight()
//        ambientLightNode.light!.type = SCNLightTypeAmbient
//        ambientLightNode.light!.color = UIColor.darkGrayColor()
//        scnScene.rootNode.addChildNode(ambientLightNode)
    }
    
    func setupDeviceMotion() {
//        motionManager.accelerometerUpdateInterval = 1/60.0
//        motionManager.startAccelerometerUpdatesToQueue(
//            NSOperationQueue.mainQueue(),
//            withHandler: {
//                (accelerometerData: CMAccelerometerData!, error: NSError!) in
//                self.accelerometerDidChange(accelerometerData.acceleration)
//        })
        
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1/60.0
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
            [weak self] (data: CMDeviceMotion?, error: NSError?) in
            if let gravity = data?.gravity {
//            let rotation = atan2(acceleration.x, acceleration.y) - M_PI
//            self?.imageView.transform = CGAffineTransformMakeRotation(CGFloat(rotation))
                let _vehicleSteering = CGFloat(atan2(gravity.x, gravity.y) - M_PI * 0.5) // -M_PI for portrait
                self!.vehicle.setSteeringAngle(_vehicleSteering, forWheelAtIndex: 0)
                self!.vehicle.setSteeringAngle(_vehicleSteering, forWheelAtIndex: 1)
            }
            }
        }
    }
    
    func setupCar() -> SCNNode {
        let carScene = SCNScene(named: "art.scnassets/rc_car.scn") //rc_car.dae
        let chassisNode = carScene!.rootNode.childNodeWithName("rccarBody", recursively: false)!
        chassisNode.position = SCNVector3Make(0, 10, 30)
        //chassisNode.rotation = SCNVector4(0, 1, 0, CGFloat(M_PI))
        let body = SCNPhysicsBody.dynamicBody()
        body.allowsResting = false
        body.mass = 80
        body.restitution = 0.1
        body.friction = 0.5
        body.rollingFriction = 0
        chassisNode.physicsBody = body
        scnScene.rootNode.addChildNode(chassisNode)
 //getNode("rccarBody", fromDaePath: "rc_car.dae")
        let wheelnode0 = chassisNode
            .childNodeWithName("wheelLocator_FL", recursively: true)!
        let wheelnode1 = chassisNode
            .childNodeWithName("wheelLocator_FR", recursively: true)!
        let wheelnode2 = chassisNode
            .childNodeWithName("wheelLocator_RL", recursively: true)!
        let wheelnode3 = chassisNode
            .childNodeWithName("wheelLocator_RR", recursively: true)!
        
        //wheelnode0.geometry!.firstMaterial!.emission.contents = UIColor.blueColor()
//        SCNTransaction.begin()
//        wheelnode0.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(M_PI)) //CGFloat(M_PI)
//        wheelnode1.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(M_PI))
//        wheelnode2.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(M_PI))
//        wheelnode3.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(M_PI))
//        SCNTransaction.commit()
//        wheelnode0.eulerAngles = SCNVector3Make(0, Float(M_PI), 0 )
        let wheel0 = SCNPhysicsVehicleWheel(node: wheelnode0)
        let wheel1 = SCNPhysicsVehicleWheel(node: wheelnode1)
        let wheel2 = SCNPhysicsVehicleWheel(node: wheelnode2)
        let wheel3 = SCNPhysicsVehicleWheel(node: wheelnode3)
//        wheel0.steeringAxis = SCNVector3Make(0, -1, 1) //wheels point up in the air with 0,1,0
//        wheel1.steeringAxis = SCNVector3Make(0, -1, 1)
//        wheel2.steeringAxis = SCNVector3Make(0, -1, 1)
//        wheel3.steeringAxis = SCNVector3Make(0, -1, 1)
//        
//        wheel0.axle = SCNVector3(x: 1,y: 0,z: 0) //wheels face and spin the right way, but car moves in opposite direction with 1,0,0
//        wheel1.axle = SCNVector3(x: 1,y: 0,z: 0)
//        wheel2.axle = SCNVector3(x: 1,y: 0,z: 0)
//        wheel3.axle = SCNVector3(x: 1,y: 0,z: 0)
       // wheel0.steeringAxis = SCNVector3()
        var min = SCNVector3(x: 0, y: 0, z: 0)
        var max = SCNVector3(x: 0, y: 0, z: 0)
        wheelnode0.getBoundingBoxMin(&min, max: &max)
        let wheelHalfWidth = Float(0.5 * (max.x - min.x))
        var w0 = wheelnode0.convertPosition(SCNVector3Zero, toNode: chassisNode)
        w0 = w0 + SCNVector3Make(wheelHalfWidth * -5.4, wheelHalfWidth * 0.5, 0)
        wheel0.connectionPosition = w0
        var w1 = wheelnode1.convertPosition(SCNVector3Zero, toNode: chassisNode)
        w1 = w1 - SCNVector3Make(wheelHalfWidth * -5.4, -wheelHalfWidth, 0)
        wheel1.connectionPosition = w1
        var w2 = wheelnode2.convertPosition(SCNVector3Zero, toNode: chassisNode)
        w2 = w2 + SCNVector3Make(wheelHalfWidth * -5.4, wheelHalfWidth, 0)
        wheel2.connectionPosition = w2
        var w3 = wheelnode3.convertPosition(SCNVector3Zero, toNode: chassisNode)
        w3 = w3 - SCNVector3Make(wheelHalfWidth * -5.4, -wheelHalfWidth, 0)
        wheel3.connectionPosition = w3
        
        vehicle = SCNPhysicsVehicle(chassisBody: chassisNode.physicsBody!,
                                    wheels: [wheel1, wheel0, wheel3, wheel2])
        scnScene.physicsWorld.addBehavior(vehicle)
        return chassisNode
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let allTouches = event!.allTouches() {
            touchCount = allTouches.count
        } else {
            fatalError("unable to count number of touch on screen")
        }
//        let touch = touches.first!
//        let location = touch.locationInView(scnView)
//        let hitResults = scnView.hitTest(location, options: nil)
//        if hitResults.count > 0 {
//            let result = hitResults.first!
//            handleTouchFor(result.node)
//        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touchCount = 0 // reset touch counter
    }
    
//    func accelerometerDidChange(acceleration: CMAcceleration) {
//        
//        let kFilteringFactor = 0.5
//        accelerometer[0] = acceleration.x * kFilteringFactor +
//            accelerometer[0] * (1.0 - kFilteringFactor)
//        accelerometer[1] = acceleration.y * kFilteringFactor +
//            accelerometer[1] * (1.0 - kFilteringFactor)
//        accelerometer[2] = acceleration.z * kFilteringFactor +
//            accelerometer[2] * (1.0 - kFilteringFactor)
//        
//        let orientationModule = CGFloat(accelerometer[1] * 1.3)
//        
//        if(accelerometer[0] > 0) {
//            _orientation = orientationModule
//        } else {
//            _orientation = -orientationModule
//        }
//    }
//
//    func handleTap(gestureRecognize: UIGestureRecognizer) {
//        // retrieve the SCNView
//        let scnView = self.view as! SCNView
//        
//        // check what nodes are tapped
//        let p = gestureRecognize.locationInView(scnView)
//        let hitResults = scnView.hitTest(p, options: nil)
//        // check that we clicked on at least one object
//        if hitResults.count > 0 {
//            // retrieved the first clicked object
//            let result: AnyObject! = hitResults[0]
//            
//            // get its material
//            let material = result.node!.geometry!.firstMaterial!
//            
//            // highlight it
//            SCNTransaction.begin()
//            SCNTransaction.setAnimationDuration(0.5)
//            
//            // on completion - unhighlight
//            SCNTransaction.setCompletionBlock {
//                SCNTransaction.begin()
//                SCNTransaction.setAnimationDuration(0.5)
//                
//                material.emission.contents = UIColor.blackColor()
//                
//                SCNTransaction.commit()
//            }
//            
//            material.emission.contents = UIColor.redColor()
//            
//            SCNTransaction.commit()
//        }
//    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        let defaultEngineForce:CGFloat = 25
        var engineForce: CGFloat = 0
        let cameraDamping = Float(0.3)
        
        if (touchCount == 1) {
            engineForce = defaultEngineForce
        }
        vehicle.applyEngineForce(engineForce, forWheelAtIndex: 2)
        vehicle.applyEngineForce(engineForce, forWheelAtIndex: 3)
        
//        let carCam = shoulderCameraNode.presentationNode
//        let targetPos = carCam.convertPosition(carCam.position, toNode: scnScene.rootNode)
//        //let targetPos = SCNVector3Make(carCamPos.x, Float(30), Float(carCamPos.z + 25))
//        var cameraPos = cameraNode.position
//        cameraPos = vector_mix(cameraPos, targetPos: targetPos, cameraDamping: cameraDamping)
//        cameraNode.position = cameraPos
    }
}
