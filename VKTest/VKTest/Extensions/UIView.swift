//
//  UIView.swift
//  VKTest
//
//  Created by Артём Калинин on 02.02.2022.
//

import UIKit

public extension UIView {

  func addSubviews(_ views: UIView...) {
    for view in views {
      addSubview(view)
    }
  }

}
