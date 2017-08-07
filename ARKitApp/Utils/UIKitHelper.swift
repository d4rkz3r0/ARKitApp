//
//  UIKitHelper.swift
//  ARKitApp
//
//  Created by Steve Kerney on 8/7/17.
//  Copyright © 2017 d4rkz3r0. All rights reserved.
//

import UIKit

extension ViewController
{
    //Computed Properties
    var viewCenterPoint: CGPoint
    {
        let viewSize = view.bounds;
        return CGPoint(x: viewSize.width / 2.0, y: viewSize.height / 2.0);
    }
    
    func displayMessage(_ message: String, label: UILabel, duration: Double = 2.0)
    {
        label.text = message;
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration)
        {
            if label.text == message { label.text = ""; }
        }
    }
}
