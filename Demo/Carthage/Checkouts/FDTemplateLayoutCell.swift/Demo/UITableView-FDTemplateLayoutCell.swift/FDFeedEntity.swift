//
//  FDFeedEntity.swift
//  TableViewDynamicHeight
//
//  Created by 伯驹 黄 on 2017/2/23.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

import SwiftyJSON

struct FDFeedEntity {
    let identifier: String?
    let title: String?
    let content: String?
    let username: String?
    let time: String?
    let imageName: String?

    init(dict: [String: JSON]) {
        identifier = arc4random().description
        title = dict["title"]?.string
        content = dict["content"]?.string
        username = dict["username"]?.string
        time = dict["time"]?.string
        imageName = dict["imageName"]?.string
    }
}
