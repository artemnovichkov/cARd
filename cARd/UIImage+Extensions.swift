//
//  UIImage+Extensions.swift
//  cARd
//
//  Created by Artem Novichkov on 03/08/2017.
//  Copyright © 2017 Rosberry. All rights reserved.
//

import UIKit

extension UIImage {
    
    func split() -> (left: UIImage, right: UIImage)? {
        guard let cgImage = cgImage else {
            return nil
        }
        let halfWidth = size.width / 2
        let height = size.height
        let rightPartPoint = CGPoint(x: halfWidth, y: 0)
        let halfSize = CGSize(width: halfWidth, height: height)
        let leftPartFrame = CGRect(origin: .zero, size: halfSize)
        let rightPartFrame = CGRect(origin: rightPartPoint, size: halfSize)
        guard
            let leftPartImage = cgImage.cropping(to: leftPartFrame),
            let rightPartImage = cgImage.cropping(to: rightPartFrame) else {
                return nil
        }
        return (UIImage(cgImage: leftPartImage), UIImage(cgImage: rightPartImage))
    }
}
