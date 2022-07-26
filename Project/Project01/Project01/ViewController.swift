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
    
    var list = ""
    
    var motionManager = CMMotionManager()
    var altimeterManger = CMAltimeter()
    
    var accState:Bool = false
    var rotState:Bool = false
    var preState:Bool = false
    
    var accArray:[String] = []
    var rotArray:[String] = []
    var preArray:[String] = []
    
    var currentDate = Date().timeIntervalSince1970
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        print(currentDate)
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
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
        
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
    }
    
    @objc func buttonAction(_ sender: UIButton) {
        motionManagerInit()
        
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
            print("hello")

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
        print("accX = " + String(format: "%.2f", acceleration.x))
        
        print("accY = " + String(format: "%.2f", acceleration.y))

        print("accZ = " + String(format: "%.2f", acceleration.z))

        
        if accArray.count != 15 {
            accArray.append(String(fabs(acceleration.x)))
            accArray.append(String(fabs(acceleration.y)))
            accArray.append(String(fabs(acceleration.z)))
            
        } else {
            
            if accState == false {
                accState = true
                sendToData(array: accArray)
            }
        }
    }
    
    func outputRotationData(_ rotation: CMRotationRate) {
        print("rotX = " + String(format: "%.2f", rotation.x))
        
        print("rotY = " + String(format: "%.2f", rotation.y))
        
        print("rotZ = " + String(format: "%.2f", rotation.z))
        
        if rotArray.count != 15 {
            rotArray.append(String(fabs(rotation.x)))
            rotArray.append(String(fabs(rotation.y)))
            rotArray.append(String(fabs(rotation.z)))
            
        } else {
            
            if rotState == false {
                rotState = true
                sendToData(array: rotArray)
            }
        }
    }
    
    func outputAlititudeData(_ altitude: CMAltitudeData) {
//        print("relativeAltitude = \(altitude.relativeAltitude)")
        print("pressure = \(altitude.pressure)")
        
        if preArray.count != 1 {
            preArray.append(String(Double(truncating: altitude.pressure)))
        } else {
            
            if preState == false {
                preState = true
                sendToData(array: preArray)
            }
        }
    }
    
    func sendToData(array: [String]) {
        let data = String(currentDate)
        let startIndexForYear = data.index(data.startIndex, offsetBy: 0)
        let endIndexForYear = data.index(data.startIndex, offsetBy: 3)
        let startIndexForOther = data.index(data.startIndex, offsetBy: 4)
        let rangeYear = startIndexForYear...endIndexForYear
        let rangeOther = startIndexForOther..<data.endIndex
        
        if list.count != 0 {
            list += "\n" + data[rangeYear]
            list += "," + data[rangeOther]
        } else {
            list += data[rangeYear]
            list += "," + data[rangeOther]
        }
        
        for i in 0..<array.count {
            list += ","+array[i]
        }
        
        if accState == true && rotState == true {
            writeCSV(sensorData: list)
        }
    }
    
    func createCSV() {
        let fileManager = FileManager.default
        
        let folderName = "newCSVFolder"
        let csvFileName = "myCSVFile.csv"
        
        let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directoryUrl = documentUrl.appendingPathComponent(folderName)
        let fileUrl = directoryUrl.appendingPathComponent(csvFileName)

        do {
            try fileManager.createDirectory(atPath: directoryUrl.path, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError {
            print("폴더 생성 에러: \(error)")
        }
        
        fileManager.createFile(atPath: fileUrl.path, contents: .none, attributes: nil)
    }
    
    func writeCSV(sensorData: String) {
        let fileManager = FileManager.default
        
        let folderName = "newCSVFolder"
        let csvFileName = "myCSVFile.csv"
        
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

