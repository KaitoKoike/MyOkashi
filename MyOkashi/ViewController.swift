//
//  ViewController.swift
//  MyOkashi
//
//  Created by 小池開人 on 2020/03/06.
//  Copyright © 2020 KKid. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource,UITableViewDelegate,SFSafariViewControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //searchBarのつ入力終了の通知先を指定する
        searchText.delegate = self
        
        // 入力のヒントとなるフレーズホルダーを設定
        searchText.placeholder = "お菓子の名前を入力してください"
        //Table Viewのデータソースを決定
        searchView.dataSource = self
        
        searchView.delegate = self
    }


    @IBOutlet weak var searchText: UISearchBar!
    
    @IBOutlet weak var searchView: UITableView!
    
    // お菓子のリストとなるタプル
    var okashiList : [(name:String, maker:String, link:URL, image:URL)] = []
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        view.endEditing(true)
        
        if let searchWord = searchBar.text {
            print(searchWord)
            
            //サーチワードがあればクエリを投げる
            searchOkashi(keyword: searchWord)
        }
    }
    
    struct ItemJson : Codable {
        // お菓子の名前
        let name : String?
        
        // メーカー
        let maker : String?
        
        // 掲載URL
        let url : URL?
        
        // 画像URL
        let image : URL?
    }
    
    //JSONのデータ構造
    struct ResultJson : Codable{
        let item : [ItemJson]?
    }
    
    
    // SearchOkashiメソッドの作成
    // お菓子のキーワードから検索して一覧を表示する処理
    // 第一引数：キーワード
    func searchOkashi(keyword:String) {
        // お菓子のキーワードをURLエンコードする
        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        //リクエストURLの組み立て
        guard let req_url = URL(string: "https://sysbird.jp/toriko/api/?apikey=guest&format=json&keyword=\(keyword_encode)&max=10&order=r") else {
            return
        }
        
        print(req_url)
        
        // リクエストに必要な情報を生成
        let req = URLRequest(url: req_url)
        
        // データ転送を管理するためのセッションを生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        // リクエストをタスクとして登録
        let task = session.dataTask(with: req, completionHandler: {
            (data, response, error) in
            //セッションを終了
            session.finishTasksAndInvalidate()
            
            //do try catch エラーハンドリング
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(ResultJson.self, from: data!)
                
                //print(json)
                // jsonの中身をokashiListに格納する
                if let items = json.item {
                    //datasourceの初期化
                    self.okashiList.removeAll()
                    
                    for item in items {
                        if let name = item.name, let maker = item.maker, let link = item.url, let image = item.image {
                            let okashi = (name,maker,link,image)
                            self.okashiList.append(okashi)
                        }
                    }
                    
                    //tableの更新
                    self.searchView.reloadData()
                    if let okashiFirst = self.okashiList.first {
                        print("----------------")
                        print("最初のお菓子は，\(okashiFirst)")
                    }
                }
                
            } catch {
                // エラー処理
                print("エラーが発生しました")
            }
        })
        
        // タスクの実行
        task.resume()
    }
    
    //Cellの総数を返すdatasourceメソッド，必ず記述する必要がある
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return okashiList.count
    }
    
    //Cellに値を代入するデータソースメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //今回使うCellオブジェクトを取得する
        let cell = tableView.dequeueReusableCell(withIdentifier: "okashiCell",for: indexPath)
        //お菓子のタイトル設定
        cell.textLabel?.text = okashiList[indexPath.row].name
        
        //お菓子のた画像を設定
        if let imageData = try? Data(contentsOf: okashiList[indexPath.row].image){
            //正常に取得できた場合は UIImageで画像オブジェクトを生成し，Cellにお菓子画像を設定
            cell.imageView?.image = UIImage(data: imageData)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //セル選択の解除
        tableView.deselectRow(at: indexPath, animated: true)
        
        //SFSafariViewを開く
        let safariViewController = SFSafariViewController(url: okashiList[indexPath.row].link)
        
        // delegateの通知先を設定
        safariViewController.delegate = self
        
        // safariを開く
        present(safariViewController,animated: true,completion: nil)
    }
    
    //safariの閉じるボタンが押された時のメソッド
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }
}

