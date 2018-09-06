//
//  RepositoryViewController.swift
//  RxIncrementalSearch
//
//  Created by 真田雄太 on 2018/08/21.
//  Copyright © 2018年 yutaSanada. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ObjectMapper
import RxAlamofire

class RepositoryViewController: UIViewController {

    @IBOutlet weak var nameSearchBar: UISearchBar!
    @IBOutlet weak var RepositoryTableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    private let disposeBag = DisposeBag()
    var repositoryViewModel: RepositoryViewModel!
    //検索ボックスの値変化を監視対象にする（テキストが空っぽの場合はデータ取得を行わない）
    var rx_searchBarText: Observable<String> {
        return nameSearchBar.rx.text
            .filter {$0 != nil}
            .map{ $0! }
            .filter { $0.characters.count > 0 }
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRx()
        setupUI()
    }
    
    func setupRx() {
        /**
         * メンバ変数の初期化（検索バーでの入力値の更新をトリガーにしてViewModel側に設置した処理を行う）
         * (フロー1) → 検索バーでの入力値の更新が「データ取得のトリガー」になるので、ViewModel側に定義したfetchRepositories()メソッドが実行される
         * (フロー2) → fetchRepositories()メソッドが実行後は、ViewModel側に定義したメンバ変数rx_repositoriesに値が格納される
         * 結果的に、githubのアカウント名でのインクリメンタルサーチのようになる
         */
        repositoryViewModel = RepositoryViewModel(withNameObservable: rx_searchBarText)
        repositoryViewModel
            .searchResults
            .drive(RepositoryTableView.rx.items) { (tableView, i, repository) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "RepositoryCell", for: IndexPath(row: i, section: 0))
                cell.textLabel?.text = repository.name
                cell.detailTextLabel?.text = repository.html_url
                return cell
            }
            .disposed(by: disposeBag)
        //リクエストした結果の更新を元に表示に関する処理を行う（取得したデータの件数に応じたエラーハンドリング処理）
        repositoryViewModel
            .searchResults
            .drive(onNext: { repositories in
                if repositories.count == 0 {
                    let alert = UIAlertController(title: ":(", message: "No repositories for this user.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    
                    if self.navigationController?.visibleViewController is UIAlertController != true {
                        self.present(alert,animated: true, completion: nil)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    //キーボードのイベント監視の設定 ＆ テーブルビューに付与したGestureRecognizerに関する処理
    //この部分はRxSwiftの処理ではないので切り離して書かれている形？
    func setupUI() {
        //テーブルビューにGestureRecognizerを付与する
        let tap = UITapGestureRecognizer(target: self, action: #selector(tableTapped(_:)))
        RepositoryTableView.addGestureRecognizer(tap)
        
        //キーボードのイベントを監視対象にする
        //Case1. キーボードを開いた場合のイベント
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil)
        
        //Case2. キーボードを閉じた場合のイベント
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil)
    }
    
    //キーボード表示時に発動されるメソッド
    @objc func keyboardWillShow(_ notification: Notification) {
        
        //キーボードのサイズを取得する（英語のキーボードが基準になるので日本語のキーボードだと少し見切れてしまう）
        guard let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        //一覧表示用テーブルビューのAutoLayoutの制約を更新して高さをキーボード分だけ縮める
        tableViewBottomConstraint.constant = keyboardFrame.height
        UIView.animate(withDuration: 0.3, animations: {
            self.view.updateConstraints()
        })
    }
    
    //キーボード非表示表示時に発動されるメソッド
    @objc func keyboardWillHide(_ notification: Notification) {
        
        //一覧表示用テーブルビューのAutoLayoutの制約を更新して高さを元に戻す
        tableViewBottomConstraint.constant = 0.0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.updateConstraints()
        })
    }
    
    //メモリ解放時にキーボードのイベント監視対象から除外する
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //テーブルビューのセルタップ時に発動されるメソッド
    @objc func tableTapped(_ recognizer: UITapGestureRecognizer) {
        
        //どのセルがタップされたかを探知する
        let location = recognizer.location(in: RepositoryTableView)
        let path = RepositoryTableView.indexPathForRow(at: location)
        
        //キーボードが表示されているか否かで処理を分ける
        if nameSearchBar.isFirstResponder {
            
            //キーボードを閉じる
            nameSearchBar.resignFirstResponder()
            
        } else if let path = path {
            
            //タップされたセルを中央位置に持ってくる
            RepositoryTableView.selectRow(at: path, animated: true, scrollPosition: .middle)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

