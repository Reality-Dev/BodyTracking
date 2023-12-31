
import RealityKit
import ARKit
import BTShared
import UIKit
import RKUtilities


// You can track as many hands as you want, or set the maximumHandCount of HandDetector's handPoseRequest.
public class HandTracker2D: HasHand2D, Identifiable {
    
    public typealias HandJointName = Hand2DComponent.HandJointName
    
    public var hand2D: Hand2DComponent
    
    public internal(set) var id = UUID()
    
    ///The frequency that the Vision request for detecting hands will be performed.
    ///
    ///Running the request every frame may decrease performance.
    ///Can be reduced to increase performance at the cost of choppy tracking.
    ///Set to half to run every other frame. Set to quarter to run every 1 out of 4 frames.
    ///Note: If multiple objects using hand tracking are used simultaneously, then the highest requestRate of any of them will be used for all of them.
    public static var requestRate: FrameRateRegulator.RequestRate {
        get {
            return HandDetector.shared.frameRateRegulator.requestRate
        }
        set {
            HandDetector.shared.frameRateRegulator.requestRate = newValue
        }
    }
    
    // 21 total.
    public static let allHandJoints : Set<HandJointName> = [
        .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
        .indexTip, .indexDIP, .indexPIP, .indexMCP,
        .middleTip, .middleDIP, .middlePIP, .middleMCP,
        .ringTip, .ringDIP, .ringPIP, .ringMCP,
        .littleTip, .littleDIP, .littlePIP, .littleMCP,
        .wrist
    ]

    public required init(arView: ARView,
                         confidenceThreshold: Float = 0.4) {
        
        hand2D = .init(confidenceThreshold: confidenceThreshold)

        Hand2DSystem.registerSystem(with: arView)
        
        Hand2DSystem.participatingTrackers.append(self)
        
        self.populateJointPositions()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {

        hand2D.jointScreenPositions = [:]
        
        hand2D.trackedViews.forEach { view in
            view.value.removeFromSuperview()
        }
        
        hand2D.trackedViews.removeAll()
        
        Hand2DSystem.participatingTrackers.removeAll(where: {$0 == self})
    }
    

    private func populateJointPositions() {
        hand2D.jointScreenPositions = [:]
        
        hand2D.jointAVFoundationPositions = [:]

        for joint in HandTracker2D.allHandJoints {
            hand2D.jointScreenPositions[joint] = CGPoint()
            hand2D.jointAVFoundationPositions[joint] = CGPoint()
        }
    }
    
    public func setConfidenceThreshold(_ newValue: Float) {
        hand2D.confidenceThreshold = newValue
    }
    
    ///Allows only one view per joint.
    ///- This will add `thisView` to ARView automatically.
    ///- If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(thisView: UIView, toThisJoint thisJoint: HandJointName){
        guard let arView = Hand2DSystem.arView else {return}
        
        hand2D.trackedViews[thisJoint] = thisView
        
        if thisView.superview == nil {
            arView.addSubview(thisView)
        }
    }
    
    public func removeJoint(_ joint: HandJointName) {
        
        hand2D.trackedViews[joint]?.removeFromSuperview()
        
        hand2D.trackedViews.removeValue(forKey: joint)
    }
}

extension HandTracker2D: Equatable {
    public static func == (lhs: HandTracker2D, rhs: HandTracker2D) -> Bool {
        return lhs.id == rhs.id
    }
}
