//
//  TableViewCell.swift
//  Project1_1_H
//
//  Created by Jaehyeok Lim on 2022/08/16.
//

import UIKit
import SnapKit

class ViewTableCell: UITableViewCell {
    let identifier = "ViewTableCell"
    
    lazy var text: UILabel = {
        let lyricsLabel = UILabel()
        
        lyricsLabel.textColor = .systemGray
        lyricsLabel.font = UIFont.systemFont(ofSize: 12)
        lyricsLabel.textAlignment = .left
        
        return lyricsLabel
    }()
    
    func setConstraint() {
        addSubview(text)
        
        text.snp.makeConstraints { make in
            make.leading.equalTo(contentView)
            make.height.equalTo(contentView)
        }
    }
    
    func transText(date: Date, start: String, end: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let aaab = date.timeIntervalSince1970
//        text.text = "\(Int(aaab)): sleep start time is \(start) and awake time is \(end)"
        text.text = "\(date): sleep start time is \(start) and awake time is \(end)"

    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
