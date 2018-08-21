//
//  RepositoryViewModel.swift
//  RxIncrementalSearch
//
//  Created by 真田雄太 on 2018/08/21.
//  Copyright © 2018年 yutaSanada. All rights reserved.
//

import ObjectMapper
import RxAlamofire
import RxCocoa
import RxSwift

struct RepositoryViewModel {
    //オブジェクトの初期化に合わせてプロパティの初期値を決定したいのでlazy varにする
    lazy var rx_repositories: Driver<[Repository]> = self.fetchRepositories()
    //監視対象のメンバ変数
    fileprivate var repositoryName: Observable<String>
    //監視対象の変数初期化処理(イニシャライザ)
    init(withNameObservable nameObservable: Observable<String>) {
        self.repositoryName = nameObservable
    }
    fileprivate func fetchRepositories() -> Driver<[Repository]> {
        /**
         * Observableな変数に対して、「.subscribeOn」→「.observeOn」→「.observeOn」...という形で数珠つなぎで処理を実行
         * 処理の終端まで無事にたどり着いた場合には、ObservableをDriverに変換して返却する
         */
        return repositoryName
            //処理Phase1: 見た目に関する処理
            .subscribeOn(MainScheduler.instance)
            .do(onNext: { response in
                //ネットワークインジケーターを表示
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
            //処理Phase2: 下記のAPI(GithubAPI)のエンドポイントへRxAlamofire経由でのアクセスをする
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest { text in
                //APIからデータを取得する
                return RxAlamofire
                    .requestJSON(.get, "https://api.github.com/users/\(text)/repos")
                    .debug()
                    .catchError{ error in
                        //エラー発生時の処理(この場合は値を持たせずにここで処理を止めてしまう)
                        return Observable.never()
                }
            }
            //処理Phase3: ModelクラスとObjectMapperで定義した形のデータを作成する
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .map { (response, json) -> [Repository] in
                //APIからレスポンスが取得できた場合にはModelクラスに定義した形のデータを返却する
                if let repos = Mapper<Repository>().mapArray(JSONObject: json) {
                    return repos
                }else {
                    return []
                }
            }
            //処理Phase4: データが受け取れた際の見た目に関する処理とDriver変換
            .observeOn(MainScheduler.instance)
            .do(onNext: { response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                //ネットワークインジケーターを非表示
            })
            .asDriver(onErrorJustReturn: []) //Driverに変換
    }
}
