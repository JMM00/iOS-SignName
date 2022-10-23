//
//  UIView+Extension.swift
//  SignName_SceneKit
//
//  Created by 전지민 on 2022/09/02.
//

import Foundation
import UIKit


extension UIColor {
    static var btnBackground: UIColor {
        guard let color = UIColor(named: "BtnBackground") else { return .label }
        return color
    }
    
    static var textBackground: UIColor {
        guard let color = UIColor(named: "textBackground") else { return .label }
        return color
    }
    static var purple: UIColor {
        guard let color = UIColor(named: "purple") else { return .label }
        return color
    }
    static var deepblue: UIColor {
        guard let color = UIColor(named: "deepblue") else { return .label }
        return color
    }
    static var skyblue: UIColor {
        guard let color = UIColor(named: "skyblue") else { return .label }
        return color
    }
    
}
