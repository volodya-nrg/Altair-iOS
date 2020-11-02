import UIKit

class BaseViewController: UIViewController {
    internal let boxScrollView: UIScrollView = {
        let x = UIScrollView()
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    internal let boxStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 10
        x.layoutMargins = UIEdgeInsets(top: Helper.globalMarginSide,
                                       left: Helper.globalMarginSide,
                                       bottom: Helper.globalMarginSide,
                                       right: Helper.globalMarginSide)
        x.isLayoutMarginsRelativeArrangement = true
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    internal let debugTextView: UITextView = {
        let x = UITextView()
        x.isSelectable = false
        x.isScrollEnabled = false
        return x
    }()
    
    deinit {
        // NotificationCenter.default.removeObserver(self) // нельзя выключать, т.к. влияет на отображение ошибок и т.д.
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Helper.myColorToUIColor(.white)
        
        boxScrollView.addSubview(boxStackView)
        view.addSubview(boxScrollView)
        
        view.addConstraints([
            boxScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            boxScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            boxScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            boxScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            boxScrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: boxStackView.heightAnchor),

            boxStackView.widthAnchor.constraint(equalTo: boxScrollView.widthAnchor),
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(catchError(_:)), name: .flyError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(goToLogin(_:)), name: .goToLogin, object: nil)
    }
}
extension BaseViewController {
    @objc private func catchError(_ notif: Notification) {
        guard let err = notif.object as? FlyErrorModule else {return}
        let oldErrors = view.subviews.filter{$0 is FlyErrorModule}
        var marginTop: CGFloat = 15
        
        if oldErrors.count > 0 {
            marginTop = oldErrors[oldErrors.count - 1].frame.height + 20
        }
        
        err.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(err)
        view.addConstraints([
            err.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: marginTop),
            err.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1 * 15),
            err.widthAnchor.constraint(equalToConstant: 250),
        ])
        
        Timer.scheduledTimer(timeInterval: Helper.timeWhenRemoveFlyError,
                             target: self,
                             selector: #selector(handlerRemoveMyError),
                             userInfo: err,
                             repeats: false)
    }
    @objc private func handlerRemoveMyError(_ timer: Timer) {
        guard let err = timer.userInfo as? FlyErrorModule else { return }
        err.removeFromSuperview()
    }
    @objc internal func goToLogin(_ notif: Notification) {
        let err = notif.object as! FlyErrorModule
        
        if let vcs = navigationController?.viewControllers {
            let curVC = vcs[vcs.count - 1]
            
            if curVC is LoginViewController {
                NotificationCenter.default.post(name: .flyError, object: err)
                
            } else {
                let x = LoginViewController()
                navigationController?.pushViewController(x, animated: true)
            }
        }
    }
}
