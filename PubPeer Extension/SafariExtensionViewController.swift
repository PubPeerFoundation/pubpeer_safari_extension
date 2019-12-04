//
//  SafariExtensionViewController.swift
//  Pubpeer Safari App Extension
//
//  Created by Rogier Muijen on 10/17/19.
//  Copyright © 2019 Pubpeer Foundation. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    @IBOutlet weak var btnCloseWindow: NSButton!
    @IBOutlet weak var btnDisableOnce: NSButton!
    @IBOutlet weak var btnDisableForever: NSButton!
    @IBOutlet weak var btnEnable: NSButton!
    @IBOutlet weak var txtLogo: NSTextField!
    @IBOutlet weak var txtDescription_1: NSTextField!
    @IBOutlet weak var txtDescription_2: NSTextField!
    
    private var url: String?
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        DispatchQueue.main.async {
            shared.preferredContentSize = NSSize(width:385, height:285)
        }
        
        return shared
    }()
    
    private func _style(title: String?, value: Any, isBold: Bool = false) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: title ?? "")
        attributedString.addAttribute(NSAttributedString.Key.kern, value: value, range: NSMakeRange(0, title?.count ?? 0))
        if (isBold) {
            attributedString.addAttribute(NSAttributedString.Key.font, value: NSFont(name: "Helvetica-Bold", size: 16)!, range: NSMakeRange(3, (title?.count ?? 0) - 4))
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraph, range: NSMakeRange(0, title?.count ?? 0))
        return attributedString
    }
    
    
    func initUIElements() {
        self.btnDisableOnce.layer?.backgroundColor = NSColor.init(calibratedRed: 106/255, green: 194/255, blue: 188/255, alpha: 1).cgColor
        self.btnDisableForever.layer?.backgroundColor = NSColor.init(calibratedRed: 106/255, green: 194/255, blue: 188/255, alpha: 1).cgColor
        self.btnDisableOnce.layer?.cornerRadius = 5
        self.btnDisableForever.layer?.cornerRadius = 5
        self.txtLogo.attributedStringValue = self._style(title: "PUBPEER", value: 2)
        self.txtDescription_1.attributedStringValue = self._style(title: "Disable Pubpeer extension", value: 1)
        self.txtDescription_2.attributedStringValue = self._style(title: "on \(DisabledHostsManager.shared.normalizeUrl( self.url ?? "" ))?", value: 1, isBold: true)
        self.btnDisableOnce.attributedTitle = self._style(title: "DISABLE ON THIS SITE UNTIL NEXT VISIT", value: 0.4)
        self.btnDisableForever.attributedTitle = self._style(title: "DISABLE ON THIS SITE FOREVER", value: 0.4)
        self.btnEnable.attributedTitle = self._style(title: "ENABLE ON THIS SITE", value: 0.4)
    }
    
    func setActivatedURL(with url: String?) {
        self.url = url
    }
    
    func closePopover() {
        SafariExtensionViewController.shared.dismissPopover()
    }
    
    @IBAction func closeWindow(_ sender: NSButton) {
        self.closePopover()
    }
    
    @IBAction func disableOnce(_ sender: NSButton) {
        DisabledHostsManager.shared.add(self.url ?? "", once: true)
        SafariExtensionHandler.shared.sendMessage(withName: "removePubPeerMarks", userInfo: [:])
        self.closePopover()
    }
    
    @IBAction func disableForever(_ sender: NSButton) {
        DisabledHostsManager.shared.add(self.url ?? "", once: false)
        SafariExtensionHandler.shared.sendMessage(withName: "removePubPeerMarks", userInfo: [:])
        self.closePopover()
    }
    
    @IBAction func enableHost(_ sender: NSButton) {
        DisabledHostsManager.shared.remove(self.url ?? "")
        SafariExtensionHandler.shared.sendMessage(withName: "addPubPeerMarks", userInfo: [:])
        self.closePopover()
    }
}
