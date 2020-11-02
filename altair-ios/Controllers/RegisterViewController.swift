import UIKit
import RxSwift

final class RegisterViewController: BaseViewController {
    private let serviceProfile = ProfileService()
    private let serviceManager = ManagerService()
    private let disposeBag = DisposeBag()
    private var formData: [String: Any] = [:] {
        didSet {
            let pass = formData["password"] as? String ?? ""
            let passConfirm = formData["passwordConfirm"] as? String ?? ""
            let email = formData["email"] as? String ?? ""
            let isCorrectPass = pass.count >= Helper.minLenPassword && pass == passConfirm
            let isAgree = formData["agreeOffer"] as? Bool ?? false
            let isPolicy = formData["agreePolicy"] as? Bool ?? false
            
            btnSend.isEnabled = isCorrectPass && Helper.validateEmail(email) && isAgree && isPolicy
            
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
    private let inputPass: UITextField = {
        let x = TextFieldFactory.create()
        x.isSecureTextEntry = true
        return x
    }()
    private let inputPassConfirm: UITextField = {
        let x = TextFieldFactory.create()
        x.isSecureTextEntry = true
        return x
    }()
    private let agreeSwitch: UISwitch = {
        let x = UISwitch()
        x.isSelected = false
        return x
    }()
    private lazy var agreeText: UIView = {
        let substr = "условия оферты"
        let fullString = "Я принимаю \(substr)"
        return self.generateViewFromTextView(fullString, substr, "\(Helper.domain)/info/agreement")
    }()
    private let policySwitch: UISwitch = {
        let x = UISwitch()
        x.isSelected = false
        return x
    }()
    private lazy var policyText: UIView = {
        let substr = "политику конфиден-и"
        let fullString = "Я принимаю \(substr)"
        return self.generateViewFromTextView(fullString, substr, "\(Helper.domain)/info/privacy-policy")
    }()
    private func generateViewFromTextView(_ fullString: String, _ substr: String, _ href: String) -> UIView {
        let containerView = UIView()
        let textView = UITextView()
        containerView.addSubview(textView)
        
        let a1 = MyText.getSmallMuteAttr(fullString)
        a1.addAttribute(.link, value: href, range: NSString(string: fullString).range(of: substr))
        
        textView.attributedText = a1
        textView.dataDetectorTypes = .link
        textView.backgroundColor = .none
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        textView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        
        return containerView
    }
    private let btnSend = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.register.rawValue
        
        attachElements()
        setConstrains()
        addEvents()
    }
}

extension RegisterViewController: DisciplineProtocol {
    func attachElements() {
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.emailWithColon.rawValue, el: inputEmail))
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.passwordWithColon.rawValue, el: inputPass))
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.passwordConfirmWithColon.rawValue, el: inputPassConfirm))
        
        var x = UIStackView()
        x.spacing = 20
        x.alignment = .leading
        x.addArrangedSubview(agreeSwitch)
        x.addArrangedSubview(agreeText)
        boxStackView.addArrangedSubview(x)
        
        x = UIStackView()
        x.spacing = 20
        x.alignment = .leading
        x.addArrangedSubview(policySwitch)
        x.addArrangedSubview(policyText)
        boxStackView.addArrangedSubview(x)
        
        x = UIStackView()
        x.alignment = .trailing
        x.distribution = .equalSpacing
        x.addArrangedSubview(UILabel())
        x.addArrangedSubview(btnSend)
        boxStackView.addArrangedSubview(x)
        
        #if DEBUG
            boxStackView.addArrangedSubview(debugTextView)
        #endif
    }
    func setConstrains() {
    }
    func addEvents() {
        inputEmail.rx.text.orEmpty.bind{self.formData["email"] = $0}.disposed(by: disposeBag)
        inputPass.rx.text.orEmpty.bind{self.formData["password"] = $0}.disposed(by: disposeBag)
        inputPassConfirm.rx.text.orEmpty.bind{self.formData["passwordConfirm"] = $0}.disposed(by: disposeBag)
        agreeSwitch.rx.value.bind{self.formData["agreeOffer"] = $0}.disposed(by: disposeBag)
        policySwitch.rx.value.bind{self.formData["agreePolicy"] = $0}.disposed(by: disposeBag)
        
        btnSend.rx.tap.asDriver().drive (onNext: {
            self.btnSend.isEnabled = false
            self.serviceProfile.create(self.formData).subscribe { userModel in
                self.navigationController?.pushViewController(RegisterOKViewController(), animated: true)
            } onError: { error in
            } onCompleted: {
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
