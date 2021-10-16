
import RealityKit
import Combine
import ARKit
import UIKit
import Vision


//You can track as many hands as you want, or set the maximumHandCount of sampleBufferDelegate's handPoseRequest.
@available(iOS 14.0, *)
public class HandTrackedEntity {
    
    weak var arView : ARView!
    
    public typealias HandJointName = VNHumanHandPoseObservation.JointName
    
    private var cancellableForUpdate : Cancellable?
    
    private var sampleBufferDelegate : SampleBufferDelegate!
    
    private var frameInt = 0
    
    public required init(arView: ARView, confidenceThreshold: Float = 0.4) {
        self.arView = arView
        self.subscribeToUpdates()
        self.populateJointPositions()
        self.sampleBufferDelegate = SampleBufferDelegate(handTrackedEntity: self,
                                                         confidenceThreshold: confidenceThreshold)
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

    public var trackedViews = [HandJointName : UIView]()
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// Without calling this, you could have a memory leak.
    public func destroy() {
      self.arView = nil
        self.sampleBufferDelegate = nil
        self.cancellableForUpdate = nil
        self.jointScreenPositions = [:]
        self.trackedViews.forEach { view in
            view.value.removeFromSuperview()
        }
        self.trackedViews.removeAll()
    }
    
    
    
    
    //Subscribe to scene updates so we can run code every frame without a delegate.
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
    ///- If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(thisView: UIView, toThisJoint thisJoint: HandJointName){
        self.trackedViews[thisJoint] = thisView
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
        if frameInt == 4 {
            sampleBufferDelegate.runFingerDetection(frame: frame)
            frameInt = 0
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
                //Interpolate between where the view is and the target location.
                //We do not run the Vision request every frame, so we need to animate the view in between those frames.
                let viewCenter = view.value.center
                let difference = screenPosition - viewCenter
                    view.value.center = viewCenter + (difference  * 0.5)
            }
        }
    }
}





@available(iOS 14, *)
class SampleBufferDelegate {
    
    weak var handTrackedEntity: HandTrackedEntity!
    ///You can track as many hands as you want, or set the maximumHandCount
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    private var confidenceThreshold: Float!
    
    init(handTrackedEntity: HandTrackedEntity, confidenceThreshold: Float) {
        self.handTrackedEntity = handTrackedEntity
        self.confidenceThreshold = confidenceThreshold
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
                if handTrackedEntity.handIsRecognized == true {
                    handTrackedEntity.handIsRecognized = false
                }
                return
            }
            if handTrackedEntity.handIsRecognized == false {
                handTrackedEntity.handIsRecognized = true
            }
            // Get points for thumb and index finger.
            //let thumbPoints = try observation.recognizedPoints(.thumb)
            let fingerPoints = try observation.recognizedPoints(.all)

            for point in fingerPoints {
                guard point.value.confidence > confidenceThreshold else {continue}
                let cgPoint = CGPoint(x: point.value.x, y: point.value.y)
                let avPoint = convertVisionToAVFoundation(cgPoint)
                let screenSpacePoint = convertAVFoundationToScreenSpace(avPoint)
                handTrackedEntity.jointScreenPositions[point.key] = screenSpacePoint
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
        if let arView = handTrackedEntity.arView,
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
