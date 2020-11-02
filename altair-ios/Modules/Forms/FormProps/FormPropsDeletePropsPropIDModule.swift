import UIKit
import RxSwift

final class FormPropsDeletePropsPropIDModule: FormBaseModule {
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
    private func reset() {
        requestedPropID = 0
        inputPropID.rx.text.onNext(String(requestedPropID))
    }
}
extension FormPropsDeletePropsPropIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.propID.rawValue, el: inputPropID))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputPropID.rx.text
            .orEmpty
            .map{ UInt($0) ?? 0 }
            .bind {
                self.requestedPropID = $0
                self.submitButton.isEnabled = self.requestedPropID > 0
            }
            .disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceProps.delete(self.requestedPropID).subscribe { emptyModel in
                self.reset()
                NotificationCenter.default.post(name: .showJSON, object: emptyModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
