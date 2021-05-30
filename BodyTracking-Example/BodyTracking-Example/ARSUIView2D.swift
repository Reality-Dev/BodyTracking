//
//  ARView.swift
//  Body Tracking
//
//  Created by Grant Jarvis on 3/25/21.
//

import ARKit
import RealityKit
//import BodyTracking

class ARSUIView2D: BodyARView {
    

    private var bodyEntity: BodyEntity2D!
    
    ///Use this to display the angle formed at this joint.
    ///See the call to "angleBetween3Joints" below.
    private var angleLabel: UILabel!
    

    // Track the screen dimensions:
    lazy var windowWidth: CGFloat = {
        return UIScreen.main.bounds.size.width
    }()
    
    lazy var windowHeight: CGFloat = {
        return UIScreen.main.bounds.size.height
    }()
    
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        self.bodyEntity = BodyEntity2D(arView: self)
        guard let _ = try? runBodyTrackingConfig2D() else { return }
        self.session.delegate = self
        
        makeRightElbowJointVisible()
        
        makeOtherJointsVisible()
    }
    
    
    ///This is an example for how to show one joint.
    private func makeRightElbowJointVisible(){
        
        let rightElbowCircle = makeCircle(circleRadius: 20)
        self.addSubview(rightElbowCircle)
        // ** HERE is the useful code: **
        //How to attach views to the skeleton:
        self.bodyEntity.attach(thisView: rightElbowCircle, toThisJoint: .right_forearm_joint)
        
        //Use this to display the angle formed at this joint.
        //See the call to "angleBetween3Joints" below.
        angleLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 50)))
        rightElbowCircle.addSubview(angleLabel)
    }
    
    
    ///This is an example for how to show multiple joints, iteratively.
    private func makeOtherJointsVisible(){
        //There are more joints you could attach views to, I'm just using these.
        let jointsToShow : [TwoDBodyJoints] = [.right_hand_joint, .right_shoulder_1_joint,
                                           .left_forearm_joint, .left_hand_joint,
                                           .left_shoulder_1_joint,
                                           .head_joint, .neck_1_joint,
                                           .root, .right_leg_joint,
                                           .right_foot_joint, .left_leg_joint,
                                           .left_foot_joint]
        
        //Another way to attach views to the skeletion, but iteratively this time:
        jointsToShow.forEach { joint in
            let circle = makeCircle(circleRadius: 20)
            self.bodyEntity.attach(thisView: circle, toThisJoint: joint)
            self.addSubview(circle)
        }
    }
    

    
    override func stopSession(){
        super.stopSession()
           self.bodyEntity.destroy()
            self.bodyEntity = nil
           self.angleLabel.removeFromSuperview()
       }
    
    
    private func makeCircle(circleRadius: CGFloat = 72,
                            color: CGColor = #colorLiteral(red: 0.3175252703, green: 0.7384468404, blue: 0.9564777644, alpha: 1)) -> UIView {
        
        // Place circle at the center of the screen to start.
        let xStart = floor((windowWidth - circleRadius) / 2)
        let yStart = floor((windowHeight - circleRadius) / 2)
        let frame = CGRect(x: xStart, y: yStart, width: circleRadius, height: circleRadius)
        
        let circleView = UIView(frame: frame)
        circleView.layer.cornerRadius = circleRadius / 2
        circleView.layer.backgroundColor = color
        return circleView
    }
    
    
    
    
    //required function.
    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ARSUIView2D: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        //The formatting rounds the number.
        if let jointAngle = self.bodyEntity.angleBetween3Joints(.right_hand_joint,
                                                                .right_forearm_joint,
                                                                .right_shoulder_1_joint) {
            self.angleLabel.text = String(format: "%.0f", Float(jointAngle))
        }
        
        //Uncomment to show the angle formed by 2 joints instead of by 3 joints.
//        if let jointAngle = self.bodyEntity.angleFrom2Joints(.right_forearm_joint, .right_shoulder_1_joint) {
//            self.angleLabel.text = String(format: "%.0f", Float(jointAngle))
//        }
    }
}


