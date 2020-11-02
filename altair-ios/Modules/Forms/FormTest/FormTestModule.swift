import UIKit
import RxSwift

final class FormTestModule: FormBaseModule {
    private let serviceTest = TestService()
    private let disposeBag = DisposeBag()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    
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
extension FormTestModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        submitButton.rx.tap.asDriver().drive(onNext: {
            self.submitButton.isEnabled = false
            self.serviceTest.request().subscribe { emptyModel in
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
