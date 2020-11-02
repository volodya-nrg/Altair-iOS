import UIKit
import RxSwift

final class FormUsersPostUsersModule: FormBaseModule {
    private let serviceUsers = UserService()
    private let disposeBag = DisposeBag()
    private var presentationController: UIViewController
    
    private var formData: [String: Any] = [:] {
        didSet {
            let email = formData["email"] as? String ?? ""
            let password = formData["password"] as? String ?? ""
            let passwordConfirm = formData["passwordConfirm"] as? String ?? ""
            
            let isCorrectEmail = Helper.validateEmail(email)
            let isCorrectPassword = password.count >= Int(Helper.minLenPassword)
            let isCorrectPasswordConfirm = passwordConfirm.count >= Int(Helper.minLenPassword)
            
            submitButton.isEnabled = isCorrectEmail && isCorrectPassword && isCorrectPasswordConfirm
            
            #if DEBUG
                // debugTextView.text = Helper.mapToString(formData) // ломается
            #endif
        }
    }
    
    public let fileModule: FileModule
    private let inputEmail: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        x.keyboardType = .emailAddress
        return x
    }()
    private let inputPassword: UITextField = {
        let x = TextFieldFactory.create()
        x.isSecureTextEntry = true
        return x
    }()
    private let inputPasswordConfirm: UITextField = {
        let x = TextFieldFactory.create()
        x.isSecureTextEntry = true
        return x
    }()
    private let inputName = TextFieldFactory.create()
    private let switchIsEmailConfirmed = UISwitch()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    
    init(presentationController: UIViewController) {
        self.presentationController = presentationController
        self.fileModule = FileModule(presentationController: presentationController, limit: 1)
        
        super.init()
        
        fileModule.delegate = self
        
        attachElements()
        setConstrains()
        addEvents()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func reset() {
        inputName.rx.text.onNext("")
        inputEmail.rx.text.onNext("")
        inputPassword.rx.text.onNext("")
        inputPasswordConfirm.rx.text.onNext("")
        fileModule.reset()
        switchIsEmailConfirmed.rx.value.onNext(false)
        formData.removeAll()
    }
}
extension FormUsersPostUsersModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.avatar.rawValue, el: fileModule))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.firstName.rawValue, el: inputName))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.email.rawValue, el: inputEmail))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.password.rawValue, el: inputPassword))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.passwordConfirm.rawValue, el: inputPasswordConfirm))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.emailIsConfirmed.rawValue, el: switchIsEmailConfirmed))
        addArrangedSubview(submitButton)
        
        #if DEBUG
            // addArrangedSubview(debugTextView)
        #endif
    }
    func setConstrains() {
    }
    func addEvents() {
        inputName.rx.text.orEmpty.bind{self.formData["name"] = $0}.disposed(by: disposeBag)
        inputEmail.rx.text.orEmpty.bind{self.formData["email"] = $0}.disposed(by: disposeBag)
        inputPassword.rx.text.orEmpty.bind{self.formData["password"] = $0}.disposed(by: disposeBag)
        inputPasswordConfirm.rx.text.orEmpty.bind{self.formData["passwordConfirm"] = $0}.disposed(by: disposeBag)
        switchIsEmailConfirmed.rx.value.bind{self.formData["isEmailConfirmed"] = $0}.disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            if self.fileModule.images.count > 0 {
                self.formData["files"] = self.fileModule.images[0].image?.pngData()
            }
            
            self.submitButton.isEnabled = false
            self.serviceUsers.create(self.formData).subscribe { userModel in
                self.reset()
                NotificationCenter.default.post(name: .showJSON, object: userModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
extension FormUsersPostUsersModule: FileModuleDelegate {
    internal func fileModuleDidSelect(image: UIImage?) {
        // обновились прикрепленные файлы
    }
}
