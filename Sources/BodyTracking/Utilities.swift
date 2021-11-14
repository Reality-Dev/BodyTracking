//
//  Utilities.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 11/13/21.
//

import simd
import UIKit

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
extension Comparable {
    
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
