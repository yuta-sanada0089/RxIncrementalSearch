//
//  Repository.swift
//  RxIncrementalSearch
//
//  Created by 真田雄太 on 2018/08/21.
//  Copyright © 2018年 yutaSanada. All rights reserved.
//

import ObjectMapper

/**
 * GithubのAPIより取得する項目を定義する（ObjectMapperを使用して表示したいものだけを抽出してマッピングする）
 * Model層
 */
class Repository: Mappable {
    //表示する値の変数
    var identifier : Int!
    var html_url: String!
    var name: String!
    //イニシャライザ
    required init?(map: Map) {}
    //objectMapperを使用したデータのマッピング
    func mapping(map: Map) {
        identifier <- map["id"]
        html_url <- map["html_url"]
        name <- map["name"]
    }
}
