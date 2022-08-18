import UIKit
import HealthKit
import SnapKit

class ViewController: UIViewController {

    let healthStore = HKHealthStore()
    let typeToShare:HKCategoryType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    let typeToRead:HKSampleType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    var sleepData:[HKCategorySample] = []
    let startDate = Date()
    var uiList = [UIView]()
    var buttonState: Bool = false

    let sleepAndAwakeButton: UIButton = {
        let sleepAndAwakeButton = UIButton()

        sleepAndAwakeButton.setImage(UIImage(systemName: "sun.max.fill"), for: .normal)
        sleepAndAwakeButton.tintColor = UIColor.systemYellow
        sleepAndAwakeButton.contentHorizontalAlignment = .fill
        sleepAndAwakeButton.contentVerticalAlignment = .fill
        
        return sleepAndAwakeButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        saveSleepData()
        requestAuthorization()
        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        table.reloadData()
    }

    let table: UITableView = {
        let table = UITableView()

        table.rowHeight = 22
        table.register(ViewTableCell.self, forCellReuseIdentifier: "ViewTableCell")

        return table
    }()

    func configure() {
        view.backgroundColor = .white
        table.backgroundColor = .white

        table.dataSource = self
//        table.delegate = self

        uiList = [table, sleepAndAwakeButton]
        
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

        if !HKHealthStore.isHealthDataAvailable() {
            requestAuthorization()

        } else {
            retrieveSleepData()
        }
        
        sleepAndAwakeButton.addTarget(self, action: #selector(sleepAndAwakeButtonAction(_:)), for: .touchUpInside)
    }
    
    @objc func sleepAndAwakeButtonAction(_: UIButton) {
        print("hello")
        if !buttonState {
            sleepAndAwakeButton.setImage(UIImage(systemName: "moon.fill"), for: .normal)
            sleepAndAwakeButton.tintColor = UIColor.systemPurple
            
        } else {
            sleepAndAwakeButton.setImage(UIImage(systemName: "sun.max.fill"), for: .normal)
            sleepAndAwakeButton.tintColor = UIColor.systemYellow
        }
        
        buttonState = !buttonState
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

extension ViewController:UITableViewDataSource {
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
}
