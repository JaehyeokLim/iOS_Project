//
//  ViewController.swift
//  Project01
//
//  Created by Jaehyeok Lim on 2022/07/16.
//

import UIKit
import SnapKit
import CoreMotion
import AVFoundation
import MediaPlayer
import CoreLocation
import HealthKit

extension UIColor {
    static let backgroundColor = UIColor(named: "BackgroundColor")
}

class ViewController: UIViewController {
    
    var motionManager = CMMotionManager()
    var altimeterManger = CMAltimeter()
    
    var accArray: [String] = []
    var rotArray: [String] = []
    var preArray: [String] = []
    var locArray: [CLLocation] = []
    
//    var accMobiusList: String = ""
//    var rotMobiusList: String = ""
//    var preMobiusList: String = ""
    
    let sensorNameArray: [String] = ["mAcc", "mGyr", "mPre"]
    
    var accList: String = ""
    var rotList: String = ""
    var preList: String = ""
    
    var count: Int = 1
    
    var secondsLeft: Int = 900
    var secondsSave: Int = 900
    
    var locationManager = CLLocationManager()
    
    let healthStore = HKHealthStore()
    let typeToShare:HKCategoryType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    let typeToRead:HKSampleType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    var sleepData:[HKCategorySample] = []
    
    let mainLabel: UILabel = {
        let mainLabel = UILabel()
        
        mainLabel.text = "Ready"
        mainLabel.font = UIFont.boldSystemFont(ofSize: 30)
        mainLabel.textColor = UIColor.systemBlue
        mainLabel.textAlignment = .center
        
        return mainLabel
    }()
    
    let timerLabel: UILabel = {
        let timerLabel = UILabel()
        
        timerLabel.font = UIFont.boldSystemFont(ofSize: 50)
        timerLabel.textColor = UIColor.systemBlue
        timerLabel.textAlignment = .center
        
        return timerLabel
    }()
    
    let updateCountNumberLabel: UILabel = {
        let updateCountNumberLabel = UILabel()
        
        updateCountNumberLabel.text = "0"
        updateCountNumberLabel.font = UIFont.boldSystemFont(ofSize: 50)
        updateCountNumberLabel.textColor = UIColor.systemBlue
        updateCountNumberLabel.textAlignment = .center
        
        return updateCountNumberLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        configure()
        
        createCSV()
    
        getLocationUsagePermission()
        
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestAlwaysAuthorization()
        
        startFunction()
        
        if CLLocationManager.locationServicesEnabled() {
            print("위치 서비스 On 상태")
            locationManager.startUpdatingLocation() //위치 정보 받아오기 시작
            print(locationManager.location?.coordinate as Any)
        } else {
            print("위치 서비스 Off 상태")
        }
    }
    
    func timerFunction() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (t) in
            //남은 시간(초)에서 1초 빼기
            self.secondsLeft -= 1

            //남은 분
            let minutes = self.secondsLeft / 60
            //그러고도 남은 초
            let seconds = self.secondsLeft % 60

            //남은 시간(초)가 0보다 크면
            if self.secondsLeft >= 0 {
                self.timerLabel.text = "\(minutes):\(seconds)"
            } else {
                self.secondsLeft = self.secondsSave
            }
        })
    }
    
    func configureLayout() {
        view.backgroundColor = UIColor.backgroundColor
        
        view.addSubview(mainLabel)
        
        mainLabel.snp.makeConstraints { make in
            make.top.equalTo(view).offset(100)
            make.width.equalTo(view)
        }
        
        view.addSubview(timerLabel)
        
        timerLabel.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(view)
        }
        
        view.addSubview(updateCountNumberLabel)
        
        updateCountNumberLabel.snp.makeConstraints { make in
            make.top.equalTo(timerLabel).offset(100)
            make.width.equalTo(view)
        }
    }
    
    func configure() {
        if !HKHealthStore.isHealthDataAvailable() {
            requestAuthorization()
        }else {
//            retrieveSleepData()
        }
    }
    
    func requestAuthorization() {
        
        self.healthStore.requestAuthorization(toShare: Set([typeToShare!]), read: Set([typeToRead!])) { success, error in
            if error != nil {
                print(error.debugDescription)
            }else{
                if success {
                    print("권한이 허락되었습니다.")
                }else{
                    print("권한이 아직 없어요.")
                }
            }
        }
    }
    
//    func retrieveSleepData() {
//        let start = makeStringToDate(str: "2021-05-01")
//        let end = Date()
//        let predicate = HKQuery.predicateForSamples(withStart:start, end: end, options: .strictStartDate)
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
//        let query = HKSampleQuery(sampleType: typeToRead!, predicate: predicate, limit: 30, sortDescriptors: [sortDescriptor]) { [weak self] (query, sleepResult, error) -> Void in
//
//            if error != nil {
//                return
//            }
//
//            if let result = sleepResult {
//                DispatchQueue.main.async {
//                    //수면 데이터에 받아온 데이터를 설정해줌.
//                    self?.sleepData = result as? [HKCategorySample] ?? []
//                    self?.table.reloadData()
//                }
//            }
//        }
//        healthStore.execute(query)
//    }
    
    func startFunction() {
        motionManagerInit()
        Timer.scheduledTimer(timeInterval: 900, target: self, selector: #selector(ViewController.aaa), userInfo: nil, repeats: true)
        timerFunction()
        mainLabel.text = "Start!"
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
        
//        print("\(acceleration.x)")
        if accArray.count < 45 {
            accArray.append(String(format: "%.3f", acceleration.x))
            accArray.append(String(format: "%.3f", acceleration.y))
            accArray.append(String(format: "%.3f", acceleration.z))

        } else {
        
            sendToData(array: accArray, time: currentDate, caseType: "mAcc")
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
        
            sendToData(array: rotArray, time: currentDate, caseType: "mGyr")
            rotArray.removeAll()
        }
    }
    
    func outputAlititudeData(_ altitude: CMAltitudeData) {
        let currentDate = Date()
            
        preArray.append(String(format: "%.3f", Double(truncating: altitude.pressure) * 10))

        if preArray.count >= 1 {
            
            sendToData(array: preArray, time: currentDate, caseType: "mPre")
            preArray.removeAll()
        }
    }
    
    func sendToData(array: [String], time: Date, caseType: String) {
        
        if caseType == "mAcc" {
            
            accList += String(format: "%.0f", time.timeIntervalSince1970)

            for i in 0..<array.count {
                accList += "," + array[i]
            }
            
            accList += "\n"
            
        } else if caseType == "mGyr" {
            
            rotList += String(format: "%.0f", time.timeIntervalSince1970)

            for i in 0..<array.count {
                rotList += "," + array[i]
            }
            
            rotList += "\n"
            
        } else if caseType == "mPre" {
            
            preList += String(format: "%.0f", time.timeIntervalSince1970)

            preList += "," + array[0]

            preList += "\n"
        }
    }
    
    @objc func aaa() {
        writeCSV(sensorData: accList, caseType: "mAcc", index: count)
        writeCSV(sensorData: rotList, caseType: "mGyr", index: count)
        writeCSV(sensorData: preList, caseType: "mPre", index: count)
        
        readFile(fileNumber: count)
        
        print(count)
        count += 1
        updateCountNumberLabel.text = String(count)

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
    
    func csvDataPostToMobius(csvData: String, conName: String) {
        let semaphore = DispatchSemaphore (value: 0)

        let parameters = "{\n    \"m2m:cin\": {\n        \"con\": \"\(csvData)\"\n    }\n}"
        let postData = parameters.data(using: .utf8)

        var request = URLRequest(url: URL(string: "http://114.71.220.59:7579/Mobius/S998/mobile/\(conName)")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("12345", forHTTPHeaderField: "X-M2M-RI")
        request.addValue("SIWLTfduOpL", forHTTPHeaderField: "X-M2M-Origin")
        request.addValue("application/vnd.onem2m-res+json; ty=4", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard data != nil else {
              print(String(describing: error))
              semaphore.signal()
              return
          }
//            print(String(data: data, encoding: .utf8)!)
            print("\(conName) Data is served.")
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()
    }
    
    func readFile(fileNumber: Int) {
        
        for fileName in sensorNameArray {
            let fileManager = FileManager.default
            
            let folderName = "CSVFolder"
            let csvFileName = "\(fileName)_\(fileNumber).csv"
            
            let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directoryUrl = documentUrl.appendingPathComponent(folderName)
            let fileUrl = directoryUrl.appendingPathComponent(csvFileName)
            
            do {
                let dataFromPath: Data = try Data(contentsOf: fileUrl) // URL을 불러와서 Data타입으로 초기화
                let text: String = String(data: dataFromPath, encoding: .utf8) ?? "문서없음" // Data to String
                let data = text.replacingOccurrences(of: "\n", with: "")
                csvDataPostToMobius(csvData: data, conName: fileName)
                
            } catch let e {
                print(e.localizedDescription)
            }
        }
    }
}

extension ViewController: AVAudioPlayerDelegate,CLLocationManagerDelegate {
    
    func getLocationUsagePermission() {
            
            self.locationManager.requestWhenInUseAuthorization()

    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("GPS 권한 설정됨")
        case .restricted, .notDetermined:
            print("GPS 권한 설정되지 않음")
            getLocationUsagePermission()
        case .denied:
            print("GPS 권한 요청 거부됨")
            getLocationUsagePermission()
        default:
            print("GPS: Default")
        }
    }
}
