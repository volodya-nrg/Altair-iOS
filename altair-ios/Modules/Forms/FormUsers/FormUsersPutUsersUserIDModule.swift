import UIKit
import RxSwift

final class FormUsersPutUsersUserIDModule: FormBaseModule {
    private let serviceUsers = UserService()
    private let disposeBag = DisposeBag()
    private var requestedUserID: UInt = 0
    private var presentationController: UIViewController
    private let miniImgSize: CGFloat = 30
    private let cellID = "FormUsersPutUsersUserIDModuleCellID"
    private var filesAlreadyHas: [UIImageView] = []
    
    private var formDataPut: [String: Any] = [:] {
        didSet {
            let email = formDataPut["email"] as? String ?? ""
            let userID = formDataPut["userID"] as? UInt ?? 0
            
            submitButtonPut.isEnabled = userID > 0 && Helper.validateEmail(email)
            
            #if DEBUG
                // debugTextView.text = Helper.mapToString(formDataPut)
            #endif
        }
    }
    private var user: UserModel? {
        didSet {
            filesAlreadyHas.removeAll()
            fileModule.reset()
            
            guard let x = user else {
                formDataPut.removeAll()
                formPutStackView.isHidden = true
                return
            }
            
            formPutStackView.isHidden = false
            inputEmail.rx.text.onNext(x.email)
            inputPassword.rx.text.onNext("")
            inputPasswordConfirm.rx.text.onNext("")
            inputName.rx.text.onNext(x.name)
            switchIsEmailConfirmed.rx.value.onNext(x.isEmailConfirmed)
            
            formDataPut = [
                "userID": x.userID,
                "email": x.email,
                "password": "",
                "passwordConfirm": "", // не null, проверка не нужна
                "avatar": x.avatar,
                "name": x.name,
                "isEmailConfirmed": x.isEmailConfirmed,
            ]
            
            if x.avatar != "" {
                let y = UIImageView()
                
                y.backgroundColor = Helper.myColorToUIColor(.gray7)
                y.contentMode = .scaleAspectFit
                y.translatesAutoresizingMaskIntoConstraints = false
                y.widthAnchor.constraint(equalToConstant: miniImgSize).isActive = true
                y.heightAnchor.constraint(equalToConstant: miniImgSize).isActive = true
                
                if let url = URL(string: "\(Helper.domain)/api/v1/resample/0/100/\(x.avatar)") {
                    Helper.downloadImage(url) { image in
                        y.image = image
                    }
                }
                
                filesAlreadyHas.append(y)
                fileAlreadyHasCollectionView.reloadData()
            }
        }
    }
    
    private let formPutStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 10
        x.isHidden = true
        return x
    }()
    public let fileModule: FileModule
    private lazy var inputID: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        x.text = "0"
        return x
    }()
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
    private let submitButtonGet = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let submitButtonPut = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private lazy var fileAlreadyHasCollectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: miniImgSize, height: miniImgSize)
        layout.scrollDirection = .horizontal
        
        let x = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        x.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        x.translatesAutoresizingMaskIntoConstraints = false
        x.heightAnchor.constraint(equalToConstant: miniImgSize).isActive = true
        x.delegate = self
        x.dataSource = self
        
        return x
    }()
    
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
}
extension FormUsersPutUsersUserIDModule: DisciplineProtocol {
    func attachElements() {
        formPutStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.avatar.rawValue, el: fileModule))
        formPutStackView.addArrangedSubview(fileAlreadyHasCollectionView)
        formPutStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.firstName.rawValue, el: inputName))
        formPutStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.email.rawValue, el: inputEmail))
        formPutStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.password.rawValue, el: inputPassword))
        formPutStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.passwordConfirm.rawValue, el: inputPasswordConfirm))
        formPutStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.emailIsConfirmed.rawValue, el: switchIsEmailConfirmed))
        formPutStackView.addArrangedSubview(submitButtonPut)
        
        #if DEBUG
            // formPutStackView.addArrangedSubview(debugTextView)
        #endif
        
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.userID.rawValue, el: inputID))
        addArrangedSubview(submitButtonGet)
        addArrangedSubview(formPutStackView)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputID.rx.text
            .orEmpty
            .map{ UInt($0) ?? 0 }
            .bind{
                self.requestedUserID = $0
                self.submitButtonGet.isEnabled = self.requestedUserID > 0
            }
            .disposed(by: disposeBag)
        
        inputName.rx.text.orEmpty.bind{self.formDataPut["name"] = $0}.disposed(by: disposeBag)
        inputEmail.rx.text.orEmpty.bind{self.formDataPut["email"] = $0}.disposed(by: disposeBag)
        inputPassword.rx.text.orEmpty.bind{self.formDataPut["password"] = $0}.disposed(by: disposeBag)
        inputPasswordConfirm.rx.text.orEmpty.bind{self.formDataPut["passwordConfirm"] = $0}.disposed(by: disposeBag)
        switchIsEmailConfirmed.rx.value.bind{self.formDataPut["isEmailConfirmed"] = $0}.disposed(by: disposeBag)
        
        submitButtonGet.rx.tap.asDriver().drive(onNext:{
            self.submitButtonGet.isEnabled = false
            self.serviceUsers.getUser(self.requestedUserID).subscribe { userModel in
                NotificationCenter.default.post(name: .showJSON, object: userModel)
                self.user = userModel
            } onError: { error in
                self.submitButtonGet.isEnabled = true
            } onCompleted: {
                self.submitButtonGet.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
        
        submitButtonPut.rx.tap.asDriver().drive(onNext:{
            if self.fileModule.images.count > 0 {
                self.formDataPut["files"] = self.fileModule.images[0].image?.pngData()
            }
            
            self.submitButtonPut.isEnabled = false
            self.serviceUsers.update(self.requestedUserID, self.formDataPut).subscribe { userModel in
                NotificationCenter.default.post(name: .showJSON, object: userModel)
                self.user = userModel
            } onError: { error in
                self.submitButtonPut.isEnabled = true
            } onCompleted: {
                self.submitButtonPut.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
extension FormUsersPutUsersUserIDModule: FileModuleDelegate {
    internal func fileModuleDidSelect(image: UIImage?) {
        // обновились прикрепленные файлы
    }
}
extension FormUsersPutUsersUserIDModule: UICollectionViewDelegate, UICollectionViewDataSource {
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filesAlreadyHas.count
    }
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
        cell.addSubview(filesAlreadyHas[indexPath.row])
        return cell
    }
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alert = UIAlertController(title: DictionaryWord.itRemoveImage.rawValue, message: nil, preferredStyle: .alert)
        let noAction = UIAlertAction(title: DictionaryWord.no.rawValue, style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: DictionaryWord.yes.rawValue, style: .default) { alert in
            let index = indexPath.row

            self.formDataPut.removeValue(forKey: "avatar")
            self.filesAlreadyHas.remove(at: index)
            collectionView.reloadData()
        }

        alert.addAction(yesAction)
        alert.addAction(noAction)

        presentationController.present(alert, animated: true, completion: nil)
    }
}
