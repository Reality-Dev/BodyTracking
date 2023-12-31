//
//  Utilities.swift
//  BodyTracking-Example
//
//  Created by Grant Jarvis on 11/13/21.
//

import simd
import UIKit
import RealityKit
import RKUtilities

//MARK: - UIView extension
public extension UIView {
    func showAlert(title: String, message: String) {

        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let mainWindow = windowScene.windows.first else {return}

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        //arView.window is nil the way we have set up this example project.
        mainWindow.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

//MARK: - Interpolation
func lerp(from: simd_float3, to: simd_float3, t: Float) -> simd_float3 {
    return from + ((to - from) * t)
}


//MARK: - WeakCollection
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
