//
//  ViewController.swift
//  RxIncrementalSearch
//
//  Created by 真田雄太 on 2018/08/21.
//  Copyright © 2018年 yutaSanada. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let allUsers = [
        "かとう",
        "たなか",
        "ひらや",
        "おおはし",
        "やまもと",
        "ふかさわ",
        "さいとう",
        "くどう",
        "すわ",
        "わたなべ"
    ]
    private var filteredUser = [String]()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
}

private extension ViewController {
    func setup() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        filteredUser = allUsers
    }
    
    func bind() {
        searchBar.delegate = self
        
        let incrementalSearchTextObservable = rx
            //UISerchBarに文字入力中に呼ばれるsearhcBarDelegateのメソッドをフック
            .methodInvoked(#selector(UISearchBarDelegate.searchBar(_:shouldChangeTextIn:replacementText:)))
            //searchbartextの値が0.3秒で確定
            .debounce(0.3, scheduler: MainScheduler.instance)
            //確定したsearchtextを取得
            .flatMap{[weak self] _ in Observable.just(self?.searchBar.text ?? "")}
        
        //searxhBarのクリア（×）ボタンや確定ボタンタップにテキストを取得するためのObservable
        let textObservable = searchBar.rx.text.orEmpty.asObservable()
        
        
        let searchText = Observable.merge(incrementalSearchTextObservable, textObservable)
            .throttle(0.3, scheduler: MainScheduler.instance)
            .share(replay: 1)
            // 変化があるまで文字列が流れないようにする,連続して同じテキストが流れないようにする
            .distinctUntilChanged()
        
        searchText
            .subscribe(onNext: {[weak self] text in
                guard let `self` = self else { return }
                if text.isEmpty {
                    self.filteredUser = self.allUsers
                } else {
                    self.filteredUser = self.allUsers.filter { $0.contains(text) }
                }
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
    }
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUser.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = filteredUser[indexPath.row]
        return cell
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}


