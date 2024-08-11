//
//  ViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 05/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import RxSwift
import SwiftyJSON
import UIKit

let MEMBER_LIST_URL = "https://my.api.mockaroo.com/members_with_avatar.json?key=44ce18f0"

//class Observable<T> {
//    private let task: (@escaping (T) -> Void) -> Void
//    init(task: @escaping (@escaping (T) -> Void) -> Void
//    ) {
//        self.task = task
//    }
//    func subscribe(_ f: @escaping (T) -> Void) {
//        task(f)
//    }
//}

class ViewController: UIViewController {
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var editView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.timerLabel.text = "\(Date().timeIntervalSince1970)"
        }
    }
    
    private func setVisibleWithAnimation(_ v: UIView?, _ s: Bool) {
        guard let v = v else { return }
        UIView.animate(withDuration: 0.3, animations: { [weak v] in
            v?.isHidden = !s
        }, completion: { [weak self] _ in
            self?.view.layoutIfNeeded()
        })
    }
    
    
    // [ 유틸리티 ]
    // PromiseKit, Bolt...
    // Rxswift : 비동기로 생기는 결과 값을 completion 같은 클로져로 값으로 전달하는 것이 아니라 리턴값으로 전달하기 위해 만들어진 유틸리티이다.
    
    
    // [ Observable의 생명주기 ]
    // 1. Create
    // 2. Subscribe - Observable은 이때 동작하기 시작한다. ( 실행 )
    // 3. onNext
    // ------ 끝 -------
    // 4. onCompleted / onError - 끝난 Observable은 재사용이 불가능하다.
    // 5. Disposed
    
    
    func downloadJson(_ url: String) -> Observable<String?> {
        // 1. 비동기로 생기는 데이터를 Observalble로 감싸서 리턴하는 방법
        
        // <create 사용 방법>
        // (1) 기본 방법
        //        return Observable.create { xzemitter in
        //            emitter.onNext("Hello")
        //            emitter.onNext("World")
        //            emitter.onCompleted()
        //
        //            return Disposables.create()
        //        }
        
        // (2) 제대로 된 Observable create 방법
        return Observable.create { emitter in
            let url = URL(string: url)!
            let task = URLSession.shared.dataTask(with: url) { (data, _, err) in
                guard err == nil else {
                    emitter.onError(err!)
                    return
                }
                
                if let dat = data, let json = String(data: dat, encoding: .utf8) {
                    emitter.onNext(json)
                }
                
                emitter.onCompleted()
            }
            
            task.resume()
            
            return Disposables.create() {
                task.cancel()
            }
        }
        //        return Observable.create { f in
        //            DispatchQueue.global().async {
        //                let url = URL(string: url)!
        //                let data = try! Data(contentsOf: url)
        //                let json = String(data: data, encoding: .utf8)
        //
        //                DispatchQueue.main.async {
        //                    f.onNext(json)
        //                    f.onCompleted() // 순환 참조가 사라진다.
        //                }
        //            }
        //            return Disposables.create()
        //        }
    }
    
    // MARK: SYNC
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBAction func onLoad() {
        editView.text = ""
        self.setVisibleWithAnimation(self.activityIndicator, true)
        
        downloadJson(MEMBER_LIST_URL)
            .subscribe { event in
                switch event {
                case .next(let json):
                    break
                case .error(let err):
                    break
                case .completed:
                    break
                }
            }
        
        
        
        // 2. Observable로 오는 데이터를 받아서 처리하는 방법
        // [ 기존 방식 ]
        //        downloadJson(MEMBER_LIST_URL)
        //            .debug() // 위에서 아래로 전달되는 데이터가 찍힌다.
        //            .subscribe { event in
        //                switch event {
        //                case let .next(json):
        //                    DispatchQueue.main.async {
        //                        self.editView.text = json
        //                        self.setVisibleWithAnimation(self.activityIndicator, false)
        //                    }
        //                case .completed:
        //                    break
        //                case .error:
        //                    break
        //                }
        //            }
        
        
        // [ 해야 할 것(RxSwift 사용방법)]
        // 1. 비동기로 생기는 데이터를 Observalble로 감싸서 리턴하는 방법
        // 2. Observable로 오는 데이터를 받아서 처리하는 방법
    }
}

// 순환 참조 생기는 이유는 self를 캡처하면서 래퍼런스 카운터가 증가하기때문이다.
// 클로져가 없어지면 래퍼런스 카운터가 사라진다.( completed 나 error 경우 사라진다)
