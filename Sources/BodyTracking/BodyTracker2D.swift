
import RealityKit
import Combine
import CoreGraphics
import ARKit
import UIKit



public extension ARView {
    func runBodyTrackingConfig2D() throws {
        //This is more efficient if you are just using 2D and Not 3D tracking.
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.bodyDetection) else {
            let errorMessage = "This device does Not support body detection."
            print(errorMessage)
            throw BodyTrackingError.runtimeError(errorMessage)
        }
        let config2D = ARWorldTrackingConfiguration()
        config2D.frameSemantics = .bodyDetection
        self.session.run(config2D)
    }
}


public class BodyTracker2D {
    
    internal weak var arView : ARView!
    
    private var cancellableForUpdate : Cancellable?
    
    ///The positions of the joints on screen.
    ///
    /// - (0,0) is in the top-left.
    /// - Use the `rawValue` of a `TwoDBodyJoint` to index.
    public private(set) var jointScreenPositions : [CGPoint]!

    public private(set) var trackedViews = [TwoDBodyJoint : UIView]()
    
    ///True if a body is detected in the current frame.
    public private(set) var bodyIsDetected = false
    
    public required init(arView: ARView) {
        self.arView = arView
        self.subscribeToUpdates()
        self.populateJointPositions()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// This helps prevent memory leaks.
    public func destroy() {
      self.arView = nil
        self.cancellableForUpdate = nil
        self.jointScreenPositions = []
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
        jointScreenPositions = []
        for _ in 0...16 {
            jointScreenPositions.append(CGPoint())
        }
    }
    
    ///Allows only one view per joint.
    ///- This will add `thisView` to ARView automatically.
    ///- If you would like to attach more than one view per joint, then try attaching additional views to the view that is already attached to this joint.
    public func attach(thisView: UIView, toThisJoint thisJoint: TwoDBodyJoint){
        self.trackedViews[thisJoint] = thisView
        if thisView.superview == nil {
            arView.addSubview(thisView)
        }
    }
    
    public func removeJoint(_ joint: TwoDBodyJoint){
        self.trackedViews[joint]?.removeFromSuperview()
        self.trackedViews.removeValue(forKey: joint)
    }
    
    //Run this code every frame to get the joints.
    public func updateBody(event: SceneEvents.Update? = nil) {
        guard
            let frame = self.arView.session.currentFrame
        else {return}
        updateJointScreenPositions(frame: frame)
        updateTrackedViews(frame: frame)

    }
    
    private func updateJointScreenPositions(frame: ARFrame){
        guard let detectedBody = frame.detectedBody else {
            if bodyIsDetected == true {bodyIsDetected = false}
            return
        }
        if bodyIsDetected == false {bodyIsDetected = true}
        
        guard
            let interfaceOrientation = self.arView.window?.windowScene?.interfaceOrientation
        else { return }
        
        let jointLandmarks = detectedBody.skeleton.jointLandmarks
        
        //Convert the normalized joint points into screen-space CGPoints.
        let transform = frame.displayTransform(for: interfaceOrientation, viewportSize: self.arView.frame.size)
        for i in 0..<jointLandmarks.count {
                if jointLandmarks[i].x.isNaN || jointLandmarks[i].y.isNaN {
                    continue
                }
                let point = CGPoint(x: CGFloat(jointLandmarks[i].x),
                                               y: CGFloat(jointLandmarks[i].y))
                //Convert from normalized pixel coordinates (0,0 top-left, 1,1 bottom-right)
                //to screen-space coordinates.
                let normalizedCenter = point.applying(transform)
            let center = normalizedCenter.applying(CGAffineTransform.identity.scaledBy(x: self.arView.frame.width, y: self.arView.frame.height))
            self.jointScreenPositions[i] = center
        }
    }
    
    func updateTrackedViews(frame: ARFrame){
        guard frame.detectedBody != nil,
              jointScreenPositions.count > 0
        else {return}
        
        for view in trackedViews {
            let jointIndex = view.key.rawValue
            let screenPosition = jointScreenPositions[jointIndex]
            view.value.center = screenPosition
        }
    }

    ///Returns the angle (in degrees) between 3 given joints, treating joint2 as the center point.
    /// - The maximum angle is 180.0°
    /// - See "ARView2D.swift" for an example usage.
    public func angleBetween3Joints(_ joint1: TwoDBodyJoint,
                                   _ joint2: TwoDBodyJoint,
                                   _ joint3: TwoDBodyJoint) -> CGFloat? {
        let joint1Index = joint1.rawValue
        let joint2Index = joint2.rawValue
        let joint3Index = joint3.rawValue
        
        //Make sure the joints we are looking for are included in jointScreenPositions.
        guard let maxIndex = [joint1Index, joint2Index, joint3Index].max(),
              (jointScreenPositions.count - 1) >= maxIndex else { return nil }
        
        let joint1ScreenPosition = jointScreenPositions[joint1Index]
        let joint2ScreenPosition = jointScreenPositions[joint2Index]
        let joint3ScreenPosition = jointScreenPositions[joint3Index]
        
        let vect1 = (joint1ScreenPosition - joint2ScreenPosition).simdVect()
        let vect2 = (joint3ScreenPosition - joint2ScreenPosition).simdVect()
        
        let top = dot(vect1, vect2)
        let bottom = length(vect1) * length(vect2)
        let angleInRadians = CGFloat(acos(top / bottom))
        let angleInDegrees = (angleInRadians * 180) / .pi
        return angleInDegrees
    }
    

    ///
    /// Returns the angle (in degrees) between down and the vector formed by the two given points.
    /// - In the UIKit coordinate system, (0,0) is in the top-left corner.
    /// - See "ARView2D.swift" for an example usage.
    /// - Returns: A vector pointing straight down returns 0.0.
    ///A vector pointing to the right returns 270.0.
    ///A vector pointing up returns 180.0.
    ///A vector pointing to the left returns 90.0.
    public func angleFrom2Joints(_ joint1: TwoDBodyJoint,
                                 _ joint2: TwoDBodyJoint) -> CGFloat? {
        let joint1Index = joint1.rawValue
        let joint2Index = joint2.rawValue
        
        //Make sure the joints we are looking for are included in jointScreenPositions.
        guard (jointScreenPositions.count - 1) >= max(joint1Index, joint2Index) else { return nil }
        
        let joint1ScreenPosition = jointScreenPositions[joint1Index]
        let joint2ScreenPosition = jointScreenPositions[joint2Index]

        return angleBetween2Points(point1: joint1ScreenPosition,
                                         point2: joint2ScreenPosition)
    }
    
    private func angleBetween2Points(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let difference = point1 - point2
        let angleInRadians = atan2(difference.y, difference.x)
        var angleInDegrees = GLKMathRadiansToDegrees(Float(angleInRadians))
        angleInDegrees -= 90
        if (angleInDegrees < 0) { angleInDegrees += 360.0 }
        return CGFloat(angleInDegrees)
    }

    
}

public extension CGPoint {

    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
    
    func simdVect() -> simd_float2 {
        return simd_float2(Float(self.x), Float(self.y))
    }
    
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
    
    static func midPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }

    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint{
        return CGPoint(x: lhs.x - rhs.x,
                       y: lhs.y - rhs.y)
    }
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint{
        return CGPoint(x: lhs.x + rhs.x,
                       y: lhs.y + rhs.y)
    }
    
    static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint{
        return CGPoint(x: lhs.x * rhs,
                       y: lhs.y * rhs)
    }
    static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint{
        return CGPoint(x: lhs.x / rhs,
                       y: lhs.y / rhs)
    }

}


///ARSkeleton.JointName only contains 8 of these but this includes all of them :)
///
///Includes 17 joints.
///- Use TwoDBodyJoint.allCases to access an array of all joints
public enum TwoDBodyJoint: Int, CaseIterable {
    case head_joint = 0
    case neck_1_joint = 1
    case right_shoulder_1_joint = 2
    case right_forearm_joint = 3
    case right_hand_joint = 4
    case left_shoulder_1_joint = 5
    case left_forearm_joint = 6
    case left_hand_joint = 7
    case right_upLeg_joint = 8
    case right_leg_joint = 9
    case right_foot_joint = 10
    case left_upLeg_joint = 11
    case left_leg_joint = 12
    case left_foot_joint = 13
    case right_eye_joint = 14
    case left_eye_joint = 15
    case root = 16 //hips
}

