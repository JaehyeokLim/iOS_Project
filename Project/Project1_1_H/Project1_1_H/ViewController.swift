import UIKit
import HealthKit
import SnapKit
import UserNotifications
import CoreLocation

public var userSleepStartDate: String = ""
public var userSleepEndDate: String = ""
public var alarmState: Bool = false

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    let typeToShare:HKCategoryType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    let typeToRead:HKSampleType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    var sleepData:[HKCategorySample] = []
    let startDate = Date()
    var uiList = [UIView]()
    var buttonState: Bool = false
    var hours: Int = 0
    var minutes: Int = 0
    var seconds: Int = 0
    var hoursText: String = ""
    var minutesText: String = ""
    var secondsText: String = ""
    var timer: Timer?
    var sleepDateLoadTimer: Timer?
    var secondsLeft: Int = 900
    var secondsSave: Int = 900
    let notificationCenter = UNUserNotificationCenter.current()
    var locationManager = CLLocationManager()
    var sleepList: String = ""
    var sleepStringDataArray: [String] = []
    let modelName = UIDevice.modelName
    
    let alarmButton: UIButton = {
        let alarmButton = UIButton()
            
        alarmButton.setImage(UIImage(systemName: "alarm.fill"), for: .normal)
        alarmButton.tintColor = UIColor.systemBlue
        alarmButton.contentVerticalAlignment = .fill
        alarmButton.contentHorizontalAlignment = .fill

        return alarmButton
    }()
    
    let sleepAndAwakeButton: UIButton = {
        let sleepAndAwakeButton = UIButton()

        sleepAndAwakeButton.setImage(UIImage(systemName: "sun.max.fill"), for: .normal)
        sleepAndAwakeButton.tintColor = UIColor.systemYellow
        sleepAndAwakeButton.contentHorizontalAlignment = .fill
        sleepAndAwakeButton.contentVerticalAlignment = .fill
        
        return sleepAndAwakeButton
    }()
    
    let timerLabel: UILabel = {
        let timerLabel = UILabel()
       
        timerLabel.text = ""
        timerLabel.font = UIFont.boldSystemFont(ofSize: 30)
        timerLabel.textAlignment = .center
        timerLabel.textColor = UIColor.black
        
        return timerLabel
    }()
    
    let loadTimerLabel: UILabel = {
        let loadTimerLabel = UILabel()
        
        loadTimerLabel.text = ""
        loadTimerLabel.font = UIFont.boldSystemFont(ofSize: 30)
        loadTimerLabel.textAlignment = .center
        loadTimerLabel.textColor = UIColor.black
        
        return loadTimerLabel
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        UserDefaults.standard.set(false, forKey: "alarmCheck")
        UserDefaults.standard.set(true, forKey: "alarmCheck")
        
        table.reloadData()
        
        requestAuthorization()
        configure()
        timerFunction()
        requestNotificationAuthorization()
        sendNoti()
        
        getLocationUsagePermission()
        
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestAlwaysAuthorization()
                
        if CLLocationManager.locationServicesEnabled() {
            print("위치 서비스 On 상태")
            locationManager.startUpdatingLocation() //위치 정보 받아오기 시작
            print(locationManager.location?.coordinate as Any)
        } else {
            print("위치 서비스 Off 상태")
        }
        
//        createCSV()
//        aaa()
    }

    override func viewWillAppear(_ animated: Bool) {
        table.reloadData()
    }

    let table: UITableView = {
        let table = UITableView()

        table.rowHeight = 44
        table.register(ViewTableCell.self, forCellReuseIdentifier: "ViewTableCell")

        return table
    }()
    
    func configure() {
        view.backgroundColor = .white
        table.backgroundColor = .white

        table.dataSource = self
//        table.delegate = self

        uiList = [table, sleepAndAwakeButton, timerLabel, loadTimerLabel, alarmButton]
        
        for uiListName in uiList {
            view.addSubview(uiListName)
        }

        table.snp.makeConstraints { make in
            make.top.equalTo(view).offset(400)
            make.bottom.leading.trailing.equalTo(view)
        }
        
        sleepAndAwakeButton.snp.makeConstraints { make in
            make.top.equalTo(view).offset(150)
            make.leading.equalTo(view).offset(150)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
        
        timerLabel.snp.makeConstraints { make in
            make.top.equalTo(view).offset(80)
            make.width.equalTo(view)
        }
        
        loadTimerLabel.snp.makeConstraints { make in
            make.top.equalTo(sleepAndAwakeButton).offset(150)
            make.width.equalTo(view)
        }
        
        alarmButton.snp.makeConstraints { make in
            make.top.equalTo(view).offset(80)
            make.trailing.equalTo(view).offset(-30)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }


        if !HKHealthStore.isHealthDataAvailable() {
            requestAuthorization()

        } else {
            retrieveSleepData()
        }
        
        sleepAndAwakeButton.addTarget(self, action: #selector(sleepAndAwakeButtonAction(_:)), for: .touchUpInside)
        alarmButton.addTarget(self, action: #selector(alarmButtonAction(_:)), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(showPage(_:)), name: NSNotification.Name("showPage"), object: nil)
    }
    
    func createCSV() {
        let fileManager = FileManager.default
        
        let folderName = "CSVFolder2"
        
        let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directoryUrl = documentUrl.appendingPathComponent(folderName)

        do {
            try fileManager.createDirectory(atPath: directoryUrl.path, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError {
            print("폴더 생성 에러: \(error)")
        }
    }
    
    func sendToData(quary: [HKSample]) {
        var sleepData:[HKCategorySample] = []
        sleepData = quary as? [HKCategorySample] ?? []

        print("불러오기 완료")

        for indexPath in 0..<sleepData.count {
            print("\(indexPath)")
            let sleep = sleepData[indexPath]
            let date = dateToString(date: sleep.startDate)
            let start = dateToStringOnlyTime(date: sleep.startDate)
            let end = dateToStringOnlyTime(date: sleep.endDate)
            let data = sleepStringDataArray[indexPath]
            
            sleepList += "\(data), \(date), \(start), \(end)\n"

        }
        writeCSV(sensorData: sleepList, caseType: "sleeep", index: 0)

        sleepStringDataArray.removeAll()
        sleepList = ""
    
    }
    
    func writeCSV(sensorData: String, caseType: String, index: Int) {
        let fileManager = FileManager.default
        
        let folderName = "CSVFolder2"
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
    
    @objc func showPage(_ notification:Notification) {
        let myViewController = DatePicker()
        
        myViewController.modalPresentationStyle = .fullScreen
        present(myViewController, animated: true, completion: nil)
        
        navigationController?.pushViewController(myViewController, animated: true)
    }
    
    @objc func alarmButtonAction(_: UIButton) {
        datePickerPreview()
    }
    
    func datePickerPreview() {
        let myViewController = DatePicker()
        
        myViewController.modalPresentationStyle = .fullScreen
        present(myViewController, animated: true, completion: nil)
    }
    
    func requestNotificationAuthorization() {
        let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]

        notificationCenter.requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func sendNoti() {
        
        let sleepNotification = UNMutableNotificationContent()
        
        sleepNotification.title = "일어나셨나요? 알림을 클릭하셔서 입력해주세요!"
        sleepNotification.title = "클릭해주세요!"
        
        var dates = DateComponents()
        
        dates.hour = 14
        dates.minute = 16
        
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dates, repeats: true)
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: sleepNotification, trigger: trigger)
        let request = UNNotificationRequest(identifier: "timerdone", content: sleepNotification, trigger: trigger)
   

        notificationCenter.add(request)
        
    }
    
    func timerFunction() {
        sleepDateLoadTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (t) in
            //남은 시간(초)에서 1초 빼기
            self.secondsLeft -= 1

            let hours = self.secondsLeft / 600
            //남은 분
            let minutes = self.secondsLeft / 60
            //그러고도 남은 초
            let seconds = self.secondsLeft % 60

            //남은 시간(초)가 0보다 크면
            if self.secondsLeft >= 0 {
                self.loadTimerLabel.text = "\(hours):\(minutes):\(seconds)"
            } else {
                self.secondsLeft = self.secondsSave
            }
        })
    }
    
    func loadCycleFunction()  {
        
    }

    
    @objc func sleepAndAwakeButtonAction(_: UIButton) {
        
        let date1 = Date()
        
        if !buttonState {
            sleepAndAwakeButton.setImage(UIImage(systemName: "moon.fill"), for: .normal)
            sleepAndAwakeButton.tintColor = UIColor.systemPurple
            
            let sleepStartAlert = UIAlertController(title: "알림", message: "수면모드를 시작하시겠습니까?", preferredStyle: .alert)
            let sleepStartAlertOkButton = UIAlertAction(title: "OK", style: .default) { _ in
                
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (t) in
                    self.seconds += 1

                    if self.seconds > 59 {
                        self.seconds = 0
                        self.minutes += 1
                    }
                    
                    if self.minutes > 59 {
                        self.minutes = 0
                        self.hours += 1
                    }
                    
                    if self.hours < 10 {
                        self.hoursText = "0\(self.hours)"
                    } else { self.hoursText = "\(self.hours)" }
                    
                    if self.minutes < 10 {
                        self.minutesText = "0\(self.minutes)"
                    } else { self.hoursText = "\(self.hours)" }
                    
                    if self.seconds < 10 {
                        self.secondsText = "0\(self.seconds)"
                    } else { self.secondsText = "\(self.seconds)" }
                    
                    self.timerLabel.text = "\(self.hoursText):\(self.minutesText):\(self.secondsText)"
                })
            }
            
            let sleepStartAlertCancelButton = UIAlertAction(title: "cancel", style: .cancel) { (sleepStartAlertOkButton) in
                
            }
        
            sleepStartAlert.addAction(sleepStartAlertOkButton)
            sleepStartAlert.addAction(sleepStartAlertCancelButton)
            
            self.present(sleepStartAlert, animated: true, completion: nil)
            
        } else {
            sleepAndAwakeButton.setImage(UIImage(systemName: "sun.max.fill"), for: .normal)
            sleepAndAwakeButton.tintColor = UIColor.systemYellow
            
            let sleepEndAlert = UIAlertController(title: "알림", message: "수면모드를 끝냅니다", preferredStyle: .alert)
            
            let sleepEndAlertOkButton = UIAlertAction(title: "OK", style: .default) { [self] (ok) in

                let date2 = Date()

                saveSleepData(start: date1, end: date2)
                
                print("완료 시작 시간:\(date1), 끝난 시간: \(date2)")
                
                resetTimer()
            }
            
            let sleepEndAlertCancelButton = UIAlertAction(title: "cancel", style: .cancel) { (sleepEndAlertCancelButton) in
                
            }
        
            sleepEndAlert.addAction(sleepEndAlertOkButton)
            sleepEndAlert.addAction(sleepEndAlertCancelButton)
            
            self.present(sleepEndAlert, animated: true, completion: nil)
        }
        
        buttonState = !buttonState
    }

    func resetTimer() {
        timer?.invalidate()
        timer = nil
        timerLabel.text = ""
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
    
    func saveSleepData(start: Date, end: Date) {
        let object = HKCategorySample(type: typeToShare!, value: HKCategoryValueSleepAnalysis.inBed.rawValue, start: start,end: end)
        healthStore.save(object, withCompletion: { (success, error) -> Void in
            if error != nil {
                return
            }
            if success {
                print("수면 데이터 저장 완료!")
                self.retrieveSleepData()
            } else {
                print("수면 데이터 저장 실패...")
            }
        })
        
        table.reloadData()
    }

//    func retrieveSleepData() {
//        let start = makeStringToDate(str: "2021-04-01")
//        let end = Date()
//        let predicate = HKQuery.predicateForSamples(withStart:start, end: end, options: .strictStartDate)
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
//        let query = HKSampleQuery(sampleType: typeToRead!, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { [weak self] (query, sleepResult, error) -> Void in
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
//
//        healthStore.execute(query)
//    }
    
    func retrieveSleepData() {
        let start = makeStringToDate(str: "1999-05-01")
//        let end = Date()
        let end = makeStringToDate(str: "2022-01-01")

        let predicate = HKQuery.predicateForSamples(withStart:start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: typeToRead!, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { [weak self] (query, sleepResult, error) -> Void in
            if error != nil {
                return
            }
            if let result = sleepResult {
                DispatchQueue.main.async {
                    self?.sleepData = result as? [HKCategorySample] ?? []
                    self?.table.reloadData()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if let optionalSleepData = self?.sleepData {
                        if let model = self?.modelName {
                            for newData in optionalSleepData {
                                print("\(newData) = \(type(of: newData))")
                                let startCollectTime = Int(newData.startDate.timeIntervalSince1970)
                                let endCollectTime = Int(newData.endDate.timeIntervalSince1970)
                                let collectDevice = String(newData.source.name)

                                let collectedSleepTime = Int(newData.endDate.timeIntervalSince(newData.startDate))

                                let organizedSleepData = "\(startCollectTime),\(endCollectTime),\(collectDevice),\(collectedSleepTime)"

                                self?.sleepStringDataArray.append(organizedSleepData)
                            }
                        }
                    }
                    
                    self?.sendToData(quary: result)
                }
                
            }
            
        }

        healthStore.execute(query)
    }


//    // 작일 10:00:00 ~ 금일 09:59:59까지 24시간의 수면 데이터를 얻는 메소드
//        func getSleepPerDay(start: Date, end: Date) {
//            print("Sleep analysis start time = \(start)\nSleep analysis end time = \(end)\n\n")
//
//            guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
//            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
//            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
//
//            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { [weak self] (_, result, error) -> Void in
//                if error != nil {
//                    return
//                }
//
//                if let result = result {
//                    DispatchQueue.main.async {
//                        self?.sleepDataArray = result as? [HKCategorySample] ?? []
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                        if self!.sleepDataArray != [] {
//                            for newData in self!.sleepDataArray {
//                                print(newData)
//                                let startCollectTime = Int(newData.startDate.timeIntervalSince1970)
//                                let endCollectTime = Int(newData.endDate.timeIntervalSince1970)
//                                let collectDevice = String(newData.device?.model ?? "DeviceError")
//                                let collectedSleepTime = Int(newData.endDate.timeIntervalSince(newData.startDate))
//
//                                let organizedSleepData = "\(startCollectTime),\(endCollectTime),\(collectDevice),\(collectedSleepTime)"
//
//                                self?.sleepStringDataArray.append(organizedSleepData)
//                            }
//                        }
//                    }
//                }
//            }
//            healthStore.execute(query)
//        }
//
//    // 정리된 수면 데이터를 하나의 문자열로 만드는 메소드
//        @objc func organizeSleepDataToUpload() {
//            sleepStringToUpload += sleepStringDataArray[0]
//            print(sleepStringDataArray[0])
//
//            for index in 1..<sleepStringDataArray.count {
//                sleepStringToUpload += "," + sleepStringDataArray[index]
//                print(sleepStringDataArray[index])
//            }
//
//            sleepDataArray.removeAll()
//            sleepStringDataArray.removeAll()
//
//            print("\n\n\(sleepStringToUpload)")
//
//            sleepStringToUpload = ""
//        }
//
    
    func makeStringToDate(str:String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(abbreviation: "KST")

        return dateFormatter.date(from: str)!
    }

    func makeStringToDateWithTime(str:String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(abbreviation: "KST")

        return dateFormatter.date(from: str)!
    }

    func dateToString(date:Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

       return dateFormatter.string(from: date)
    }

    func dateToStringOnlyTime(date:Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

       return dateFormatter.string(from: date)
    }
    
    func csvDataPostToMobius(csvData: Date, start: String, end: String) {
        let semaphore = DispatchSemaphore (value: 0)

        let parameters = "{\n    \"m2m:cin\": {\n        \"con\": \"\(Int(csvData.timeIntervalSince1970)).\(start),\(end)\"\n    }\n}"
        let postData = parameters.data(using: .utf8)

        var request = URLRequest(url: URL(string: "http://114.71.220.59:7579/Mobius/S998/health/Sleep")!,timeoutInterval: Double.infinity)
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
            print("Data is served.")
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()
    }
    
    func checkTheSleepTime(time: Date) -> Bool {
        if time >= startDate {
            return true
        } else { return false}
    }
}

extension ViewController: UITableViewDataSource, CLLocationManagerDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sleepData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ViewTableCell", for: indexPath) as? ViewTableCell else { return UITableViewCell() }
        
        let sleep = sleepData[indexPath.row]
        let date = dateToString(date: sleep.startDate)
        let start = dateToStringOnlyTime(date: sleep.startDate)
        let end = dateToStringOnlyTime(date: sleep.endDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let aa = dateFormatter.date(from: date) {
            cell.transText(date: aa, start: start, end: end)
        }

        return cell
    }
    
    
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

public extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                       return "iPod touch (5th generation)"
            case "iPod7,1":                                       return "iPod touch (6th generation)"
            case "iPod9,1":                                       return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":           return "iPhone 4"
            case "iPhone4,1":                                     return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                        return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                        return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                        return "iPhone 5s"
            case "iPhone7,2":                                     return "iPhone 6"
            case "iPhone7,1":                                     return "iPhone 6 Plus"
            case "iPhone8,1":                                     return "iPhone 6s"
            case "iPhone8,2":                                     return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                        return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                        return "iPhone 7 Plus"
            case "iPhone10,1", "iPhone10,4":                      return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                      return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                      return "iPhone X"
            case "iPhone11,2":                                    return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                      return "iPhone XS Max"
            case "iPhone11,8":                                    return "iPhone XR"
            case "iPhone12,1":                                    return "iPhone 11"
            case "iPhone12,3":                                    return "iPhone 11 Pro"
            case "iPhone12,5":                                    return "iPhone 11 Pro Max"
            case "iPhone13,1":                                    return "iPhone 12 mini"
            case "iPhone13,2":                                    return "iPhone 12"
            case "iPhone13,3":                                    return "iPhone 12 Pro"
            case "iPhone13,4":                                    return "iPhone 12 Pro Max"
            case "iPhone14,4":                                    return "iPhone 13 mini"
            case "iPhone14,5":                                    return "iPhone 13"
            case "iPhone14,2":                                    return "iPhone 13 Pro"
            case "iPhone14,3":                                    return "iPhone 13 Pro Max"
            case "iPhone8,4":                                     return "iPhone SE"
            case "iPhone12,8":                                    return "iPhone SE (2nd generation)"
            case "iPhone14,6":                                    return "iPhone SE (3rd generation)"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":      return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":                 return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":                 return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                          return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                            return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                          return "iPad (7th generation)"
            case "iPad11,6", "iPad11,7":                          return "iPad (8th generation)"
            case "iPad12,1", "iPad12,2":                          return "iPad (9th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":                 return "iPad Air"
            case "iPad5,3", "iPad5,4":                            return "iPad Air 2"
            case "iPad11,3", "iPad11,4":                          return "iPad Air (3rd generation)"
            case "iPad13,1", "iPad13,2":                          return "iPad Air (4th generation)"
            case "iPad13,16", "iPad13,17":                        return "iPad Air (5th generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":                 return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":                 return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":                 return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                            return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                          return "iPad mini (5th generation)"
            case "iPad14,1", "iPad14,2":                          return "iPad mini (6th generation)"
            case "iPad6,3", "iPad6,4":                            return "iPad Pro (9.7-inch)"
            case "iPad7,3", "iPad7,4":                            return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":      return "iPad Pro (11-inch) (1st generation)"
            case "iPad8,9", "iPad8,10":                           return "iPad Pro (11-inch) (2nd generation)"
            case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return "iPad Pro (11-inch) (3rd generation)"
            case "iPad6,7", "iPad6,8":                            return "iPad Pro (12.9-inch) (1st generation)"
            case "iPad7,1", "iPad7,2":                            return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":      return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,11", "iPad8,12":                          return "iPad Pro (12.9-inch) (4th generation)"
            case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":return "iPad Pro (12.9-inch) (5th generation)"
            case "AppleTV5,3":                                    return "Apple TV"
            case "AppleTV6,2":                                    return "Apple TV 4K"
            case "AudioAccessory1,1":                             return "HomePod"
            case "AudioAccessory5,1":                             return "HomePod mini"
            case "i386", "x86_64", "arm64":                       return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                              return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }

        return mapToDevice(identifier: identifier)
    }()

}
