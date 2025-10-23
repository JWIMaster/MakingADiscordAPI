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
import iOS6BarFix

//public typealias UIStackView = UIKitCompatKit.UIStackView

class ViewController: UIViewController {
    let scrollView = UIScrollView()
    
    var dmStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }()
    
    var guildStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .center
        return stack
    }()
    
    var viewStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)
        SetWantsFullScreenLayout(self, true)
        title = "Direct Messages"
        
        clientUser.setIntents(intents: .directMessages, .directMessagesTyping)
        clientUser.connect()
        
        setupSubviews()
        setupConstraints()
        getDMs()
        
        
        
        
        let clearCache = UIButton(type: .custom)
        clearCache.setTitle("Clear Cache", for: .normal)
        clearCache.titleLabel?.font = .systemFont(ofSize: 17)
        clearCache.setTitleColor(.black, for: .normal)
        clearCache.titleLabel?.backgroundColor = .clear
        clearCache.addAction(for: .touchUpInside) {
            AvatarCache.shared.clearCache()
        }
        dmStack.addArrangedSubview(clearCache)
    }
    
    func setupSubviews() {
        scrollView.isDirectionalLockEnabled = true
        scrollView.addSubview(dmStack)
        viewStack.addArrangedSubview(scrollView)
        view.addSubview(viewStack)
    }
    
    func setupConstraints() {
        dmStack.pinToEdges(of: scrollView, insetBy: .init(top: 20, left: 20, bottom: 20, right: 20))
        dmStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        viewStack.pinToEdges(of: view, insetBy: .init(top: (self.navigationController?.navigationBar.frame.height)!+10, left: 0, bottom: 0, right: 0))
        //viewStack.pinToCenter(of: view)
    }
    
    func getDMs() {
        clientUser.getSortedDMs() { dms, error in
            self.addDMsToStack(dms)
        }
    }
    
    func addDMsToStack(_ dms: [DM]) {
        for dm in dms {
            let dmButton = UIButton(type: .custom)
            dmButton.setTitle(dm.recipient?.displayname, for: .normal)
            dmButton.setTitleColor(.white, for: .normal)
            dmButton.titleLabel?.font = .systemFont(ofSize: 20)
            dmButton.setTitleColor(.gray, for: .highlighted)
            
            dmButton.addAction(for: .touchUpInside) {
                self.navigationController?.pushViewController(DMViewController(dm: dm), animated: true)
            }
            
            self.dmStack.addArrangedSubview(dmButton)
        }
    }
    
    
}


