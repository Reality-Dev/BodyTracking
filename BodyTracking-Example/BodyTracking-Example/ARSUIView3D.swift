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
        self.bodyEntity = BodyEntity3D(arView: self,
                                       smoothingAmount: 0.7)
        
        do { try runBodyTrackingConfig3D() }
        catch BodyTrackingError.runtimeError(let errorMessage) {print(errorMessage); return}
        catch {}
        
        //Another way you can call runBodyTrackingConfig3D:
        //guard let _ = try? runBodyTrackingConfig3D() else { return }

        
        makeTrackedJointsVisible()
    }
    
    
    ///This is an example for how to show one joint.
    private func makeRightHandVisible(){
        let rightHandSphere = Entity.makeSphere(radius: 0.05)
        // ** HERE is the useful code: **
        //How to attach entities to the skeleton:
        bodyEntity.attach(thisEntity: rightHandSphere, toThisJoint: .right_hand_joint)
    }
    
    ///This is an example for how to show multiple joints, iteratively.
    private func makeTrackedJointsVisible(){
        //There are more joints you could attach entities to, I'm just using these.
        //Another way to attach entities to the skeletion, but iteratively this time:
        ThreeDBodyJoint.trackedJoints.forEach { joint in
            let sphere = Entity.makeSphere(radius: 0.05)
            bodyEntity.attach(thisEntity: sphere, toThisJoint: joint)
        }
    }
    

    override func stopSession(){
            super.stopSession()
            DataModel.shared.arView = nil
            self.bodyEntity.destroy()
            self.bodyEntity = nil
    }
    
    deinit {
        self.stopSession()
    }
    
    
    //required function.
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
