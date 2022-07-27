//
//  ViewController.swift
//  Project01
//
//  Created by Jaehyeok Lim on 2022/07/16.
//

import UIKit
import SnapKit
import CoreMotion

extension UIColor {
    static let backgroundColor = UIColor(named: "BackgroundColor")
}

class ViewController: UIViewController {
    
    var motionManager = CMMotionManager()
    var altimeterManger = CMAltimeter()
    
    var accArray: [String] = []
    var rotArray: [String] = []
    var preArray: [String] = []
    
    var accList: String = ""
    var rotList: String = ""
    var preList: String = ""
    
    var count: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(ViewController.aaa), userInfo: nil, repeats: true)
        configureLayout()
        createCSV()
    }
    
    func configureLayout() {
        view.backgroundColor = UIColor.backgroundColor
        
        let button = UIButton()
        
        button.setImage(UIImage(systemName: "cursorarrow.click"), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        
        view.addSubview(button)
        
        button.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
        
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
    }
    
    @objc func buttonAction(_ sender: UIButton) {
        motionManagerInit()
        print("start")
    }
    
    func motionManagerInit() {
        motionManager.accelerometerUpdateInterval = 1 / 15
        motionManager.gyroUpdateInterval = 1 / 15
        
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
        }
    }
    
    func outputAccelerationData(_ acceleration: CMAcceleration) {
        let currentDate = Date()
        
        if accArray.count < 45 {
            accArray.append(String(format: "%.3f", acceleration.x))
            accArray.append(String(format: "%.3f", acceleration.y))
            accArray.append(String(format: "%.3f", acceleration.z))

        } else {
        
            sendToData(array: accArray, time: currentDate, caseType: "Acceleration")
            accArray.removeAll()
        }
    }
    
    func outputRotationData(_ rotation: CMRotationRate) {
        let currentDate = Date()

        if rotArray.count < 45 {
            rotArray.append(String(format: "%.3f", rotation.x))
            rotArray.append(String(format: "%.3f", rotation.y))
            rotArray.append(String(format: "%.3f", rotation.z))
            
        } else {
        
            sendToData(array: rotArray, time: currentDate, caseType: "Rotation")
            rotArray.removeAll()
        }
    }
    
    func outputAlititudeData(_ altitude: CMAltitudeData) {
        let currentDate = Date()
            
        preArray.append(String(format: "%.3f", Double(truncating: altitude.pressure) * 10))

        if preArray.count >= 1 {
            
            sendToData(array: preArray, time: currentDate, caseType: "Pressure")
            preArray.removeAll()
        }
    }
    
    func sendToData(array: [String], time: Date, caseType: String) {
        
        if caseType == "Acceleration" {
            
            accList += String(format: "%.0f", time.timeIntervalSince1970)
            
            for i in 0..<array.count {
                accList += "," + array[i]
            }
            
            accList += "\n"
            
        } else if caseType == "Rotation" {
            
            rotList += String(format: "%.0f", time.timeIntervalSince1970)
            
            for i in 0..<array.count {
                rotList += "," + array[i]
            }
            
            rotList += "\n"
            
        } else if caseType == "Pressure" {
            
            preList += String(format: "%.0f", time.timeIntervalSince1970)
            
            preList += "," + array[0]
            
            preList += "\n"
        }
    }
    
    @objc func aaa() {
        writeCSV(sensorData: accList, caseType: "Acceleration", index: count)
        writeCSV(sensorData: rotList, caseType: "Rotation", index: count)
        writeCSV(sensorData: preList, caseType: "Pressure", index: count)
        
        count += 1
        
        accList = ""; rotList = ""; preList = ""
    }
    
    func createCSV() {
        let fileManager = FileManager.default
        
        let folderName = "CSVFolder"
        
        let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directoryUrl = documentUrl.appendingPathComponent(folderName)

        do {
            try fileManager.createDirectory(atPath: directoryUrl.path, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError {
            print("폴더 생성 에러: \(error)")
        }
    }
    
    func writeCSV(sensorData: String, caseType: String, index: Int) {
        let fileManager = FileManager.default
        
        let folderName = "CSVFolder"
        let csvFileName = "\(caseType)_\(index).csv"
        
        let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directoryUrl = documentUrl.appendingPathComponent(folderName)
        let fileUrl = directoryUrl.appendingPathComponent(csvFileName)
        
        let fileData = sensorData.data(using: .utf8)
            
            do {
                try fileData?.write(to: fileUrl)
                
                print("Writing CSV to: \(fileUrl.path)")
            }
            catch let error as NSError {
                print("CSV파일 생성 에러: \(error)")
            }
    }
}

