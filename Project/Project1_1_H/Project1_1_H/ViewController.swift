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
        
        if alarmState == true {
            datePickerPreview()
            alarmState = false
        }
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
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
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
    
    func aaa() {
        
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

    func retrieveSleepData() {
        let start = makeStringToDate(str: "1999-01-01")
        let end = Date()
        let predicate = HKQuery.predicateForSamples(withStart:start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: typeToRead!, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { [weak self] (query, sleepResult, error) -> Void in

            if error != nil {
                return
            }

            if let result = sleepResult {
                DispatchQueue.main.async {
                    //수면 데이터에 받아온 데이터를 설정해줌.
                    self?.sleepData = result as? [HKCategorySample] ?? []
                    self?.table.reloadData()
                }
            }
        }

        healthStore.execute(query)
    }

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
//            if checkTheSleepTime(time: aa) {
//                csvDataPostToMobius(csvData: aa, start: start, end: end)
//            }
//            csvDataPostToMobius(csvData: aa, start: start, end: end)
        }
        
//        print(dateFormatter.date(from: date)?.timeIntervalSince1970)
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

