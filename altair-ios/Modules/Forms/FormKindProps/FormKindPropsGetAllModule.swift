import UIKit
import RxSwift

final class FormKindPropsGetAllModule: FormBaseModule {
    private let serviceKindProps = KindPropsService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    
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
extension FormKindPropsGetAllModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceKindProps.getAll().subscribe { kindPropModels in
                NotificationCenter.default.post(name: .showJSON, object: kindPropModels)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
