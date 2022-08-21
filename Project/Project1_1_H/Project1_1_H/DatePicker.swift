//
//  DatePicker.swift
//  Project1_1_H
//
//  Created by Jaehyeok Lim on 2022/08/21.
//

import UIKit
import HealthKit
import SnapKit

class DatePicker: UIViewController {
    
    let healthStore = HKHealthStore()
    let typeToShare:HKCategoryType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    let typeToRead:HKSampleType? = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        
        titleLabel.text = "잠에 든 시간을 선택해주세요!"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 25)
        titleLabel.textAlignment = .center
        
        return titleLabel
    }()
    
    let datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        let loc = Locale(identifier: "ko")
        datePicker.locale = loc

        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .dateAndTime

        return datePicker
    }()

    let choosenDate: UILabel = {
        let choosenDate = UILabel()
            
        choosenDate.text = ""
        choosenDate.textColor = UIColor.systemBlue
        choosenDate.font = UIFont.boldSystemFont(ofSize: 20)
        choosenDate.textAlignment = .center
        
        return choosenDate
    }()
    
    let saveButton: UIButton = {
        let saveButton = UIButton()
       
        saveButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        saveButton.tintColor = .systemBlue
        saveButton.contentVerticalAlignment = .fill
        saveButton.contentHorizontalAlignment = .fill
        
        return saveButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layout()
    }
    
    func layout() {
        view.backgroundColor = UIColor.black
        
        view.addSubview(datePicker)
        view.addSubview(choosenDate)
        view.addSubview(titleLabel)
        view.addSubview(saveButton)
        
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(view).offset(220)
            make.leading.equalTo(view).offset(0)
        }
        
        choosenDate.snp.makeConstraints { make in
            make.top.equalTo(datePicker).offset(450)
            make.width.equalTo(view)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view).offset(150)
            make.width.equalTo(view)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(view).offset(60)
            make.trailing.equalTo(view).offset(-20)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        datePicker.addTarget(self, action: #selector(datePickerAction(sender:)), for: .valueChanged)
        saveButton.addTarget(self, action: #selector(saveButtonAction(sender:)), for: .touchUpInside)
    }
    
    @objc func datePickerAction(sender: UIDatePicker) {
        choosenDate.text = formatDate(date: datePicker.date)
    }
    
    @objc func saveButtonAction(sender: UIDatePicker) {
        
        if UserDefaults.standard.bool(forKey: "alarmCheck") {
            print("이미했음!!")
            
        } else {
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.timeZone = TimeZone(abbreviation: "KST")
            
            if let choosenDateData = choosenDate.text {
                if let date = formatter.date(from: choosenDateData) {
                    saveSleepData(start: date, end: Date())
                    print("\(date)")
                }
            }
        }
        
        self.dismiss(animated: true, completion: nil )
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        return formatter.string(from: date)
    }
    
    func saveSleepData(start: Date, end: Date) {
        let object = HKCategorySample(type: typeToShare!, value: HKCategoryValueSleepAnalysis.inBed.rawValue, start: start,end: end)
        healthStore.save(object, withCompletion: { (success, error) -> Void in
            if error != nil {
                return
            }
            if success {
                print("수면 데이터 저장 완료!")
//                self.retrieveSleepData()
                print("\(self.formatDate(date: start)), \(self.formatDate(date: end))")
                self.csvDataPostToMobius(start: start, end: end)
                UserDefaults.standard.set(true, forKey: "alarmCheck")
            } else {
                print("수면 데이터 저장 실패...")
            }
        })
        
//        table.reloadData()
    }
    
    func csvDataPostToMobius(start: Date, end: Date) {
        let semaphore = DispatchSemaphore (value: 0)

        let parameters = "{\n    \"m2m:cin\": {\n        \"con\": \"\(Int(start.timeIntervalSince1970)),\(Int(end.timeIntervalSince1970))\"\n    }\n}"
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
            print("\(Int(start.timeIntervalSince1970)),\(Int(end.timeIntervalSince1970))")
            print("Data is served.")
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()
    }
}
