//
//  ViewController.swift
//  Project01
//
//  Created by Jaehyeok Lim on 2022/07/16.
//

import UIKit

extension UIColor {
    static let backgroundColor = UIColor(named: "BackgroundColor")
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
    }
    
    func configureLayout() {
        view.backgroundColor = UIColor.backgroundColor
    }
}

