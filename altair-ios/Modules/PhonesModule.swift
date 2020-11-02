import UIKit
import RxSwift

protocol PhonesModuleDatasource: class {
    func showAlertBeforeDeletePhone(_ index: Int)
}
enum PhonesStates {
    case openForm
    case closeForm
    case didSendInputNumber
    case toDefault
}

final class PhonesModule: UIView {
    private let servicePhone = PhoneService()
    private let cellID = "PhonesModuleCellID"
    private var savePhone = ""
    private var timeLockInputPhone: UInt = 0
    public var phones: [PhoneModel] = [] {
        didSet {
            phonesStackView.subviews.forEach { $0.removeFromSuperview() }
            for (i, _) in phones.enumerated() {
                phonesStackView.addArrangedSubview(createRowPhone(i))
            }
        }
    }
    private var time: Timer?
    private let disposeBag = DisposeBag()
    public weak var dataSource: PhonesModuleDatasource?
    
    private let boxStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.alignment = .leading
        x.spacing = 10
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    private let titleLabel = MyText.getH3Label(DictionaryWord.phoneNumbersWithColon.rawValue)
    private let phonesStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 5
        return x
    }()
    private let formElementsStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 5
        x.isHidden = true
        return x
    }()
    private let rowAddNumberStackView: UIStackView = {
        let x = UIStackView()
        x.spacing = 5
        return x
    }()
    private let inputNumberTextField = TextFieldFactory.create(.roundedRect, DictionaryWord.phoneNumber.rawValue)
    private let sendNewNumberButton = ButtonFactory.create(.system, DictionaryWord.send.rawValue)
    private let rowCheckCodeStackView: UIStackView = {
        let x = UIStackView()
        x.spacing = 5
        x.isHidden = true
        return x
    }()
    private let inputCodeTextField = TextFieldFactory.create(.roundedRect, DictionaryWord.confirmationCode.rawValue)
    private let sendCodeButton = ButtonFactory.create(.system, DictionaryWord.send.rawValue)
    private let textUnlockLabel = MyText.getSmallMuteLabel(DictionaryWord.timeOfLock.rawValue)
    private let togglerForAddButton = ButtonFactory.create(.system, DictionaryWord.addWithPrefixPlus.rawValue)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        attachElements()
        setConstrains()
        addEvents()
        
        NotificationCenter.default.post(name: .phoneModuleListener, object: PhonesStates.toDefault)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    private func createRowPhone(_ indexInArray: Int) -> UIStackView {
        let x = UIStackView()
        x.distribution = .equalSpacing
        
        let titleLabel = UILabel()
        titleLabel.text = "+\(phones[indexInArray].number)"
        
        let btn = UIButton(type: .close)
        
        x.addArrangedSubview(titleLabel)
        x.addArrangedSubview(btn)
        
        btn.rx.tap.asDriver().drive(onNext:{
            self.dataSource?.showAlertBeforeDeletePhone(indexInArray)
        }).disposed(by: disposeBag)
        
        return x
    }
    private func stopTimer() {
        guard let x = time else {return}
        x.invalidate()
        time = nil
    }
}
extension PhonesModule: DisciplineProtocol {
    internal func attachElements() {
        rowAddNumberStackView.addArrangedSubview(inputNumberTextField)
        rowAddNumberStackView.addArrangedSubview(sendNewNumberButton)
        
        rowCheckCodeStackView.addArrangedSubview(inputCodeTextField)
        rowCheckCodeStackView.addArrangedSubview(sendCodeButton)
        
        formElementsStackView.addArrangedSubview(rowAddNumberStackView)
        formElementsStackView.addArrangedSubview(textUnlockLabel)
        formElementsStackView.addArrangedSubview(rowCheckCodeStackView)
        
        boxStackView.addArrangedSubview(titleLabel)
        boxStackView.addArrangedSubview(phonesStackView)
        boxStackView.addArrangedSubview(formElementsStackView)
        boxStackView.addArrangedSubview(togglerForAddButton)
        
        addSubview(boxStackView)
    }
    internal func setConstrains() {
        addConstraints([
            boxStackView.topAnchor.constraint(equalTo: topAnchor),
            boxStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            boxStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            boxStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            phonesStackView.widthAnchor.constraint(equalTo: boxStackView.widthAnchor),
        ])
    }
    internal func addEvents() {
        togglerForAddButton.rx.tap.asDriver().drive(onNext:{
            NotificationCenter.default.post(name: .phoneModuleListener,
                                            object: (self.formElementsStackView.isHidden ?
                                                        PhonesStates.openForm :
                                                        PhonesStates.closeForm))
        }).disposed(by: disposeBag)
        
        sendNewNumberButton.rx.tap.asDriver().drive(onNext:{
            let phoneNumber = self.inputNumberTextField.text?.trim() ?? ""
            
            do {
                let regex = try NSRegularExpression(pattern: "^(7|9)\\d{10,11}$")
                let range = NSRange(location: 0, length: phoneNumber.count)
                guard regex.firstMatch(in: phoneNumber, range: range) != nil else {
                    NotificationCenter.default.post(name: .flyError,
                                                    object: FlyErrorModule(kindVisual: .warning,
                                                                           msg: DictionaryWord.notFitPhoneByMask.rawValue))
                    return
                }
                
            } catch {
                NotificationCenter.default.post(name: .flyError,
                                                object: FlyErrorModule(kindVisual: .danger,
                                                                       msg: error.localizedDescription))
                return
            }
            
            self.servicePhone.create(["number": phoneNumber]).subscribe { phoneModel in
                self.savePhone = phoneModel.number
                NotificationCenter.default.post(name: .phoneModuleListener,
                                                object: PhonesStates.didSendInputNumber)
            } onError: { error in
            } onCompleted: {
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
        
        sendCodeButton.rx.tap.asDriver().drive(onNext:{
            let code = self.inputCodeTextField.text?.trim() ?? ""
            
            if code.count < 5 {
                NotificationCenter.default.post(name: .flyError,
                                                object: FlyErrorModule(kindVisual: .danger,
                                                                       msg: DictionaryWord.codeIsShort.rawValue))
                return
            }

            self.sendCodeButton.isEnabled = false
            self.servicePhone.check(self.savePhone, code).subscribe { userExtModel in
                Helper.profile$.onNext(userExtModel)
                NotificationCenter.default.post(name: .phoneModuleListener, object: PhonesStates.toDefault)
            } onError: { error in
                self.sendCodeButton.isEnabled = true
            } onCompleted: {
                self.sendCodeButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onListenerStates(_:)), name: .phoneModuleListener, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onListenerRemovePhone(_:)), name: .deletePhone, object: nil)
    }
}
extension PhonesModule {
    // states
    @objc private func onListenerStates(_ notif: Notification) {
        let state = notif.object as! PhonesStates
        
        switch state {
        case .openForm:
            stateOpenForm()
        case .closeForm:
            stateCloseForm()
        case .didSendInputNumber:
            stateDidSendInputNumber()
        case .toDefault:
            stateToDefault()
        }
    }
    @objc private func stateOpenForm() {
        formElementsStackView.isHidden = false
        togglerForAddButton.setTitle(DictionaryWord.hidden.rawValue, for: .normal)
    }
    @objc private func stateCloseForm() {
        formElementsStackView.isHidden = true
        togglerForAddButton.setTitle(DictionaryWord.addWithPrefixPlus.rawValue, for: .normal)
    }
    @objc private func stateDidSendInputNumber() {
        rowCheckCodeStackView.isHidden = false
        inputNumberTextField.isEnabled = false
        sendNewNumberButton.isEnabled = false
        textUnlockLabel.isHidden = false
        
        timeLockInputPhone = Helper.timeSecBlockForPhoneSend // выставим начальное значение
        time = Timer.scheduledTimer(timeInterval: 1,
                                    target: self,
                                    selector: #selector(loop),
                                    userInfo: nil,
                                    repeats: true)
    }
    @objc private func stateToDefault() {
        inputNumberTextField.text = ""
        inputNumberTextField.isEnabled = true
        sendNewNumberButton.isEnabled = true
        
        inputCodeTextField.text = "" // должен быть всегда включен
        sendCodeButton.isEnabled = true
        
        rowCheckCodeStackView.isHidden = true
        textUnlockLabel.text = String(format: DictionaryWord.timeOfLock.rawValue, 0)
        textUnlockLabel.isHidden = true
        
        formElementsStackView.isHidden = true
        togglerForAddButton.setTitle(DictionaryWord.addWithPrefixPlus.rawValue, for: .normal)
        savePhone = ""
    }
    // \ states
    
    @objc private func onListenerRemovePhone(_ notif: Notification) {
        let index = notif.object as! Int
        
        servicePhone.delete(phones[index].number).subscribe { userExtModel in
            Helper.profile$.onNext(userExtModel)
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
    @objc private func loop() {
        timeLockInputPhone -= 1
        textUnlockLabel.text = String(format: DictionaryWord.timeOfLock.rawValue, timeLockInputPhone)
        
        if timeLockInputPhone < 1 {
            inputNumberTextField.isEnabled = true
            sendNewNumberButton.isEnabled = true
            stopTimer()
        }
    }
}
