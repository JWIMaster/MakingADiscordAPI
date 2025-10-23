//
//  DMView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 19/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix


class DMViewController: UIViewController, UIGestureRecognizerDelegate {
    public var dm: DM?
    
    var messageIDsInStack = Set<Snowflake>()
    var initialViewSetupComplete = false
    
    let scrollView = UIScrollView()
    let containerView = UIView()
    var containerViewBottomConstraint: NSLayoutConstraint!
    
    private var observers = [NSObjectProtocol]()
    
    var dmStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }()
    
    public init(dm: DM) {
        super.init(nibName: nil, bundle: nil)
        self.dm = dm
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)
        
        title = self.dm?.recipient?.displayname
        
        SetStatusBarBlackTranslucent()
        SetWantsFullScreenLayout(self, true)
        
        setupKeyboardObservers()
        setupSubviews()
        setupConstraints()
        getMessages()
        setupWebsocketWatchers()
    }
    
    func setupWebsocketWatchers() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .messageCreate, object: nil, queue: .main) { [weak self] notification in
            self?.createMessage(notification: notification as NSNotification)
        })
        observers.append(center.addObserver(forName: .messageDelete, object: nil, queue: .main) { [weak self] notification in
            self?.deleteMessage(notification: notification as NSNotification)
        })
        observers.append(center.addObserver(forName: .messageUpdate, object: nil, queue: .main) { [weak self] notification in
            self?.updateMessage(notification: notification as NSNotification)
        })
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("✅ DMViewController deinitialized")
    }
    
    /*override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for subview in dmStack.arrangedSubviews {
            if let mv = subview as? MessageView {
                mv.unloadHeavyContent()
                mv.removeFromSuperview()
            } else {
                subview.removeFromSuperview()
            }
        }
        dmStack.removeFromSuperview()
        containerView.removeFromSuperview()

        URLCache.shared.removeAllCachedResponses()
        func clearLayers(_ view: UIView) {
            view.layer.contents = nil
            view.layer.removeAllAnimations()
            view.subviews.forEach { clearLayers($0) }
        }
        clearLayers(view)
        DispatchQueue.main.async {
            autoreleasepool { }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            autoreleasepool { }
        }
    }*/

    
    @objc func createMessage(notification: NSNotification) {
        guard let messageData = notification.userInfo as? [String: Any] else { return }
        
        let message = Message(clientUser, messageData)
        
        if !messageIDsInStack.contains(message.id!) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return }
                self.dmStack.addArrangedSubview(MessageView(clientUser, message: message))
                self.scrollView.layoutIfNeeded()
                self.scrollToBottom(animated: true)
            }
        }
    }
    
    @objc func deleteMessage(notification: NSNotification) {
        guard let messageData = notification.userInfo as? [String: Any] else { return }
        
        let message = Message(clientUser, messageData)
        
        for view in dmStack.arrangedSubviews {
            if let messageView = view as? MessageView, messageView.message?.id == message.id {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                        self.dmStack.removeArrangedSubview(messageView)
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }
    }
    
    @objc func updateMessage(notification: NSNotification) {
        guard let messageData = notification.userInfo as? [String: Any] else { return }
        
        let message = Message(clientUser, messageData)
        
        for view in dmStack.arrangedSubviews {
            if let messageView = view as? MessageView, messageView.message?.id == message.id {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                        messageView.updateMessage(message)
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupSubviews() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        dmStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(dmStack)
        
        containerView.alpha = 0
    }
    
    func getMessages() {
        guard let dm = dm, let id = dm.id else { return }
        
        
        clientUser.getChannelMessages(for: id) { [weak self] messages, error in
            guard let self = self else { return }
            
            self.addMessagesToStack(messages)
            
            if !self.initialViewSetupComplete {
                self.setupInputView(for: dm)
            }
            
            //Fade on container
            if self.containerView.alpha == 0 {
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut]) {
                    self.containerView.alpha = 1
                }
            }
        }
    }
    
    func addMessagesToStack(_ messages: [Message]) {
        
        for message in messages {
            if let messageID = message.id, !messageIDsInStack.contains(messageID) {
                
                let messageView = MessageView(clientUser, message: message)
                self.dmStack.addArrangedSubview(messageView)
                messageIDsInStack.insert(messageID)
                scrollView.layoutIfNeeded()
                scrollToBottom(animated: true)
            }
        }
    }
    
    func setupInputView(for dm: DM) {
        let inputView = InputView(dm: dm, snapshotView: view)
        containerView.addSubview(inputView)
        inputView.translatesAutoresizingMaskIntoConstraints = false
        
        inputView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        inputView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        inputView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -20).isActive = true
        
        view.layoutIfNeeded()
        scrollView.contentInset.bottom = inputView.bounds.height + 10
        scrollView.contentInset.top = (navigationController?.navigationBar.frame.height)!
        
        scrollView.layoutIfNeeded()
        scrollToBottom(animated: false)
        
        initialViewSetupComplete = true
    }
    
    func setupConstraints() {
        dmStack.pinToEdges(of: scrollView, insetBy: .init(top: 20, left: 20, bottom: 20, right: 20))
        dmStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        scrollView.pinToEdges(of: containerView)
        scrollView.pinToCenter(of: containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIApplication.shared.statusBarFrame.height),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomConstraint.isActive = true
    }
    
    
    func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: 0,y: max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom))
        scrollView.setContentOffset(bottomOffset, animated: animated)
    }
    
    
    
    @objc private func keyboardWillAppear(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        containerViewBottomConstraint.constant = -keyboardFrame.cgRectValue.height
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.scrollView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
        }
    }
    
    @objc private func keyboardWillDisappear(notification: NSNotification) {
        containerViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIControl || touch.view is UITextView {
            return false
        }
        return true
    }

    
    private var navigationBarHeight: CGFloat {
        if #available(iOS 7.0.1, *) {
            return navigationController?.navigationBar.frame.height ?? 0
        } else {
            return 0
        }
    }

}

import UIKit
import QuartzCore

public func applyGaussianBlur(to layer: CALayer, radius: CGFloat) {
    // Get the CAFilter class dynamically
    guard let CAFilterClass = NSClassFromString("CAFilter") as AnyObject as? NSObjectProtocol else {
        print("CAFilter not available")
        return
    }

    // Create a Gaussian blur filter
    let blurFilter = CAFilterClass.perform(NSSelectorFromString("filterWithName:"), with: "gaussianBlur")?.takeUnretainedValue()

    // Set the blur radius
    blurFilter?.perform(NSSelectorFromString("setValue:forKey:"), with: radius, with: "inputRadius")

    // Apply the filter to the layer
    layer.setValue([blurFilter as Any].compactMap { $0 }, forKey: "filters")
}
