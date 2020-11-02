import UIKit
import RxSwift

final class RecoverSenderViewController: BaseViewController {
    private let serviceRecover = RecoverService()
    private let disposeBag = DisposeBag()
    private var formData: [String: Any] = [:] {
        didSet {
            submitButton.isEnabled = Helper.validateEmail(formData["email"] as? String ?? "")
            
            #if DEBUG
                debugTextView.text = Helper.mapToString(formData)
            #endif
        }
    }
    private let inputEmail: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        x.keyboardType = .emailAddress
        return x
    }()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.recover.rawValue
        
        attachElements()
        setConstrains()
        addEvents()
    }
}
extension RecoverSenderViewController {
    private func goToRoot() {
        let alert = UIAlertController(title: DictionaryWord.aVerificationCodeHasBeenSentToYourEmail.rawValue,
                                      message: nil,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: DictionaryWord.good.rawValue, style: .cancel) { (alert) in
            self.navigationController?.popToRootViewController(animated: true)
        }

        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}
extension RecoverSenderViewController: DisciplineProtocol {
    func attachElements() {
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.emailWithColon.rawValue, el: inputEmail))
        
        let x = UIStackView()
        x.alignment = .trailing
        x.distribution = .equalSpacing
        x.addArrangedSubview(UILabel())
        x.addArrangedSubview(submitButton)
        
        boxStackView.addArrangedSubview(x)
        
        #if DEBUG
            boxStackView.addArrangedSubview(debugTextView)
        #endif
    }
    func setConstrains() {
    }
    func addEvents() {
        inputEmail.rx.text.orEmpty.bind{self.formData["email"] = $0}.disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive (onNext: {
            self.submitButton.isEnabled = false
            self.serviceRecover.sendHash(self.formData).subscribe { emptyModel in
                self.goToRoot()
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
