//
//  SignDetection.swift
//  SignName_SceneKit
//
//  Created by Jeon Jimin on 2022/08/30.
//

import Foundation
import Vision

class SignDetection {
    static func createSignDetection() -> VNCoreMLModel {
        let defaultConfig = MLModelConfiguration()
        
        let signDetectionWrapper = try? SignLanguageDetection_E(configuration: defaultConfig)
        guard let signDetection = signDetectionWrapper else {
            fatalError("app failed to create an sign detectio model instance.")
        }
        
        let signDetectionModel = signDetection.model
        
        guard let signDetectionVisonModel = try? VNCoreMLModel(for: signDetectionModel) else {
                fatalError("App failed to create a VNCoreMLModel instance")
        }
        return signDetectionVisonModel
    }
}
