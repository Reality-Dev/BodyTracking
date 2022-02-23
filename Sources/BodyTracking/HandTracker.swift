
import RealityKit
import Combine
import ARKit
import UIKit
import Vision


//You can track as many hands as you want, or set the maximumHandCount of sampleBufferDelegate's handPoseRequest.
@available(iOS 14.0, *)
public class HandTracker {
    
    internal weak var arView : ARView!
    
    public typealias HandJointName = VNHumanHandPoseObservation.JointName
    
    private var cancellableForUpdate : Cancellable?
    
    private var sampleBufferDelegate : SampleBufferDelegate!
    
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
    
    public required init(arView: ARView,
                         confidenceThreshold: Float = 0.4,
                         maximumHandCount: Int = 1) {
        self.arView = arView
        self.subscribeToUpdates()
        self.populateJointPositions()
        self.sampleBufferDelegate = SampleBufferDelegate(handTracker: self,
                                                         confidenceThreshold: confidenceThreshold,
                                                         maximumHandCount: maximumHandCount)
    }
    
    public fileprivate(set) var handIsRecognized = false
    
    public fileprivate(set) var jointScreenPositions : [HandJointName : CGPoint]!
    
    public let allHandJoints : Set<HandJointName> = [
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
        self.sampleBufferDelegate = nil
        self.cancellableForUpdate?.cancel()
        self.cancellableForUpdate = nil
        self.jointScreenPositions = [:]
        self.trackedViews.forEach { view in
            view.value.removeFromSuperview()
        }
        self.trackedViews.removeAll()
    }
    
    
    
    
    //Subscribe to scene updates so we can run code every frame without a delegate.
    //For RealityKit 2 we should use a RealityKit System instead of this update function but that would be limited to devices running iOS 15.0+
    private func subscribeToUpdates(){
        self.cancellableForUpdate = self.arView.scene.subscribe(to: SceneEvents.Update.self, updateBody)
    }
    
    private func populateJointPositions() {
        jointScreenPositions = [:]
        //21 total.
        for joint in allHandJoints {
            jointScreenPositions[joint] = CGPoint()
        }
    }
    
    ///Allows only one view per joint.
    ///- This will add `thisView` to ARView automatically.
    ///- If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(thisView: UIView, toThisJoint thisJoint: HandJointName){
        self.trackedViews[thisJoint] = thisView
        if thisView.superview == nil {
            arView.addSubview(thisView)
        }
    }
    
    public func removeJoint(_ joint: HandJointName){
        self.trackedViews[joint]?.removeFromSuperview()
        self.trackedViews.removeValue(forKey: joint)
    }
    
    //Run this code every frame to get the joints.
    private func updateBody(event: SceneEvents.Update? = nil) {
        guard
            let frame = self.arView.session.currentFrame
        else {return}
        
        //Another way to do it is to keep the buffer full until the request finishes and then set the buffer to nil and process the next request.
        if frameInt == self.requestRate.rawValue {
            sampleBufferDelegate.runFingerDetection(frame: frame)
            frameInt = 1
        } else {
            frameInt += 1
        }
        
        updateTrackedViews(frame: frame)

    }
    
    private func updateTrackedViews(frame: ARFrame){

        guard
              jointScreenPositions.count > 0
        else {return}
        
        for view in trackedViews {
            let jointIndex = view.key
            if let screenPosition = jointScreenPositions[jointIndex] {

                let viewCenter = view.value.center
                switch requestRate {
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
    
    weak var handTracker: HandTracker!
    ///You can track as many hands as you want, or set the maximumHandCount
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private var confidenceThreshold: Float!
    
    init(handTracker: HandTracker,
         confidenceThreshold: Float,
         maximumHandCount: Int) {
        self.handTracker = handTracker
        self.confidenceThreshold = confidenceThreshold
        handPoseRequest.maximumHandCount = maximumHandCount
    }
    
    func runFingerDetection(frame: ARFrame){
        //Run hand detection asynchronously to keep app from lagging.
        //DispatchQueue.main.async {
        
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .up, options: [:])
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
            guard let observation = handPoseRequest.results?.first else {
                if handTracker.handIsRecognized == true {
                    handTracker.handIsRecognized = false
                }
                return
            }
            if handTracker.handIsRecognized == false {
                handTracker.handIsRecognized = true
            }
            // Get points for thumb and index finger.
            //let thumbPoints = try observation.recognizedPoints(.thumb)
            let fingerPoints = try observation.recognizedPoints(.all)

            for point in fingerPoints {
                guard point.value.confidence > confidenceThreshold else {continue}
                let cgPoint = CGPoint(x: point.value.x, y: point.value.y)
                let avPoint = convertVisionToAVFoundation(cgPoint)
                let screenSpacePoint = convertAVFoundationToScreenSpace(avPoint)
                handTracker.jointScreenPositions[point.key] = screenSpacePoint
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func convertVisionToAVFoundation(_ inputPoint: CGPoint) -> CGPoint {
        return CGPoint(x: inputPoint.x, y: 1 - inputPoint.y)
    }
    
    private func convertAVFoundationToScreenSpace(_ point: CGPoint) -> CGPoint{
        //Convert from normalized pixel coordinates (0,0 top-left, 1,1 bottom-right)
        //to screen-space coordinates.
        if let arView = handTracker.arView,
           let frame = arView.session.currentFrame,
            let interfaceOrientation = arView.window?.windowScene?.interfaceOrientation{
            let transform = frame.displayTransform(for: interfaceOrientation, viewportSize: arView.frame.size)
            let normalizedCenter = point.applying(transform)
            let center = normalizedCenter.applying(CGAffineTransform.identity.scaledBy(x: arView.frame.width, y: arView.frame.height))
            return center
        } else {
            return CGPoint()
        }
    }
}
