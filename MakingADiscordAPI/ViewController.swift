//
//  ViewController.swift
//  MakingADiscordAPI
//
//  Created by JWI on 15/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions

class ViewController: UIViewController {
    let scrollView = UIScrollView()
    
    var dmStack: UIKitCompatKit.UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }()
    
    var guildStack: UIKitCompatKit.UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .center
        return stack
    }()
    
    var viewStack: UIKitCompatKit.UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()
    
    
    
    let user = SwiftcordLegacy(token: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        user.getDMs() { dms, error in
            for dm in dms {
                let dmButton = UIButton(type: .custom)
                dmButton.setTitle(dm.recipient?.displayname, for: .normal)
                dmButton.setTitleColor(.black, for: .normal)
                dmButton.titleLabel?.font = .systemFont(ofSize: 20)
                dmButton.setTitleColor(.gray, for: .highlighted)
                //dmButton.backgroundColor = .black
                
                dmButton.addAction(for: .touchUpInside) {
                    for view in self.dmStack.subviews {
                        view.removeFromSuperview()
                    }
                    
                    self.user.getChannelMessages(for: dm.id!) { messages, error in
                        for message in messages {
                            let messageLabel = UILabel()
                            messageLabel.text = "\(message.author?.displayname ?? "unknown") - \(message.content ?? "unknown")"
                            messageLabel.textColor = .black
                            messageLabel.font = .systemFont(ofSize: 20)
                            self.dmStack.addArrangedSubview(messageLabel)
                        }
                    }
                }
                
                self.dmStack.addArrangedSubview(dmButton)
            }
        }
        
        user.getGuilds() { guilds, error in
            for guild in guilds {
                let guildButton = UIButton(type: .custom)
                guildButton.setTitle(guild.name, for: .normal)
                guildButton.setTitleColor(.black, for: .normal)
                guildButton.titleLabel?.font = .systemFont(ofSize: 20)
                self.guildStack.addArrangedSubview(guildButton)
            }
        }
        
        scrollView.isDirectionalLockEnabled = true
        scrollView.addSubview(dmStack)
        //viewStack.addArrangedSubview(guildStack)
        viewStack.addArrangedSubview(scrollView)
        dmStack.pinToEdges(of: scrollView)
        dmStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        view.addSubview(viewStack)
        viewStack.pinToEdges(of: view)
        viewStack.pinToCenter(of: view)
        
    }


}

