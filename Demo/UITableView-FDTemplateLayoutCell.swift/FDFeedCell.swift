//
//  FDFeedCell.swift
//  TableViewDynamicHeight
//
//  Created by 伯驹 黄 on 2017/2/23.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

let screenW = UIScreen.main.bounds.width
let halfScreenW = screenW / 2
let padding: CGFloat = 16

import SnapKit

class FDFeedCell: UITableViewCell {
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.purple
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        return titleLabel
    }()

    private lazy var contentLabel: UILabel = {
        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        contentLabel.numberOfLines = 0
        return contentLabel
    }()

    private lazy var contentImageView: UIImageView = {
        let contentImageView = UIImageView()
        contentImageView.contentMode = .scaleAspectFit
        return contentImageView
    }()

    private lazy var usernameLabel: UILabel = {
        let usernameLabel = UILabel()
        usernameLabel.font = UIFont.systemFont(ofSize: 13)
        return usernameLabel
    }()

    private lazy var timeLabel: UILabel = {
        let timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: halfScreenW - 16, height: 20))
        timeLabel.font = UIFont.boldSystemFont(ofSize: 12)
        return timeLabel
    }()

    var entity: FDFeedEntity? {
        didSet {
            titleLabel.text = entity?.title
            contentLabel.text = entity?.content
            contentImageView.image = nil
            if let imageName = entity?.imageName, !imageName.isEmpty {
                // FIX CUICatalog: Invalid asset name supplied:
                contentImageView.image = UIImage(named: imageName)
            }
            usernameLabel.text = entity?.username
            timeLabel.text = entity?.time
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(contentImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(timeLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(padding)
            make.trailing.equalTo(10)
            make.top.equalTo(10)
        }

        usernameLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(-4)
            make.leading.equalTo(titleLabel.snp.leading)
        }

        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.trailing.leading.equalTo(titleLabel)
        }

        timeLabel.snp.makeConstraints { (make) in
            make.lastBaseline.equalTo(usernameLabel)
            make.trailing.equalTo(10)
        }

        contentImageView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.leading)
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // If you are not using auto layout, override this method, enable it by setting
    // "fd_enforceFrameLayout" to YES.
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var totalHeight: CGFloat = 0
        totalHeight += titleLabel.sizeThatFits(size).height
        totalHeight += contentLabel.sizeThatFits(size).height
        totalHeight += contentImageView.sizeThatFits(size).height
        totalHeight += usernameLabel.sizeThatFits(size).height
        totalHeight += 40 // margins
        return CGSize(width: size.width, height: totalHeight)
    }
}

extension String {
    var length: Int {
        return characters.count
    }
}
