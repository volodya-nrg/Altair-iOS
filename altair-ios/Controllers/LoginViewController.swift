import UIKit
import RxSwift

final class LoginViewController: BaseViewController {
    private let serviceAuth = AuthService()
    private let disposeBag = DisposeBag()
    private var formData: [String: Any] = [:] {
        didSet {
            let isCorrectEmail = Helper.validateEmail(formData["email"] as? String ?? "")
            let isCorrectPass = (formData["password"] as? String ?? "").trim().count >= Helper.minLenPassword
            btnSend.isEnabled = isCorrectPass && isCorrectEmail
            
            #if DEBUG
                debugTextView.text = Helper.mapToString(formData)
            #endif
        }
    }
    private let inputEmail: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        x.keyboardType = .emailAddress
        x.text = "volodya-nrg@mail.ru"
        return x
    }()
    private let inputPass: UITextField = {
        let x = TextFieldFactory.create()
        x.isSecureTextEntry = true
        x.text = "test"
        return x
    }()
    private let btnForgot = ButtonFactory.create(.system, DictionaryWord.forgotPassword.rawValue)
    private let btnSend = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let btnRegister = ButtonFactory.create(.system, DictionaryWord.zaRegister.rawValue)
    private let dopText: UITextView = {
        let link1 = "пользовательским соглашением"
        let link2 = "политикой конфиденциальности"
        let str = "При входе вы подтверждаете согласие с \(link1) и \(link2)."
        
        let z = NSString(string: str)
        let a1 = MyText.getSmallMuteAttr(str)
        a1.addAttribute(.link, value: "\(Helper.domain)/info/agreement", range: z.range(of: link1))
        a1.addAttribute(.link, value: "\(Helper.domain)/info/privacy-policy", range: z.range(of: link2))
        
        let x = UITextView()
        x.textAlignment = .center
        x.attributedText = a1
        x.dataDetectorTypes = .link
        x.backgroundColor = .none
        x.isScrollEnabled = false
        
        return x
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.login.rawValue

        attachElements()
        setConstrains()
        addEvents()
    }
}
extension LoginViewController: DisciplineProtocol {
    func attachElements() {
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.emailWithColon.rawValue, el: inputEmail))
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.passwordWithColon.rawValue, el: inputPass))
        
        var x = UIStackView()
        x.alignment = .trailing
        x.distribution = .equalSpacing
        x.addArrangedSubview(UILabel())
        x.addArrangedSubview(btnForgot)
        boxStackView.addArrangedSubview(x)
        
        x = UIStackView()
        x.alignment = .leading
        x.distribution = .equalSpacing
        x.addArrangedSubview(btnSend)
        x.addArrangedSubview(UILabel())
        boxStackView.addArrangedSubview(x)
        
        let y = UIView()
        y.heightAnchor.constraint(equalToConstant: 1).isActive = true
        y.backgroundColor = Helper.myColorToUIColor(.gray8)
        boxStackView.addArrangedSubview(UILabel())
        boxStackView.addArrangedSubview(y)
        
        x = UIStackView()
        x.alignment = .center
        x.distribution = .equalSpacing
        x.addArrangedSubview(UILabel())
        x.addArrangedSubview(btnRegister)
        x.addArrangedSubview(UILabel())
        boxStackView.addArrangedSubview(x)
        
        boxStackView.addArrangedSubview(dopText)
        
        #if DEBUG
            boxStackView.addArrangedSubview(debugTextView)
        #endif
    }
    func setConstrains() {
    }
    func addEvents() {
        inputEmail.rx.text.orEmpty.bind{self.formData["email"] = $0}.disposed(by: disposeBag)
        inputPass.rx.text.orEmpty.bind{self.formData["password"] = $0}.disposed(by: disposeBag)
        
        btnForgot.rx.tap.asDriver().drive (onNext: {
            self.navigationController?.pushViewController(RecoverSenderViewController(), animated: true)
        }).disposed(by: disposeBag)
        
        btnRegister.rx.tap.asDriver().drive (onNext: {
            self.navigationController?.pushViewController(RegisterViewController(), animated: true)
        }).disposed(by: disposeBag)
        
        btnSend.rx.tap.asDriver().drive (onNext: {
            self.btnSend.isEnabled = false
            self.serviceAuth.login(self.formData).subscribe { JWTModel in
                JWTSingleton.instance.data = JWTModel.JWT
                Helper.profile$.onNext(JWTModel.userExt)
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
                self.navigationController?.pushViewController(ProfileInfoViewController(), animated: true)
            } onError: { error in
                self.btnSend.isEnabled = true
            } onCompleted: {
                self.btnSend.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
