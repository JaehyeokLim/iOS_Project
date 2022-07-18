//
//  ViewController.swift
//  Project01
//
//  Created by Jaehyeok Lim on 2022/07/16.
//

import UIKit
import CoreMotion

extension UIColor {
    static let backgroundColor = UIColor(named: "BackgroundColor")
}

class ViewController: UIViewController {

    var motionManager = CMMotionManager()
    var motion = CMMotionManager()
    var currentMaxAccelX: Double = 0
    var currentMaxAccelY: Double = 0
    var currentMaxAccelZ: Double = 0
    var currentMaxRotX: Double = 0
    var currentMaxRotY: Double = 0
    var currentMaxRotZ: Double = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        motionManagerInit()
    }
    
    func configureLayout() {
        view.backgroundColor = UIColor.backgroundColor
    }
    
    func motions() {
        motion.startAccelerometerUpdates()
        
        motion.accelerometerUpdateInterval = 3
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let data = self.motion.accelerometerData {
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                
                print("x, y, z = " + "\(x), \(y), \(z)")
            }
        }
    }
    
    func motionManagerInit() {
        motionManager.accelerometerUpdateInterval = 5
        motionManager.gyroUpdateInterval = 5

        if let currentValue = OperationQueue.current {
            motionManager.startAccelerometerUpdates(to: currentValue, withHandler: {
                    (accelerometerData: CMAccelerometerData!, error: Error!) -> Void in
                    self.outputAccelerationData(accelerometerData.acceleration)
                    if (error != nil) {
                        print("\(error!)")
                    }
                })
            
            motionManager.startGyroUpdates(to: currentValue, withHandler: {
                (gyroData: CMGyroData!, error: Error!) -> Void in
                self.outputRotationData(gyroData.rotationRate)
                if (error != nil) {
                    print("\(error!)")
                }
            })
        }
    }
    
    func outputAccelerationData(_ acceleration: CMAcceleration) {
        print("accX = " + String(format: "%.2f", acceleration.x))

        if fabs(acceleration.x) > fabs(currentMaxAccelX) {
            currentMaxAccelX = acceleration.x
        }
        
        print("accY = " + String(format: "%.2f", acceleration.y))

        if fabs(acceleration.y) > fabs(currentMaxAccelY) {
            currentMaxAccelY = acceleration.y
        }
        
        print("accZ = " + String(format: "%.2f", acceleration.z))
        
        if fabs(acceleration.z) > fabs(currentMaxAccelZ) {
            currentMaxAccelZ = acceleration.z
        }
        
        print("maxAccX = " + String(format: "%.2f", currentMaxAccelX))
        print("maxAccY = " + String(format: "%.2f", currentMaxAccelY))
        print("maxAccZ = " + String(format: "%.2f", currentMaxAccelZ))
    }
    
    func outputRotationData(_ rotation: CMRotationRate) {
        print("rotX = " + String(format: "%.2f", rotation.x))
        
        if fabs(rotation.x) > fabs(currentMaxRotX) {
            currentMaxRotX = rotation.x
        }
        
        print("rotY = " + String(format: "%.2f", rotation.y))
        
        if fabs(rotation.y) > fabs(currentMaxRotY) {
            currentMaxRotY = rotation.y
        }
        print("rotZ = " + String(format: "%.2f", rotation.z))
        
        if fabs(rotation.z) > fabs(currentMaxRotZ) {
            currentMaxRotZ = rotation.z
        }
        
        print("maxRotX = " + String(format: "%.2f", currentMaxRotX))
        print("maxRotY = " + String(format: "%.2f", currentMaxRotY))
        print("maxRotZ = " + String(format: "%.2f", currentMaxRotZ))
    }
}

