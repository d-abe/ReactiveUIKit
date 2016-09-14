//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
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
//

import UIKit
import ReactiveKit

@objc class RKUIControlHelper: NSObject
{
  weak var control: UIControl?
  let pushStream = PushStream<UIControlEvents>()
  
  init(control: UIControl) {
    self.control = control
    super.init()
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchDown), for: UIControlEvents.touchDown)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchDownRepeat), for: UIControlEvents.touchDownRepeat)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchDragInside), for: UIControlEvents.touchDragInside)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchDragOutside), for: UIControlEvents.touchDragOutside)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchDragEnter), for: UIControlEvents.touchDragEnter)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchDragExit), for: UIControlEvents.touchDragExit)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchUpInside), for: UIControlEvents.touchUpInside)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchUpOutside), for: UIControlEvents.touchUpOutside)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerTouchCancel), for: UIControlEvents.touchCancel)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerValueChanged), for: UIControlEvents.valueChanged)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerEditingDidBegin), for: UIControlEvents.editingDidBegin)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerEditingChanged), for: UIControlEvents.editingChanged)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerEditingDidEnd), for: UIControlEvents.editingDidEnd)
    control.addTarget(self, action: #selector(RKUIControlHelper.eventHandlerEditingDidEndOnExit), for: UIControlEvents.editingDidEndOnExit)
  }
  
  func eventHandlerTouchDown() {
    pushStream.next(.TouchDown)
  }
  
  func eventHandlerTouchDownRepeat() {
    pushStream.next(.TouchDownRepeat)
  }
  
  func eventHandlerTouchDragInside() {
    pushStream.next(.TouchDragInside)
  }
  
  func eventHandlerTouchDragOutside() {
    pushStream.next(.TouchDragOutside)
  }
  
  func eventHandlerTouchDragEnter() {
    pushStream.next(.TouchDragEnter)
  }
  
  func eventHandlerTouchDragExit() {
    pushStream.next(.TouchDragExit)
  }
  
  func eventHandlerTouchUpInside() {
    pushStream.next(.TouchUpInside)
  }
  
  func eventHandlerTouchUpOutside() {
    pushStream.next(.TouchUpOutside)
  }
  
  func eventHandlerTouchCancel() {
    pushStream.next(.TouchCancel)
  }
  
  func eventHandlerValueChanged() {
    pushStream.next(.ValueChanged)
  }
  
  func eventHandlerEditingDidBegin() {
    pushStream.next(.EditingDidBegin)
  }
  
  func eventHandlerEditingChanged() {
    pushStream.next(.EditingChanged)
  }
  
  func eventHandlerEditingDidEnd() {
    pushStream.next(.EditingDidEnd)
  }
  
  func eventHandlerEditingDidEndOnExit() {
    pushStream.next(.EditingDidEndOnExit)
  }
  
  deinit {
    control?.removeTarget(self, action: nil, for: UIControlEvents.allEvents)
    pushStream.completed()
  }
}

extension UIControl {
  
  private struct AssociatedKeys {
    static var ControlHelperKey = "r_ControlHelperKey"
  }
  
  public var rControlEvent: Stream {
    if let controlHelper: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.ControlHelperKey) {
      return (controlHelper as! RKUIControlHelper).pushStream.toStream()
    } else {
      let controlHelper = RKUIControlHelper(control: self)
      objc_setAssociatedObject(self, &AssociatedKeys.ControlHelperKey, controlHelper, objc_AssociationPolicy.objc_ASSOCIATION_RETAIN_NONATOMIC)
      return controlHelper.pushStream.toStream()
    }
  }
  
  public var rEnabled: Property<Bool> {
    return rAssociatedPropertyForValueForKey("enabled")
  }
}
