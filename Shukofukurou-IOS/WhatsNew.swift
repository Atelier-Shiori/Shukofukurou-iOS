//
//  WhatsNew.swift
//  Shukofukurou-IOS
//
//  Created by 千代田桃 on 9/25/21.
//  Copyright © 2021 MAL Updater OS X Group. All rights reserved.
//

import Foundation
import UIKit
import WhatsNewKit

@objc public class SWhatsNew: NSObject {
    @objc func showWhatsNew(witems : NSArray, vc : UIViewController, showAtLaunch : Bool){
        var wnewitems = [WhatsNew.Item]()
        for item in (witems as NSArray as! [NSDictionary]) {
            wnewitems.append(WhatsNew.Item(title: item["title"] as! String, subtitle: item["description"] as! String, image: UIImage.init(systemName: item["icon"] as! String)))
        }
        let whatsNew = WhatsNew(
            // The Title
            title: "What's New In Shukofukurou",
            // The features you want to showcase
            items: wnewitems
        )
        let whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew
        )
        
        whatsNewViewController.modalPresentationStyle = .formSheet
        if (showAtLaunch && !self.checkVersion()) || !showAtLaunch {
            vc.present(whatsNewViewController, animated: true) {
                if (showAtLaunch) {
                    UserDefaults.standard.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString"), forKey:"curVersionNum")
                    UserDefaults.standard.set(Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String), forKey: "curBuildNum")
                }
            }
        }
    }
    func checkVersion() -> Bool {
        let curversionNum = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let curbuildNum = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String)
        let prevversionNum = UserDefaults.standard.string(forKey: "curVersionNum")
        let prevbuildNum = UserDefaults.standard.string(forKey: "curBuildNum")
        
        if (curversionNum as! String) == prevversionNum && (curbuildNum as! String) == prevbuildNum {
            return true
        }
        return false;
    }
}
