import UIKit
import RxSwift

final class ProfileInfoViewController: BaseViewController {
    private let serviceProfile = ProfileService()
    private let serviceAuth = AuthService()
    private lazy var modulePhones: PhonesModule = {
        let x = PhonesModule()
        x.dataSource = self
        return x
    }()
    
    private let disposeBag = DisposeBag()
    private var formData: [String: Any] = [:] {
        didSet {
            let pass = formData["passwordOld"] as? String ?? ""
            let passNew = formData["passwordNew"] as? String ?? ""
            let passNewConfirm = formData["passwordConfirm"] as? String ?? ""
            
            #if DEBUG
                // debugTextView.text = Helper.mapToString(formData) - выдает ошибку
            #endif
            
            if pass != "" || passNew != "" || passNewConfirm != "" {
                let isCorrectPass = pass.count >= Helper.minLenPassword &&
                    passNew.count >= Helper.minLenPassword &&
                    passNewConfirm.count >= Helper.minLenPassword &&
                    passNew == passNewConfirm
                submitButton.isEnabled = isCorrectPass
                return
            }
            
            submitButton.isEnabled = true
        }
    }
    private var profile: UserExtModel? {
        didSet {
            self.reset()
            guard let x = profile else {return}
            
            let t1 = DictionaryWord.dateRegisterWithColon.rawValue
            let t2 = Helper.getFormattedDate(string: x.createdAt)
            dateRegLabel.attributedText = MyText.getMutedAttr("\(t1) \(t2)")
            
            inputEmail.text = x.email
            inputName.text = x.name
            inputPass.text = ""
            inputPassNew.text = ""
            inputPassNewConfirm.text = ""
            modulePhones.phones = x.phones
            
            formData = [
                "name": x.name,
                "passwordOld": "",
                "passwordNew": "",
                "passwordConfirm": "",
            ]
            
            if x.avatar != "" {
                if let url = URL(string: "\(Helper.domain)/api/v1/resample/0/320/\(x.avatar)") {
                    Helper.downloadImage(url) { self.avatarImageView.image = $0 }
                }
                
                delAvatarButton.isHidden = false
                formData["avatar"] = x.avatar
            }
        }
    }
    private var isWantDelAvatar: Bool = false {
        didSet {
            avatarImageView.layer.opacity = isWantDelAvatar ? 0.5 : 1
            formData["avatar"] = (isWantDelAvatar ? "" : (profile?.avatar ?? ""))
        }
    }
    private lazy var fileModule: FileModule = {
        let x = FileModule(presentationController: self, limit: 1)
        return x
    }()
    private let adminButton = ButtonFactory.create(.system, DictionaryWord.adm.rawValue)
    private let myAdsButton = ButtonFactory.create(.system, DictionaryWord.myAds.rawValue)
    private let logoutButton = ButtonFactory.create(.system, DictionaryWord.exit.rawValue)
    private let avatarImageWrapView: UIView = {
        let x = UIView()
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    private let avatarImageView: UIImageView = {
        let x = UIImageView()
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        x.contentMode = .scaleAspectFit
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    private let delAvatarButton: UIButton = {
        let x = UIButton(type: .close)
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    private let inputEmail: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        x.keyboardType = .emailAddress
        x.isEnabled = false
        return x
    }()
    private let inputName = TextFieldFactory.create()
    private let inputPass: UITextField = {
        let x = TextFieldFactory.create()
        x.isSecureTextEntry = true
        return x
    }()
    private let inputPassNew: UITextField = {
        let x = TextFieldFactory.create()
        x.isSecureTextEntry = true
        return x
    }()
    private let inputPassNewConfirm: UITextField = {
        let x = TextFieldFactory.create()
        x.isSecureTextEntry = true
        return x
    }()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.save.rawValue)
    private let dateRegLabel: UILabel = {
        let x = UILabel()
        x.textAlignment = .right
        return x
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.profile.rawValue
        
        attachElements()
        setConstrains()
        addEvents()
        
        Helper.profile$.subscribe { userExtModel in
            self.profile = userExtModel
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // необходимо
        if let vcs = navigationController?.viewControllers {
            let previousVC = vcs[vcs.count - 2]
            
            if previousVC is LoginViewController {
                navigationItem.leftBarButtonItems = [
                    UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                    style: .plain,
                                    target: self,
                                    action: #selector(goToRoot)),
                ]
            }
        }
    }
    private func reset() {
        delAvatarButton.isHidden = true
        avatarImageView.image = nil
        fileModule.reset()
        formData.removeAll()
        dateRegLabel.text = ""
        isWantDelAvatar = false
        inputEmail.rx.text.onNext("")
        inputPass.rx.text.onNext("")
        inputPassNew.rx.text.onNext("")
        inputPassNewConfirm.rx.text.onNext("")
    }
}
extension ProfileInfoViewController: DisciplineProtocol {
    func attachElements() {
        let x = UIStackView()
        x.axis = .vertical
        x.alignment = .leading
        
        if serviceAuth.isAdmin() {
            x.addArrangedSubview(adminButton)
        }
        
        x.addArrangedSubview(myAdsButton)
        x.addArrangedSubview(logoutButton)
        boxStackView.addArrangedSubview(x)
        
        avatarImageWrapView.addSubview(avatarImageView)
        avatarImageWrapView.addSubview(delAvatarButton)
        
        boxStackView.addArrangedSubview(avatarImageWrapView)
        boxStackView.addArrangedSubview(modulePhones)
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.avatar.rawValue, el: fileModule))
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.email.rawValue, el: inputEmail))
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.firstName.rawValue, el: inputName))
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.password.rawValue, el: inputPass))
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.passwordNew.rawValue, el: inputPassNew))
        boxStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.passwordNewConfirm.rawValue, el: inputPassNewConfirm))
        boxStackView.addArrangedSubview(submitButton)
        boxStackView.addArrangedSubview(dateRegLabel)
        
        #if DEBUG
            // boxStackView.addArrangedSubview(debugTextView) // выдает ошибку
        #endif
    }
    func setConstrains() {
        view.addConstraints([
            avatarImageWrapView.heightAnchor.constraint(equalToConstant: 200),
            avatarImageView.widthAnchor.constraint(equalTo: avatarImageWrapView.widthAnchor),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageWrapView.heightAnchor),
            delAvatarButton.topAnchor.constraint(equalTo: avatarImageWrapView.topAnchor, constant: Helper.paddingSm),
            delAvatarButton.trailingAnchor.constraint(equalTo: avatarImageWrapView.trailingAnchor, constant: -1 * Helper.paddingSm),
        ])
    }
    func addEvents() {
        inputName.rx.text.orEmpty.bind{self.formData["name"] = $0}.disposed(by: disposeBag)
        inputPass.rx.text.orEmpty.bind{self.formData["passwordOld"] = $0}.disposed(by: disposeBag)
        inputPassNew.rx.text.orEmpty.bind{self.formData["passwordNew"] = $0}.disposed(by: disposeBag)
        inputPassNewConfirm.rx.text.orEmpty.bind{self.formData["passwordConfirm"] = $0}.disposed(by: disposeBag)
        
        delAvatarButton.rx.tap.asDriver().drive(onNext:{
            self.isWantDelAvatar = !self.isWantDelAvatar
        }).disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive (onNext: {
            if self.fileModule.images.count > 0 {
                self.formData["files"] = self.fileModule.images[0].image?.pngData()
            }
            
            self.submitButton.isEnabled = false
            self.serviceProfile.update(self.formData).subscribe { userExtModel in // userExt (user, phones)
                Helper.profile$.onNext(userExtModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
        
        adminButton.rx.tap.asDriver().drive (onNext: {
            self.navigationController?.pushViewController(AdmViewController(), animated: true)
        }).disposed(by: disposeBag)
        
        logoutButton.rx.tap.asDriver().drive (onNext: {
            self.serviceAuth.logout().subscribe { emptyModel in
                JWTSingleton.instance.data = ""
                Helper.profile$.onNext(nil)
                self.navigationController?.popToRootViewController(animated: true)
            } onError: { error in
            } onCompleted: {
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
        
        myAdsButton.rx.tap.asDriver().drive (onNext: {
            self.navigationController?.pushViewController(ProfileAdsViewController(), animated: true)
        }).disposed(by: disposeBag)
    }
}
extension ProfileInfoViewController {
    @objc private func goToRoot() {
        navigationController?.popToRootViewController(animated: true)
    }
}
extension ProfileInfoViewController: PhonesModuleDatasource {
    func showAlertBeforeDeletePhone(_ index: Int) {
        let alert = UIAlertController(title: DictionaryWord.areYouSureYouWantToDeleteYourPhoneNumber.rawValue,
                                      message: nil,
                                      preferredStyle: .alert)
        let yesAction = UIAlertAction(title: DictionaryWord.yes.rawValue, style: .default) { alert in
            NotificationCenter.default.post(name: .deletePhone, object: index)
        }
        let noAction = UIAlertAction(title: DictionaryWord.no.rawValue, style: .cancel, handler: nil)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: true, completion: nil)
    }
}
