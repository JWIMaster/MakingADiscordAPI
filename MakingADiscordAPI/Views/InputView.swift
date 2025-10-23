import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy


public class InputView: UIView, UITextViewDelegate {
    public var snapshotView: UIView?
    public let backgroundView: LiquidGlassView = {
        let bView = LiquidGlassView(blurRadius: 8, cornerRadius: 20, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
        bView.translatesAutoresizingMaskIntoConstraints = false
        bView.solidViewColour = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 0.8)
        bView.scaleFactor = PerformanceManager.scaleFactor
        bView.frameInterval = PerformanceManager.frameInterval
        return bView
    }()
    public var dm: DM?
    public var tokenInputView: Bool?
    
    
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
    
    
    
    public let sendButton = UIButton(type: .custom)
    
    public init(dm: DM, snapshotView: UIView, tokenInputView: Bool = false) {
        super.init(frame: .zero)
        self.snapshotView = snapshotView
        self.dm = dm
        self.tokenInputView = tokenInputView
        setupSubviews()
        setupConstraints()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.snapshotView = nil
        self.dm = nil
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupSubviews() {
        
        backgroundView.snapshotTargetView = snapshotView
        addSubview(backgroundView)
        
        textView.delegate = self
        backgroundView.addSubview(textView)
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        let buttonBackground = LiquidGlassView(blurRadius: 0, cornerRadius: 20, snapshotTargetView: nil, disableBlur: true)
        buttonBackground.scaleFactor = 0.25
        buttonBackground.snapshotTargetView = snapshotView
        buttonBackground.frameInterval = 6
        sendButton.addSubview(buttonBackground)
        buttonBackground.pinToEdges(of: sendButton, insetBy: .init(top: -4, left: -8, bottom: -4, right: -8))
        buttonBackground.isUserInteractionEnabled = false
        sendButton.sendSubviewToBack(buttonBackground)
        sendButton.addAction(for: .touchUpInside) {
            self.sendMessageAction()
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
        sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 10).isActive = true
        sendButton.heightAnchor.constraint(equalTo: backgroundView.heightAnchor).isActive = true
    }
    
    private func sendMessageAction() {
        self.sendButton.isUserInteractionEnabled = false
        guard let dmID = self.dm?.id else { return }
        clientUser.sendMessage(self.textView.text, to: dmID) { message, error in
            self.textView.text = nil
            self.textViewDidChange(self.textView)
            self.sendButton.isUserInteractionEnabled = true
        }
    }
    
    
    public func textViewDidChange(_ textView: UITextView) {
        backgroundView.frameInterval = 60*60*60
        let width = textView.bounds.width > 0 ? textView.bounds.width : 100 // fallback
        let size = textView.sizeThatFits(CGSize(width: width, height: 1000000))
        let clampedHeight = max(40, min(size.height, 120))
        
        if clampedHeight != self.bounds.height {
            self.invalidateIntrinsicContentSize()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.backgroundView.frameInterval = 6
        }
    }
    
    
    public override var intrinsicContentSize: CGSize {
        let width = textView.bounds.width > 0 ? textView.bounds.width : 100
        let size = textView.sizeThatFits(CGSize(width: width, height: 1000000))
        let height = max(40, min(size.height, 120))
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    
}
