import UIKit
import RxSwift

final class FormPropsPutPropsPropIDModule: FormBaseModule {
    private let serviceProps = PropService()
    private let commonForm: FormPropsPostPutPropModule = {
        let x = FormPropsPostPutPropModule()
        x.isHidden = true
        return x
    }()
    private let submitButtonGet = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    private var requestedPropID: UInt = 0
    
    private var propFull: PropFullModel? {
        didSet {
            if propFull != nil {
                commonForm.isHidden = false
                commonForm.propFull = propFull
                
            } else {
                commonForm.reset()
                commonForm.isHidden = true
            }
        }
    }
    private lazy var inputPropIDGet: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        x.text = "0"
        return x
    }()
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
extension FormPropsPutPropsPropIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.propID.rawValue, el: inputPropIDGet))
        addArrangedSubview(submitButtonGet)
        addArrangedSubview(commonForm)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputPropIDGet.rx.text.orEmpty.bind {
            var isCorrect = false
            
            if let y = UInt($0) {
                self.requestedPropID = y
                isCorrect = self.requestedPropID > 0
            }
            
            self.submitButtonGet.isEnabled = isCorrect
        }.disposed(by: disposeBag)
        
        submitButtonGet.rx.tap.asDriver().drive(onNext:{
            self.submitButtonGet.isEnabled = false
            self.serviceProps.getOne(self.requestedPropID).subscribe { propFullModel in
                NotificationCenter.default.post(name: .showJSON, object: propFullModel)
                self.propFull = propFullModel
            } onError: { error in
                self.submitButtonGet.isEnabled = true
            } onCompleted: {
                self.submitButtonGet.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
