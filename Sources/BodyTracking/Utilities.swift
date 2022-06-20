//
//  Utilities.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 11/13/21.
//

import simd
import UIKit
import RealityKit

public extension Entity {
    
    static func makeSphere(color: UIColor = .blue,
                            radius: Float = 0.15,
                            isMetallic: Bool = true) -> ModelEntity {
        
        let sphereMesh = MeshResource.generateSphere(radius: radius)
        let sphereMaterial = SimpleMaterial.init(color: color, isMetallic: isMetallic)
        return ModelEntity(mesh: sphereMesh,
                           materials: [sphereMaterial])
    }
    
    ///Recursively searches through all descendants (depth first) for an Entity that satisfies the given predicate, Not just through the direct children.
    func findEntity(where predicate: (Entity) -> Bool) -> Entity? {
        for child in self.children {
            if predicate(child) { return child }
            else if let satisfier = child.findEntity(where: predicate) {return satisfier}
        }
        return nil
    }
    
    ///Recursively searches through all descendants (depth first) for a ModelEntity, Not just through the direct children.
    ///Reutrns the first model entity it finds.
    ///Returns the input entity if it is a model entity.
    func findModelEntity() -> ModelEntity? {
        if self is ModelEntity { return self as? ModelEntity }
        return self.findEntity(where: {$0 is ModelEntity}) as? ModelEntity
    }
}

public extension UIView {
    func showAlert(title: String, message: String){
        guard UIApplication.shared.windows.count == 1 else { return}
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        //arView.window is nil the way we have set up this example project.
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

public extension simd_float3 {
    func smoothed(oldVal: simd_float3, amount smoothingAmount: Float) -> simd_float3 {
        let smoothingAmount = smoothingAmount.clamped(0, 1)
        return (oldVal * smoothingAmount) + (self * ( 1 - smoothingAmount))
    }
}


import simd
public extension float4x4 {
  var translation: SIMD3<Float> {
    get {
      let translation = columns.3
      return SIMD3<Float>(translation.x, translation.y, translation.z)
    }
  }
    
    mutating func setTranslation(_ newVal: simd_float3) {
        columns.3 = [newVal.x, newVal.y, newVal.z, columns.3.w]
    }
    
    var orientation: simd_quatf {
      return simd_quaternion(self)
    }
}

// MARK: - Comparable extensions
public extension Comparable {
    
    /// Returns self clamped between two values.
    /// - If self is already between the two input values, returns self. If self is below a, returns a. If self is above b, returns b.
    /// - Parameters:
    ///   - a: The lower bound
    ///   - b: The upper bound.
    /// - Returns: self clamped between the two input values.
    func clamped(_ a: Self, _ b: Self) -> Self {
        min(max(self, a), b)
    }
}



//  Created by Vladislav Grigoryev on 27.05.2020.
//  Copyright © 2020 GORA Studio. https://gora.studio
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

@propertyWrapper
struct WeakCollection<Value: AnyObject> {

  private var _wrappedValue: [Weak<Value>]

  var wrappedValue: [Value] {
    get { _wrappedValue.lazy.compactMap { $0.get() } }
    set { _wrappedValue = newValue.map(Weak.init) }
  }

  init(wrappedValue: [Value]) { self._wrappedValue = wrappedValue.map(Weak.init) }

  mutating func compact() { _wrappedValue = { _wrappedValue }() }
}

@propertyWrapper
final class Weak<Object: AnyObject> {

  private weak var _wrappedValue: AnyObject?

  var wrappedValue: Object? {
    get { _wrappedValue as? Object }
    set { _wrappedValue = newValue }
  }

  init(_ object: Object) { self._wrappedValue = object }

  init(wrappedValue: Object?) { self._wrappedValue = wrappedValue }

  func get() -> Object? { wrappedValue }
}
