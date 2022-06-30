
import RealityKit
import ARKit
import UIKit
import Vision


public class FrameRateRegulator {
    public enum RequestRate: Int {
        case everyFrame = 1
        case half = 2
        case quarter = 4
    }
    
    ///The frequency that the Vision request for detecting hands will be performed.
    ///
    ///Running the request every frame may decrease performance.
    ///Can be reduced to increase performance at the cost of choppy tracking.
    ///Set to half to run every other frame. Set to quarter to run every 1 out of 4 frames.
    public var requestRate: RequestRate = .quarter
    
    private var frameInt = 1
    
    fileprivate func canContinue() -> Bool {
        if frameInt == self.requestRate.rawValue {
            frameInt = 1
            return true
            
        } else {
            frameInt += 1
            return false
        }
    }
}


//You can track as many hands as you want, or set the maximumHandCount of sampleBufferDelegate's handPoseRequest.
@available(iOS 14.0, *)
public class HandTracker2D {
    
    public var confidenceThreshold: Float!
    
    internal weak var arView : ARView?
    
    public typealias HandJointName = VNHumanHandPoseObservation.JointName
    
    internal var id = UUID()

    public required init(arView: ARView,
                         confidenceThreshold: Float = 0.4) {
        self.arView = arView
        self.confidenceThreshold = confidenceThreshold
        SampleBufferDelegate.shared.arView = arView
        self.populateJointPositions()
        
        HandTrackingSystem.registerSystem(arView: arView)
        HandTrackingSystem.trackedObjects.append(.twoD(self))
        SampleBufferDelegate.shared.handTrackers.append(self)
    }
    
    internal fileprivate(set) var handHasBeenInitiallyIdentified = false
    
    public fileprivate(set) var handIsRecognized = false
    
    ///Screen-space coordinates. These can be used with a UIKit view or ARView covering the entire screen.
    public fileprivate(set) var jointScreenPositions : [HandJointName : CGPoint]!
    
    ///Normalized pixel coordinates (0,0 top-left, 1,1 bottom-right)
    public fileprivate(set) var jointAVFoundationPositions : [HandJointName : CGPoint]!
    
    public static let allHandJoints : Set<HandJointName> = [
        .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
        .indexTip, .indexDIP, .indexPIP, .indexMCP,
        .middleTip, .middleDIP, .middlePIP, .middleMCP,
        .ringTip, .ringDIP, .ringPIP, .ringMCP,
        .littleTip, .littleDIP, .littlePIP, .littleMCP,
        .wrist
    ]

    public private(set) var trackedViews = [HandJointName : UIView]()
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
        self.arView = nil
        self.jointScreenPositions = [:]
        self.trackedViews.forEach { view in
            view.value.removeFromSuperview()
        }
        self.trackedViews.removeAll()
        
        if let trackedIndex = HandTrackingSystem.trackedObjects.firstIndex(where: {$0.id == self.id}){
            HandTrackingSystem.trackedObjects.remove(at: trackedIndex)
        }

        HandTrackingSystem.unRegisterSystem()
    }
    

    private func populateJointPositions() {
        jointScreenPositions = [:]
        jointAVFoundationPositions = [:]
        //21 total.
        for joint in Self.allHandJoints {
            jointScreenPositions[joint] = CGPoint()
            jointAVFoundationPositions[joint] = CGPoint()
        }
    }
    
    ///Allows only one view per joint.
    ///- This will add `thisView` to ARView automatically.
    ///- If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(thisView: UIView, toThisJoint thisJoint: HandJointName){
        guard let arView = arView else {return}
        
        self.trackedViews[thisJoint] = thisView
        if thisView.superview == nil {
            arView.addSubview(thisView)
        }
    }
    
    public func removeJoint(_ joint: HandJointName){
        self.trackedViews[joint]?.removeFromSuperview()
        self.trackedViews.removeValue(forKey: joint)
    }
    
    fileprivate func updateTrackedViews(frame: ARFrame){

        guard
              jointScreenPositions.count > 0
        else {return}
        
        for view in trackedViews {
            let jointIndex = view.key
            if let screenPosition = jointScreenPositions[jointIndex] {

                let viewCenter = view.value.center
                switch SampleBufferDelegate.shared.frameRateRegulator.requestRate {
                case .everyFrame:
                    view.value.center = screenPosition
                    
                //Interpolate between where the view is and the target location.
                //We do not run the Vision request every frame, so we need to animate the view in between those frames.
                case .half, .quarter:
                    let difference = screenPosition - viewCenter
                    view.value.center = viewCenter + (difference  * 0.5)
                }
            }
        }
    }
}



@available(iOS 14, *)
class SampleBufferDelegate {
    
    static var shared = SampleBufferDelegate()
    
    public var frameRateRegulator = FrameRateRegulator()
    
    internal weak var arView : ARView?
    
    @WeakCollection var handTrackers = [HandTracker2D]() {
        didSet {
            handPoseRequest.maximumHandCount = handTrackers.count
        }
    }
    
    ///You can track as many hands as you want, or set the maximumHandCount
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    init() {
        handPoseRequest.maximumHandCount = 1
    }
    
    
    //Run this code every frame to get the joints.
    func update() {
        guard
            let frame = self.arView?.session.currentFrame
        else {return}
        
        if frameRateRegulator.canContinue() {
            self.runFingerDetection(frame: frame)
        }
        
        for handTracker in self.handTrackers {
            
            handTracker.updateTrackedViews(frame: frame)
        }
    }
    
    func runFingerDetection(frame: ARFrame){
        //Run hand detection asynchronously to keep app from lagging.
        DispatchQueue.global().async { [weak self] in
            
        guard
            let self = self
        else {return}
        
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([self.handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observations = self.handPoseRequest.results, observations.isEmpty == false else {
                for handTracker in self.handTrackers {
                    if handTracker.handIsRecognized == true {
                        handTracker.handIsRecognized = false
                    }}
                return
            }

            let pairs = zip(observations, self.handTrackers)
            
            for (observation, handTracker) in pairs {

                let fingerPoints = try observation.recognizedPoints(.all)

                DispatchQueue.main.async {
                    var aboveConfidenceThreshold = false
                    
                    fingerPointsLoop: for point in fingerPoints {
                        
                        guard point.value.confidence > handTracker.confidenceThreshold else {continue fingerPointsLoop}
                        aboveConfidenceThreshold = true
                        
                        let cgPoint = CGPoint(x: point.value.x, y: point.value.y)
                        
                        let avPoint = cgPoint.convertVisionToAVFoundation()
                        handTracker.jointAVFoundationPositions[point.key] = avPoint
                        
                        let screenSpacePoint = handTracker.arView?.convertAVFoundationToScreenSpace(avPoint) ?? .zero
                        handTracker.jointScreenPositions[point.key] = screenSpacePoint
                    }

                    if !aboveConfidenceThreshold {
                        if handTracker.handIsRecognized == true {
                            handTracker.handIsRecognized = false
                    }} else {
                        if handTracker.handIsRecognized == false {
                            handTracker.handIsRecognized = true
                        }
                        if handTracker.handHasBeenInitiallyIdentified == false {
                            handTracker.handHasBeenInitiallyIdentified = true
                        }
                    }
                }
            }
            } catch {
                print(error)
            }
        }
    }
}
