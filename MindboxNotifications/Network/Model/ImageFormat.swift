//
//  ImageFormat.swift
//  MindboxNotifications
//
//  Created by Ihor Kandaurov on 22.06.2021.
//  Copyright © 2021 Mindbox. All rights reserved.
//

import UIKit.UIImage
import MindboxLogger

enum ImageFormat: String {
    case png, jpg, gif

    init?(_ data: Data) {
        if let type = ImageFormat.get(from: data) {
            self = type
        } else {
            return nil
        }
    }

    var `extension`: String {
        return rawValue
    }
}

extension ImageFormat {
    static func get(from data: Data) -> ImageFormat? {
        guard let firstByte = data.first else { 
            Logger.common(message: "ImageFormat: Failed to get firstByte", level: .error, category: .notification)
            return nil
        }
        switch firstByte {
        case 0x89:
            return .png
        case 0xFF:
            return .jpg
        case 0x47:
            return .gif
        default:
            Logger.common(message: "ImageFormat: Failed to get image format", level: .error, category: .notification)
            return nil
        }
    }
    
    static func getImage(imageData: Data?) -> UIImage? {
        guard let imageData else { return nil  }
        
        let imageFormat = ImageFormat.get(from: imageData)
        
        switch imageFormat {
        case .gif:
            return animatedImage(withGIFData: imageData)
        default:
            return UIImage(data: imageData)
        }
    }
    
    private static func animatedImage(withGIFData data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        
        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var gifDuration = 0.0
        
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil),
               let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
               let frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) {
                gifDuration += frameDuration.doubleValue
            }
            
            let frameImage = UIImage(cgImage: cgImage)
            frames.append(frameImage)
        }
        
        let animatedImage = UIImage.animatedImage(with: frames, duration: gifDuration)
        return animatedImage
    }
}
