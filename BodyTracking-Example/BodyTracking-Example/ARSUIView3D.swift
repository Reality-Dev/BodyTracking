//
//  ARView.swift
//  Body Tracking
//
//  Created by Grant Jarvis on 3/25/21.
//

import ARKit
import RealityKit
//import BodyTracking

class ARSUIView3D: BodyARView {
    
    private var bodyEntity : BodyEntity3D!

    
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        self.bodyEntity = BodyEntity3D(arView: self)
        
        do { try runBodyTrackingConfig3D() }
        catch BodyTrackingError.runtimeError(let errorMessage) {print(errorMessage)}
        catch {}

        makeTrackedJointsVisible()
    }
    
    
    ///This is an example for how to show one joint.
    private func makeRightHandVisible(){
        let rightHandSphere = makeSphere(radius: 0.05)
        // ** HERE is the useful code: **
        //How to attach entities to the skeleton:
        bodyEntity.attach(thisEntity: rightHandSphere, toThisJoint: .right_hand_joint)
    }
    
    ///This is an example for how to show multiple joints, iteratively.
    private func makeTrackedJointsVisible(){
        //There are more joints you could attach entities to, I'm just using these.
        //Another way to attach entities to the skeletion, but iteratively this time:
        ThreeDBodyJoints.trackedJoints.forEach { joint in
            let sphere = makeSphere(radius: 0.05)
            bodyEntity.attach(thisEntity: sphere, toThisJoint: joint)
        }
    }
    

    override func stopSession(){
            super.stopSession()
            DataModel.shared.arView = nil
            self.bodyEntity.destroy()
            self.bodyEntity = nil
    }
    

    
    

    
    private func makeSphere(color: UIColor = .blue,
                            radius: Float = 0.15,
                            isMetallic: Bool = true) -> ModelEntity{
        
        let sphereMesh = MeshResource.generateSphere(radius: radius)
        let sphereMaterial = SimpleMaterial.init(color: color, isMetallic: isMetallic)
        return ModelEntity(mesh: sphereMesh,
                           materials: [sphereMaterial])
    }
    
    
    
    //required function.
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
