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
    var altimeterManger = CMAltimeter()
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
    
    func motionManagerInit() {
        motionManager.accelerometerUpdateInterval = 5 / 15
        motionManager.gyroUpdateInterval = 5 / 15
        
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
            
            if CMAltimeter.isRelativeAltitudeAvailable() {
                altimeterManger.startRelativeAltitudeUpdates(to: currentValue, withHandler: {
                    (altimeterData: CMAltitudeData!, error: Error!) -> Void in
                    self.outputAlititudeData(altimeterData)
                    if (error != nil) {
                        print("\(error!)")
                    }
                })
            }
            
//            if CMAltimeter.isAbsoluteAltitudeAvailable() {
//                altimeterManger.startAbsoluteAltitudeUpdates(to: currentValue, withHandler: {
//                    (altimeterData: CMAbsoluteAltitudeData!, error: Error!) -> Void in
//                    self.outputAbsoluteAlitituedData(altimeterData)
//                    if (error != nil) {
//                        print("\(error!)")
//                    }
//                })
//            }
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
    
    func outputAlititudeData(_ altitude: CMAltitudeData) {
        print("relativeAltitude = \(altitude.relativeAltitude)")
        print("pressure = \(altitude.pressure)")
    }
    
    func outputAbsoluteAlitituedData(_ altitude: CMAbsoluteAltitudeData) {
        print("absoluteAltitude = \(altitude.altitude)")
    }
}

