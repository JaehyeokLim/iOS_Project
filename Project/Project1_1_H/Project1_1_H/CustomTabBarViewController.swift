////
////  CustomTabBarController.swift
////  Instagram_Light
////
////  Created by Jaehyeok Lim on 2022/06/24.
////
//
//import UIKit
//import SnapKit
//
//class CustomTabBarController: UITabBarController {
//    let addViewControllerNavigationButton = UIButton()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        configureLayout()
//    }
//    
//    func configureLayout() {
//        self.tabBar.tintColor = .white
//        self.tabBar.unselectedItemTintColor = .black
//        self.tabBar.backgroundColor = UIColor.gray
//        
//        let firstViewController = ViewController()
//        
//        firstViewController.view.backgroundColor = UIColor.white
//        firstViewController.tabBarItem.selectedImage = UIImage(systemName: "house")
//        firstViewController.tabBarItem.image = UIImage(systemName: "house.fill")
//        
//        let secondViewController = DatePicker()
//        
//        secondViewController.view.backgroundColor = UIColor.black
//        secondViewController.tabBarItem.selectedImage = UIImage(systemName: "person")
//        secondViewController.tabBarItem.image = UIImage(systemName: "person.fill")
//        
//        viewControllers = [firstViewController, secondViewController]
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(showPage(_:)), name: NSNotification.Name("showPage"), object: nil)
//    }
//    
//    @objc func showPage(_ notification:Notification) {
//        if let userInfo = notification.userInfo {
//            if let index = userInfo["index"] as? Int {
//            
//                // 네번째 탭의 VC는 NavigationBar를 가지고 있어서 UINavigationController로 다운 캐스팅을 해주기
//                let navigationController = self.children[index] as? UINavigationController
//                
//                // 받아온 인덱스(3, 네번째 탭을 의미)에 해당하는 VC를 띄우고,
//                self.selectedIndex = index
//                
//                // navigationController에 연결되어 있는 secondVC를 push 형식으로 전환
//  
//                
//                let myViewController = DatePicker()
//                
//                myViewController.modalPresentationStyle = .fullScreen
//                present(myViewController, animated: true, completion: nil)
//                
//                navigationController?.pushViewController(myViewController, animated: true)
//                
//                // Modal로 띄우고 싶으면 NavigationController를 연결하는 선행 과정 없이 present 메서드를 사용하면 됨.
//            }
//        }
//    }
//    
//}
