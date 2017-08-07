//
//  SelectableButton.swift
//  ARKitApp
//
//  Created by Steve Kerney on 8/7/17.
//  Copyright © 2017 d4rkz3r0. All rights reserved.
//

import UIKit

class SelectableButton: UIButton
{
    override var isSelected: Bool
        {
            didSet
            {
                if isSelected
                {
                    layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1);
                    layer.borderWidth = 3.0;
                }
                else
                {
                    layer.borderWidth = 0.0;
                }
            }
        }
}
