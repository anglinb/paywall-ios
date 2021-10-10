//
//  File.swift
//  
//
//  Created by Jake Mor on 10/9/21.
//

import Foundation
import UIKit

public class PaywallResult {
	public var didPresent: Bool
	public var paywallInfo: PaywallInfo?
	public var error: NSError?
	
	internal var onDismissalCompletion: (Bool, String?) -> () = { _, _ in
		
	}

	public func onCompletion(completion: @escaping ((Bool, String?) -> ())) {
		self.onDismissalCompletion = completion
	}
	
	init(didPresent: Bool, paywallInfo: PaywallInfo?, error: NSError?) {
		self.didPresent = didPresent
		self.paywallInfo = paywallInfo
		self.error = error
	}
}


extension Paywall {
	@available(*, deprecated, message: "use present(on viewController: UIViewController? = nil, presentationCompletion: (()->())? = nil, dismissalCompletion: DismissalCompletionBlock? = nil, fallback: FallbackBlock? = nil) instead")
	@objc public static func present(on viewController: UIViewController? = nil,
									 cached: Bool = true,
									 presentationCompletion: (()->())? = nil,
									 purchaseCompletion: ((Bool) -> ())? = nil,
									 fallback: (()->())? = nil) {
		present(on: viewController, presentationCompletion: { _  in
			presentationCompletion?()}, dismissalCompletion: { didPurchase, _, _ in
				purchaseCompletion?(didPurchase)
			}, fallback: { _ in
			fallback?()
		})
	}	
	
	public static func present(identifier: String? = nil, on viewController: UIViewController? = nil, completion: @escaping (PaywallResult) -> ()) {
		var result: PaywallResult? = nil
		
		present(identifier: identifier, on: viewController) { didPresent, info, error in
			result = PaywallResult(didPresent: didPresent, paywallInfo: info, error: error)
			if let r = result {
				completion(r)
			}
		} onDismiss: { didPurchase, productId, info in
			result?.paywallInfo = info
			result?.onDismissalCompletion(didPurchase, productId)
		}

		
	}
	
	/// Presents a paywall to the user.
	///  - Parameter completion: A completion block that gets called immediately after the paywall is presented. Defaults to  `nil`,
	///  - Parameter onDismiss: Gets called when the paywall is dismissed by the user, by way of purchasing, restoring or manually dismissing. Accepts a `Bool` that is `true` if the product is purchased or restored, and `false` if the paywall is manually dismissed by the user.
	@objc public static func present(completion: ((Bool, PaywallInfo?, NSError?)->())? = nil,
									 onDismiss: ((Bool, String?, PaywallInfo?) -> ())? = nil) {
		_present(identifier: nil, on: nil, fromEvent: nil, cached: true, dismissalCompletion: onDismiss, completion: completion)
		
	}
	
	
	/// Presents a paywall to the user.
	///  - Parameter on: The view controller to present the paywall on. Presents on the `keyWindow`'s `rootViewController` if `nil`. Defaults to `nil`.
	///  - Parameter completion: A completion block that gets called immediately after the paywall is presented. Defaults to  `nil`,
	///  - Parameter onDismiss: Gets called when the paywall is dismissed by the user, by way of purchasing, restoring or manually dismissing. Accepts a `Bool` that is `true` if the product is purchased or restored, and `false` if the paywall is manually dismissed by the user.
	@objc public static func present(on viewController: UIViewController? = nil,
									 completion: ((Bool, PaywallInfo?, NSError?)->())? = nil,
									 onDismiss: ((Bool, String?, PaywallInfo?) -> ())? = nil) {
		_present(identifier: nil, on: viewController, fromEvent: nil, cached: true, dismissalCompletion: onDismiss, completion: completion)
		
	}
	
	
	/// Presents a paywall to the user.
	///  - Parameter identifier: The identifier of the paywall you wish to present
	///  - Parameter on: The view controller to present the paywall on. Presents on the `keyWindow`'s `rootViewController` if `nil`. Defaults to `nil`.
	///  - Parameter completion: A completion block that gets called immediately after the paywall is presented. Defaults to  `nil`,
	///  - Parameter onDismiss: Gets called when the paywall is dismissed by the user, by way of purchasing, restoring or manually dismissing. Accepts a `Bool` that is `true` if the product is purchased or restored, and `false` if the paywall is manually dismissed by the user.
	@objc public static func present(identifier: String? = nil,
									 on viewController: UIViewController? = nil,
									 completion: ((Bool, PaywallInfo?, NSError?)->())? = nil,
									 onDismiss: ((Bool, String?, PaywallInfo?) -> ())? = nil) {
		

		_present(identifier: identifier, on: viewController, fromEvent: nil, cached: true, dismissalCompletion: onDismiss, completion: completion)
	}
	
	
	/// This function is equivalent to logging an event, but exposes completion blocks in case you would like to execute code based on specific outcomes
	///  - Parameter event: The name of the event you wish to trigger (equivalent to event name in `Paywall.track()`)
	///  - Parameter params: Parameters you wish to pass along to the trigger (equivalent to params in `Paywall.track()`)
	///  - Parameter on: The view controller to present the paywall on. Presents on the `keyWindow`'s `rootViewController` if `nil`. Defaults to `nil`.
	///  - Parameter completion: A completion block that gets called immediately after the paywall is presented. Defaults to  `nil`,
	///  - Parameter onDismiss: Gets called when the paywall is dismissed by the user, by way of purchasing, restoring or manually dismissing. Accepts a `Bool` that is `true` if the product is purchased or restored, and `false` if the paywall is manually dismissed by the user.
	///  - Parameter triggerFallback: Gets called if the trigger is not defined, if the trigger is off,  or if an error occurs
	@objc public static func trigger(event: String? = nil,
									 params: [String: Any]? = nil,
									 on viewController: UIViewController? = nil,
									 completion: ((Bool, PaywallInfo?, NSError?) -> ())? = nil,
									 onDismiss: ((Bool, String?, PaywallInfo?) -> ())? = nil) {
		
		var e: EventData? = nil
		
		if let name = event {
			e = Paywall._track(name, [:], params ?? [:], handleTrigger: false)
		}
		
		_present(identifier: nil, on: viewController, fromEvent: e, cached: true, dismissalCompletion: onDismiss, completion: completion)
	}
	
	
	internal static func _present(identifier: String? = nil,
									 on viewController: UIViewController? = nil,
									 fromEvent: EventData? = nil,
									 cached: Bool = true,
									 dismissalCompletion: ((Bool, String?, PaywallInfo?) -> ())? = nil,
									 completion: ((Bool, PaywallInfo?, NSError?)->())? = nil) {
		
		present(identifier: identifier, on: viewController, fromEvent: fromEvent, cached: cached, presentationCompletion: { paywallInfo in
			completion?(true, paywallInfo, nil)
		}, dismissalCompletion: dismissalCompletion, fallback: { error in
			completion?(false, nil, error)
		})
		
	}
	
	internal static func present(identifier: String? = nil,
									on viewController: UIViewController? = nil,
									fromEvent: EventData? = nil,
									cached: Bool = true,
									presentationCompletion: ((PaywallInfo?)->())? = nil,
									dismissalCompletion: ((Bool, String?, PaywallInfo?) -> ())? = nil,
									fallback: ((NSError?) -> ())? = nil) {
		
		if isDebuggerLaunched {
			// if the debugger is launched, ensure the viewcontroller is the debugger
			guard viewController is SWDebugViewController else { return }
		} else {
			// otherwise, ensure we should present the paywall via the delegate method
			guard (delegate?.shouldPresentPaywall() ?? false) else { return }
		}
		
		self.dismissalCompletion = dismissalCompletion
		
		
		
		guard let delegate = delegate else {
			Logger.superwallDebug(string: "Yikes ... you need to set Paywall.delegate before doing anything fancy")
			fallback?(Paywall.shared.presentationError(domain: "SWDelegateError", code: 100, title: "Paywall delegate not set", value: "You need to set Paywall.delegate before doing anything fancy"))
			return
		}
		
		
		let presentationBlock: ((SWPaywallViewController) -> ()) = { vc in
			

			guard let presentor = (viewController ?? UIViewController.topMostViewController) else {
				Logger.superwallDebug(string: "No UIViewController to present paywall on. This usually happens when you call this method before a window was made key and visible. Try calling this a little later, or explicitly pass in a UIViewController to present your Paywall on :)")
				fallback?(Paywall.shared.presentationError(domain: "SWPresentationError", code: 101, title: "No UIViewController to present paywall on", value: "This usually happens when you call this method before a window was made key and visible."))
				return
			}
			
			// if the top most view controller is a paywall view controller
			// the paywall view controller to present has a presenting view controller
			// the paywall view controller to present is in the process of being presented
			
			
			let isPresented = (presentor as? SWPaywallViewController) != nil || vc.presentingViewController != nil || vc.isBeingPresented
			
			if !isPresented {
				shared.paywallViewController?.readyForEventTracking = false
				vc.willMove(toParent: nil)
				vc.view.removeFromSuperview()
				vc.removeFromParent()
				vc.view.alpha = 1.0
				vc.view.transform = .identity
				vc.webview.scrollView.contentOffset = CGPoint.zero
				delegate.willPresentPaywall?()
				presentor.present(vc, animated: true, completion: {
					self.presentAgain = {
						present(on: viewController, fromEvent: fromEvent, cached: false, presentationCompletion: presentationCompletion, dismissalCompletion: dismissalCompletion, fallback: fallback)
					}
					delegate.didPresentPaywall?()
					presentationCompletion?(vc._paywallResponse?.paywallInfo)
					Paywall.track(.paywallOpen(paywallId: self.shared.paywallId))
					shared.paywallViewController?.readyForEventTracking = true
					if (Paywall.isGameControllerEnabled) {
						GameControllerManager.shared.delegate = vc
					}
				})
			} else {
				Logger.superwallDebug(string: "Note: A Paywall is already being presented")
			}

		}
		
		if let vc = shared.paywallViewController, cached, fromEvent?.name == lastEventTrigger {
			presentationBlock(vc)
			return
		}
		
		lastEventTrigger = fromEvent?.name
		
		getPaywallResponse(withIdentifier: identifier, fromEvent: fromEvent) { success, error in
			
			if (success) {
				
				guard let vc = shared.paywallViewController else {
					lastEventTrigger = nil
					Logger.superwallDebug(string: "Paywall's viewcontroller is nil!")
					fallback?(Paywall.shared.presentationError(domain: "SWInternalError", code: 102, title: "Paywall not set", value: "Paywall.paywallViewController was nil"))
					return
				}
				
				guard let _ = shared.paywallResponse else {
					lastEventTrigger = nil
					Logger.superwallDebug(string: "Paywall presented before API response was received")
					fallback?(Paywall.shared.presentationError(domain: "SWInternalError", code: 103, title: "Paywall Presented to Early", value: "Paywall presented before API response was received"))
					return
				}
				
				presentationBlock(vc)
				
			} else {
				lastEventTrigger = nil
				fallback?(error)
			}
		}
	}
	
	
	func presentationError(domain: String, code: Int, title: String, value: String) -> NSError {
		let userInfo: [String : Any] = [
			NSLocalizedDescriptionKey :  NSLocalizedString(title, value: value, comment: "") ,
		]
		return NSError(domain: domain, code: code, userInfo: userInfo)
	}
	
}



