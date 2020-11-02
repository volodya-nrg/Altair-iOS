import UIKit
import RxSwift

final class FormPropsGetPropsPropIDModule: FormBaseModule {
    private let serviceProps = PropService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    private var requestedPropID: UInt = 0
    
    private lazy var inputPropID: UITextField = {
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
extension FormPropsGetPropsPropIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.propID.rawValue, el: inputPropID))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputPropID.rx.text.orEmpty.bind {
            var isCorrect = false
            
            if let y = UInt($0) {
                self.requestedPropID = y
                isCorrect = self.requestedPropID > 0
            }
            
            self.submitButton.isEnabled = isCorrect
        }.disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceProps.getOne(self.requestedPropID).subscribe { propFullModel in
                NotificationCenter.default.post(name: .showJSON, object: propFullModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
