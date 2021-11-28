
import RealityKit
import Combine
import ARKit
import UIKit


public extension ARView {
    
    //To learn more about face tracking:
    //https://developer.apple.com/documentation/arkit/arfacetrackingconfiguration
    /*
    "Because face tracking provides your app with personal facial information, your app must include a privacy policy describing to users how you intend to use face tracking and face data. For details, see the Apple Developer Program License Agreement."
    */
    
    
    func runFaceTrackingConfig() throws {
        
        // If the iOS device doesn't support face tracking, raise an error.
        guard ARFaceTrackingConfiguration.isSupported
        else {
            showAlert(title: "Uh oh...", message: "This device does Not support face tracking.")
            let errorMessage = "This device does Not support face tracking. This feature is only supported on devices with an A12 chip."
            print(errorMessage)
            throw BodyTrackingError.runtimeError(errorMessage)
        }
        
        let config3D = ARFaceTrackingConfiguration()
        self.session.run(config3D)
    }
}


public class FaceEntity: Entity, HasAnchoring {
    weak var arView : ARView!

    
    private var cancellableForUpdate : Cancellable?

    ///SCNMorpher can be used with blendshapes for Memoji type effects.
    ///There is even the option to use the front and back camera at the same time.
    public var blendShapes = [ARFaceAnchor.BlendShapeLocation : Float]()
    
    public var rEyeTransform: simd_float4x4?
    public var lEyeTransform: simd_float4x4?

    
    public required init(arView: ARView) {
        self.arView = arView
        super.init()
        //This will automatically attach this entity to the face.
        self.anchoring = AnchoringComponent(.face)
        self.arView.scene.addAnchor(self)
        self.subscribeToUpdates()
    }


    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    /// Destroy this Entity and its references to any ARViews
    /// Without calling this, you could have a memory leak.
    public func destroy() {
      self.arView = nil
      for child in children {
        child.removeFromParent()
      }
        self.cancellableForUpdate = nil
        self.blendShapes = [:]
      self.removeFromParent()
    }
    
    
    
    
    //Subscribe to scene updates so we can run code every frame without a delegate.
    private func subscribeToUpdates(){
        self.cancellableForUpdate = self.arView.scene.subscribe(to: SceneEvents.Update.self, updateFace)
    }
    
    
    
    
    //Run this code every frame to get the joints.
    public func updateFace(event: SceneEvents.Update? = nil) {
        guard let faceAnchor = self.arView.session.currentFrame?.anchors.first(where: {$0 is ARFaceAnchor}) as? ARFaceAnchor else {return}
        rEyeTransform = faceAnchor.rightEyeTransform
        lEyeTransform = faceAnchor.leftEyeTransform
        for blendShape in faceAnchor.blendShapes {
            self.blendShapes[blendShape.key] = blendShape.value as? Float
        }
    }
    

}


