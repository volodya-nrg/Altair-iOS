import UIKit
import RxSwift

final class FormKindPropsPutModule: FormBaseModule {
    private let serviceKindProps = KindPropsService()
    private let submitButtonGet = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let submitButtonPut = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    private var requestedKindPropID: UInt = 0
    private var formDataPut: [String: Any] = [:] {
        didSet {
            let isCorrectID = (formDataPut["kindPropID"] as? UInt ?? 0) > 0
            let isCorrectName = (formDataPut["name"] as? String ?? "").count > 0
            submitButtonPut.isEnabled = isCorrectID && isCorrectName
            
            #if DEBUG
                debugTextView.text = Helper.mapToString(formDataPut)
            #endif
        }
    }
    
    private var kindProp: KindPropModel? {
        didSet {
            guard let x = kindProp else {
                formDataPut.removeAll()
                formPutStackView.isHidden = true
                return
            }
            
            formPutStackView.isHidden = false
            inputKindPropName.text = x.name
            formDataPut = [
                "kindPropID": x.kindPropID,
                "name": x.name,
            ]
        }
    }
    private let formPutStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 10
        x.isHidden = true
        return x
    }()
    
    private lazy var inputKindPropIDGet: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        x.text = "0"
        return x
    }()
    private lazy var inputKindPropIDPut: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        x.text = "0"
        return x
    }()
    private let inputKindPropName = TextFieldFactory.create()
    
    override init() {
        super.init()
        
        attachElements()
        setConstrains()
        addEvents()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension FormKindPropsPutModule: DisciplineProtocol {
    func attachElements() {
        formPutStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.name.rawValue, el: inputKindPropName))
        formPutStackView.addArrangedSubview(submitButtonPut)

        #if DEBUG
            formPutStackView.addArrangedSubview(debugTextView)
        #endif
        
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.kindPropID.rawValue, el: inputKindPropIDGet))
        addArrangedSubview(submitButtonGet)
        addArrangedSubview(formPutStackView)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputKindPropIDGet.rx.text.orEmpty.bind{
            var isCorrect = false
            
            if let x = UInt($0) {
                self.requestedKindPropID = x
                isCorrect = self.requestedKindPropID > 0
            }
            
            self.submitButtonGet.isEnabled = isCorrect
        }.disposed(by: disposeBag)
        
        inputKindPropName.rx.text.orEmpty.bind{self.formDataPut["name"] = $0}.disposed(by: disposeBag)
        
        submitButtonGet.rx.tap.asDriver().drive(onNext:{
            self.submitButtonGet.isEnabled = false
            self.serviceKindProps.getOne(self.requestedKindPropID).subscribe { kindPropModel in
                NotificationCenter.default.post(name: .showJSON, object: kindPropModel)
                self.kindProp = kindPropModel
            } onError: { error in
                self.submitButtonGet.isEnabled = true
            } onCompleted: {
                self.submitButtonGet.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
        
        submitButtonPut.rx.tap.asDriver().drive(onNext:{
            self.submitButtonPut.isEnabled = false
            guard let x = self.kindProp else {return}
            self.serviceKindProps.update(x.kindPropID, self.formDataPut).subscribe { kindPropModel in
                NotificationCenter.default.post(name: .showJSON, object: kindPropModel)
            } onError: { error in
                self.submitButtonPut.isEnabled = true
            } onCompleted: {
                self.submitButtonPut.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
