//
//  BodyTrackedEntity+Extension.swift
//  BodyEntity-Example
//
//  Created by Grant Jarvis on 5/2/21.
//


import RealityKit
import Combine
public extension BodyTrackedEntity {
    
    
    /// Asynchronously loads the 3D character.
    ///
    /// Asynchronous loading prevents our app from freezing while waiting for the loading task to complete.
    /// See the example project in ARSUIViewBodyTrackedEntity for an example of how to use this.
    /// - Parameters:
    ///   - name: The name of the usdz file in the main bundle.
    ///   - completionHandler: The code to run once the BodyTrackedEntity is done loading. The BodyTrackedEntity is passed in as a parameter.
    class func loadCharacterAsync(named name: String, completionHandler: @escaping ((_ character: BodyTrackedEntity) -> Void)){
        var myCancellable: AnyCancellable? = nil
        myCancellable = Entity.loadBodyTrackedAsync(named: name).sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                myCancellable?.cancel()
        },
            receiveValue: { bodyTrackedEntity in
                completionHandler(bodyTrackedEntity)
                myCancellable?.cancel()
            })
    }
    
    
    
    
}
