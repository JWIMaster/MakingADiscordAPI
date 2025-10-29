import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import SFSymbolsCompatKit


public class EditView: UIView, UITextViewDelegate {
    public weak var snapshotView: UIView?
    public let backgroundView: LiquidGlassView = {
        let bView = LiquidGlassView(blurRadius: 8, cornerRadius: 20, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
        bView.translatesAutoresizingMaskIntoConstraints = false
        bView.solidViewColour = .discordGray.withAlphaComponent(0.8)
        bView.scaleFactor = PerformanceManager.scaleFactor
        bView.frameInterval = PerformanceManager.frameInterval
        return bView
    }()
    public var channel: TextChannel?
    public var message: Message?
    
    let buttonBackground = LiquidGlassView(blurRadius: 0, cornerRadius: 20, snapshotTargetView: nil, disableBlur: true)
    
    public let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.isScrollEnabled = false
        textView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }()
    
    
    
    public let sendButton = LargeHitAreaButton()
    
    public init(channel: TextChannel, message: Message, snapshotView: UIView) {
        super.init(frame: .zero)
        self.snapshotView = snapshotView
        self.channel = channel
        self.message = message
        setupSubviews()
        setupConstraints()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.snapshotView = nil
        self.channel = nil
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupSubviews() {
        
        backgroundView.snapshotTargetView = snapshotView
        addSubview(backgroundView)
        
        textView.text = message?.content
        textView.sizeToFit()
        textView.delegate = self
        backgroundView.addSubview(textView)
        
        sendButton.setImage(.init(systemName: "paperplane", tintColor: .white), for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        buttonBackground.scaleFactor = 0.25
        buttonBackground.snapshotTargetView = snapshotView
        buttonBackground.frameInterval = 6
        buttonBackground.solidViewColour = .discordGray.withAlphaComponent(0.8)
        addSubview(buttonBackground)
        buttonBackground.pinToCenter(of: sendButton)
        buttonBackground.heightAnchor.constraint(equalToConstant: 40).isActive = true
        buttonBackground.widthAnchor.constraint(equalToConstant: 40).isActive = true
        buttonBackground.isUserInteractionEnabled = false
        sendButton.sendSubviewToBack(buttonBackground)
        //Must use weak self or else the whole inputview gets retained
        sendButton.addAction(for: .touchUpInside) { [weak self] in
            self?.editMessageAction()
        }
        
        
        addSubview(sendButton)
        bringSubviewToFront(sendButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -60)
        ])
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            textView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        ])
        
        sendButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
        sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 20).isActive = true
        sendButton.heightAnchor.constraint(equalTo: backgroundView.heightAnchor).isActive = true
        
        
    }
    
    private func editMessageAction() {
        self.sendButton.isUserInteractionEnabled = false
        
        guard let channel = self.channel, let dmVC = parentViewController as? DMViewController, let message = self.message else { return }
        
        let newMessage = Message(clientUser, ["content": self.textView.text])
        
        clientUser.edit(message: message, to: newMessage, in: channel) { error in
            dmVC.endMessageAction()
        }
        
        
        
    }
    
    
    public func textViewDidChange(_ textView: UITextView) {
        guard let dmVC = parentViewController as? DMViewController, let navBarHeight = dmVC.navigationController?.navigationBar.frame.height else { return }
        let maxHeight = dmVC.view.bounds.height - 50 - navBarHeight*5
        backgroundView.frameInterval = 60*60*60
        let width = textView.bounds.width > 0 ? textView.bounds.width : 100 // fallback
        let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let clampedHeight = max(40, min(size.height, maxHeight))
        
        textView.isScrollEnabled = size.height > maxHeight
        
        if clampedHeight != self.bounds.height {
            self.invalidateIntrinsicContentSize()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.backgroundView.frameInterval = 6
        }
    }
    
    
    public override var intrinsicContentSize: CGSize {
        guard let dmVC = parentViewController as? DMViewController, let navBarHeight = dmVC.navigationController?.navigationBar.frame.height else { return .zero }
        let maxHeight = dmVC.view.bounds.height - 50 - navBarHeight*5
        let width = textView.bounds.width > 0 ? textView.bounds.width : 100
        let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = max(40, min(size.height, maxHeight))
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}




