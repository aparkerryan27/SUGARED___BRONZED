//
//  HalfModalTransitioningDelegate.swift
//
//  Created by Martin Normark on 17/01/16. Edited by Parker Ryan
//  Copyright © 2016 martinnormark. All rights reserved.
//

import UIKit

//MARK: - A Custom Half-Screen View Controller for the Notification Views

class HalfModalPresentationController : UIPresentationController {
    
    var isMaximized: Bool = false
    
    var _dimmingView: UIView?
    var direction: CGFloat = 0
    var state: ModalScaleState = .normal
    var dimmingView: UIView {
        if let dimmedView = _dimmingView {
            return dimmedView
        }
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: containerView!.bounds.width, height: containerView!.bounds.height))
        
        // Blur Effect
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        blurEffectView.frame = view.bounds
        view.addSubview(blurEffectView)
        
        _dimmingView = view
        
        return view
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return CGRect(x: 0,
                      y: containerView!.bounds.height / 2,
                      width: containerView!.bounds.width,
                      height: containerView!.bounds.height / 2
        )
    }
    
    override func presentationTransitionWillBegin() {
        let dimmedView = dimmingView
        
        if let containerView = self.containerView, let coordinator = presentingViewController.transitionCoordinator {
            
            dimmedView.alpha = 0
            containerView.addSubview(dimmedView)
            dimmedView.addSubview(presentedViewController.view)
            
            coordinator.animate(alongsideTransition: { (context) -> Void in
                dimmedView.alpha = 1
                //shrinks the presenting view controller as the new one in placed on top of it
                self.presentingViewController.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }, completion: nil)
        }
    }
    
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentingViewController.transitionCoordinator {
            
            coordinator.animate(alongsideTransition: { (context) -> Void in
                self.dimmingView.alpha = 0
                self.presentingViewController.view.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        
        if completed {
            dimmingView.removeFromSuperview()
            _dimmingView = nil
            
            isMaximized = false
        }
    }
}


class HalfModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var viewController: UIViewController
    var presentingViewController: UIViewController
    
    init(viewController: UIViewController, presentingViewController: UIViewController) {
        self.viewController = viewController
        self.presentingViewController = presentingViewController
        
        super.init()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HalfModalTransitionAnimator(type: .Dismiss)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}

class HalfModalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var type: HalfModalTransitionAnimatorType
    
    init(type:HalfModalTransitionAnimatorType) {
        self.type = type
    }
    
    @objc func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let _ = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { () -> Void in
            
            from!.view.frame.origin.y = 800 //this looks like the actual height of the notification but i'm not sure
            
        }) { (completed) -> Void in
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
}

internal enum HalfModalTransitionAnimatorType {
    case Present
    case Dismiss
}

enum ModalScaleState {
    case adjustedOnce
    case normal
}
