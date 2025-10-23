//
//  MessageView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 18/10/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy

public class MessageView: UIView {
    let messageContent: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 6
        stack.distribution = .equalSpacing
        return stack
    }()
    var messageText = UILabel()
    var messageAttachments: UIImageView?
    var authorAvatar: UIImageView = UIImageView()
    let authorName = UILabel()
    let messageBackground = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
    var slClient: SLClient?
    var message: Message?
    var isClientUser: Bool?
    
    public init(_ slClient: SLClient, message: Message) {
        super.init(frame: .zero)
        self.slClient = slClient
        self.message = message
        self.isClientUser = {
            return message.author == slClient.clientUser
        }()
        self.setup()
    }
    
    
    private func setup() {
        setupText()
        setupBackground()
        setupAuthorName()
        //setupAvatar()
        setupSubviews()
        setupAttachments()
        setupContraints()
    }
    
    private func setupSubviews() {
        messageContent.addArrangedSubview(messageText)
        addSubview(messageContent)
        addSubview(messageBackground)
        sendSubviewToBack(messageBackground)
        addSubview(authorName)
        addSubview(authorAvatar)
    }
    
    private func setupText() {
        messageText.translatesAutoresizingMaskIntoConstraints = false
        messageText.text = "\(message?.content ?? "unknown")"
        messageText.backgroundColor = .clear
        messageText.textColor = .white
        messageText.lineBreakMode = .byWordWrapping
        messageText.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 60
        messageText.numberOfLines = 0
        messageText.font = .systemFont(ofSize: 17)
        messageText.sizeToFit()
    }
    
    private func setupBackground() {
        var messageColor = UIColor()
        if isClientUser! {
            messageColor = .tealBlue.withAlphaComponent(0.4)
        } else {
            messageColor = UIColor(red: 66/255, green: 252/255, blue: 115/255, alpha: 0.4)
        }
        messageBackground.translatesAutoresizingMaskIntoConstraints = false
        messageBackground.isUserInteractionEnabled = false
        messageBackground.tintColorForGlass = messageColor
        messageBackground.shadowColor = messageColor.withAlphaComponent(1).cgColor
        messageBackground.shadowOpacity = 0.3
        let shadowRadius: CGFloat = {
            if device == .a4 {
                return 0
            }
            else {
                return 6
            }
        }()
        messageBackground.shadowRadius = shadowRadius
        messageBackground.solidViewColour = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)
        
        messageBackground.sizeToFit()
    }
    
    private func setupAuthorName() {
        authorName.text = message?.author?.displayname
        authorName.font = .boldSystemFont(ofSize: 12)
        authorName.textColor = .white
        authorName.backgroundColor = .clear
        authorName.translatesAutoresizingMaskIntoConstraints = false
        authorName.sizeToFit()
    }
    
    private func setupAvatar() {
        guard let author = message?.author else { return }

        authorAvatar = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        
        
        AvatarCache.shared.avatar(for: author) { [weak self] image in
            guard let self = self, let image = image else { return }
            
            let resized = image.resizeImage(image, targetSize: CGSize(width: 30, height: 30))
            
            DispatchQueue.main.async {
                self.authorAvatar.image = resized
                self.authorAvatar.contentMode = .scaleAspectFit
            }
        }
    }

    
    private func setupDate() {
        
    }
    
    private func setupAttachments() {
        guard let attachment = self.message?.attachments.first else { return }
        
        attachment.fetch { [weak self] content in
            guard let self = self else { return }
            guard let image = content as? UIImage else { return }
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            let originalSize = image.size
            let aspectRatio = originalSize.height / originalSize.width

            self.messageAttachments = imageView
            
            self.messageContent.addArrangedSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: self.messageContent.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: self.messageContent.trailingAnchor),
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: image.size.height / image.size.width)
            ])
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }


    
    private func setupContraints() {
        NSLayoutConstraint.activate([
            messageBackground.topAnchor.constraint(equalTo: self.topAnchor),
            messageBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            messageBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            messageBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            
            messageContent.topAnchor.constraint(equalTo: self.topAnchor, constant: 18),
            messageContent.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            messageContent.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            messageContent.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6),
            
            
            authorName.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            authorName.leadingAnchor.constraint(equalTo: messageContent.leadingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            authorAvatar.topAnchor.constraint(equalTo: authorName.topAnchor),
            authorAvatar.trailingAnchor.constraint(equalTo: messageContent.leadingAnchor, constant: -4)
        ])
    }
    
    public func updateMessage(_ message: Message) {
        self.messageText.text = message.content
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.slClient = nil
        self.message = nil
        self.isClientUser = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    deinit {
        unloadHeavyContent()
        print("Deinit!")
    }
    
    public func unloadHeavyContent() {
        // Remove attachment image and layer contents
        if let imgView = messageAttachments {
            imgView.image = nil
            imgView.layer.contents = nil
            imgView.removeFromSuperview()
            messageAttachments = nil
        }

        // Release avatar and its layer
        authorAvatar.image = nil
        authorAvatar.layer.contents = nil

        // Remove blurred background textures
        messageBackground.layer.contents = nil

        // Force Core Animation to release textures
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.contents = nil
        CATransaction.commit()

        // Remove from superview to break layout/animation retain chains
        removeFromSuperview()

        // Hint ARC cleanup
        DispatchQueue.global(qos: .background).async {
            autoreleasepool { }
        }
    }

}


extension UIImage {
    static func solid(color: UIColor, size: CGSize = CGSize(width: 30, height: 30)) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        print("resized")
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
}
