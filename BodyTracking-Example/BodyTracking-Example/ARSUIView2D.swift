//
//  ARView.swift
//  Body Tracking
//
//  Created by Grant Jarvis on 3/25/21.
//

import ARKit
import RealityKit
import BodyTracking

class ARSUIView2D: BodyARView {
    

    private var bodyTracker: BodyTracker2D!
    
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
        self.bodyTracker = BodyTracker2D(arView: self)
        guard let _ = try? runBodyTrackingConfig2D() else { return }
        self.session.delegate = self
        
        //makeRightElbowJointVisible()
        
        makeAllJointsVisible()
    }
    
    
    ///This is an example for how to show one joint.
    private func makeRightElbowJointVisible(){
        
        let rightElbowCircle = makeCircle(circleRadius: 20, color: .init(red: 0, green: 1, blue: 0, alpha: 1))
        // ** HERE is the useful code: **
        //How to attach views to the skeleton:
        self.bodyTracker.attach(thisView: rightElbowCircle, toThisJoint: .right_forearm_joint)
    }
    
    
    ///This is an example for how to show multiple joints, iteratively.
    private func makeAllJointsVisible(){
        //There are more joints you could attach views to, I'm just using these.
        var jointsToShow: [TwoDBodyJoint] = TwoDBodyJoint.allCases
        
        //Two new joints for the ears were added in iOS 16.0
        if #unavailable(iOS 16) {
            jointsToShow.removeLast(2)
        }
        
        //Another way to attach views to the skeletion, but iteratively this time:
        for (i, joint) in jointsToShow.enumerated() {
            
            let circle = makeCircle(circleRadius: 20, color: .init(red: CGFloat(i) / 19, green: CGFloat(i) / 19, blue: 1.0, alpha: 1.0))
            self.bodyTracker.attach(thisView: circle, toThisJoint: joint)
            
            //Add an angle label to the right_forearm_joint
            if i == 3 {
                //Use this to display the angle formed at this joint.
                //See the call to "angleBetween3Joints" below.
                angleLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 50)))
                circle.addSubview(angleLabel)
            }
        }
    }
    

    
    override func stopSession(){
        super.stopSession()
           self.bodyTracker.destroy()
            self.bodyTracker = nil
           self.angleLabel.removeFromSuperview()
       }
    
    deinit {
        self.stopSession()
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
    
    //For RealityKit 2 we should use a RealityKit System instead of this update function but that would be limited to devices running iOS 15.0+
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        //The formatting rounds the number.
        if let jointAngle = self.bodyTracker.angleBetween3Joints(.right_hand_joint,
                                                                .right_forearm_joint,
                                                                .right_shoulder_1_joint) {
            self.angleLabel.text = String(format: "%.0f", Float(jointAngle))
        }
        
        //Uncomment to show the angle formed by 2 joints instead of by 3 joints.
//        if let jointAngle = self.bodyTracker.angleFrom2Joints(.right_forearm_joint, .right_shoulder_1_joint) {
//            self.angleLabel.text = String(format: "%.0f", Float(jointAngle))
//        }
    }
}


