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

public class MessageView: UIView, UIGestureRecognizerDelegate {
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
    public var averageAvatarColor: UIColor?
    let authorName = UILabel()
    let messageBackground: UIView? = {
        switch device {
        case .a4:
            return UIView()
        default:
            return LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        }
    }()
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
        //setupAuthorAvatar()
        setupSubviews()
        setupContraints()
        //setupAttachments()
    }
    
    private func setupSubviews() {
        guard let messageBackground = messageBackground else { return }
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
        messageText.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80
        messageText.numberOfLines = 0
        messageText.font = .systemFont(ofSize: 17)
        messageText.sizeToFit()
    }
    
    private func setupBackground() {
        guard let messageBackground = messageBackground else { return }
        
        messageBackground.translatesAutoresizingMaskIntoConstraints = false
        messageBackground.isUserInteractionEnabled = false
        
        if let messageBackground = messageBackground as? LiquidGlassView {
            messageBackground.shadowOpacity = 0.3
            messageBackground.shadowRadius = 6
            messageBackground.solidViewColour = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)
        } else {
            messageBackground.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)
        }
        
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
    
    private func setupAuthorAvatar() {
        guard let author = message?.author else { return }

        authorAvatar = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        authorAvatar.translatesAutoresizingMaskIntoConstraints = false
        
        AvatarCache.shared.avatar(for: author) { [weak self] image, color in
            guard let self = self, let image = image, let color = color else { return }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let resized = image.resizeImage(image, targetSize: CGSize(width: 30, height: 30))
                
                DispatchQueue.main.async {
                    self.authorAvatar.image = resized
                    self.authorAvatar.contentMode = .scaleAspectFit
                    
                    if let messageBackground = self.messageBackground as? LiquidGlassView {
                        messageBackground.tintColorForGlass = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(0.4)
                        messageBackground.shadowColor = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(1).cgColor
                        messageBackground.shadowOpacity = 0.6
                        messageBackground.setNeedsLayout()
                    } else {
                        self.messageBackground?.backgroundColor = color.withIncreasedSaturation(factor: 1.4)
                        self.messageBackground?.setNeedsLayout()
                    }
                }
            }
        }
    }

    
    private func setupDate() {
        
    }

    private func getAttachment(attachment: Attachment) {
        guard let attachmentWidth = attachment.width, let attachmentHeight = attachment.height else { return }
        
        let aspectRatio = attachmentWidth / attachmentHeight
        let width = UIScreen.main.bounds.width-40
        let height = width / aspectRatio
        let scaledSize = CGSize(width: width, height: height)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.messageAttachments = imageView
        
        self.messageContent.addArrangedSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.messageContent.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.messageContent.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1/aspectRatio)
        ])
        
        attachment.fetch { [weak self] attachment in
            guard let self = self, let image = attachment as? UIImage else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                autoreleasepool {
                    let resizedImage = image.resizeImage(image, targetSize: scaledSize)
                    DispatchQueue.main.async {
                        imageView.image = resizedImage
                    }
                }
            }
        }
    }
    
    //MARK: TODO cannot fix multi attachments on iOS 6 it is slow as hell for some reason
    private func setupAttachments() {
        guard let message = message else {
            return
        }

        if #available(iOS 7.0.1, *) {
            setupAttachments7()
        } else {
            guard let firstAttachment = message.attachments.first else { return }
            getAttachment(attachment: firstAttachment)
        }
    }
    
    private func setupAttachments7() {
        guard let message = message else { return }
        let attachments = message.attachments
        guard !attachments.isEmpty else { return }
        var index = 0
        
        //Stack of all the attachments
        let attachmentStack = UIStackView()
        attachmentStack.axis = .vertical
        attachmentStack.spacing = 8
        attachmentStack.distribution = .fillEqually
        attachmentStack.translatesAutoresizingMaskIntoConstraints = false
        
        while index < attachments.count {
            //Stack for row of 2 attachments
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            // Add up to 2 attachments per row
            for increment in 0...1 where index + increment < attachments.count {
                let attachment = attachments[index + increment]
                
                guard let attachmentWidth = attachment.width, let attachmentHeight = attachment.height else { return }

                let aspectRatio = attachmentWidth / attachmentHeight
                let width = (UIScreen.main.bounds.width-40)/2
                let height = width / aspectRatio
                let scaledSize = CGSize(width: width, height: height)
                
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(imageClick))
                tapGesture.cancelsTouchesInView = false
                tapGesture.delegate = self
                imageView.addGestureRecognizer(tapGesture)
                imageView.isUserInteractionEnabled = true
                rowStack.addArrangedSubview(imageView)
                
                //Set height or else behaves poorly
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1/aspectRatio).isActive = true
                
                // Fetch image async
                attachment.fetch { [weak imageView] attachment in
                    guard let imageView = imageView, let image = attachment as? UIImage else { return }
                    DispatchQueue.global(qos: .userInitiated).async {
                        autoreleasepool {
                            let resizedImage = image.resizeImage(image, targetSize: scaledSize)
                            DispatchQueue.main.async {
                                imageView.image = resizedImage
                                imageView.backgroundColor = .clear
                            }
                        }
                    }
                }
            }
            attachmentStack.addArrangedSubview(rowStack)
            //Move onto next pair
            index += 2
        }
        self.messageContent.addArrangedSubview(attachmentStack)
    }

    @objc private func imageClick(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let imageView = gesture.view as? UIImageView,
              let image = imageView.image else { return }
        
        let newImageView = UIImageView(image: image)
        newImageView.contentMode = .scaleAspectFit
        newImageView.translatesAutoresizingMaskIntoConstraints = false

        let vc = AttachmentViewController(attachment: newImageView)
        self.parentViewController?.navigationController?.pushViewController(vc, animated: true)
    }



    
    private func setupContraints() {
        guard let messageBackground = messageBackground else { return }
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
}







