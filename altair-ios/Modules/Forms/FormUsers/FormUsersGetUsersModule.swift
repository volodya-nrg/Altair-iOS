import UIKit
import RxSwift

final class FormUsersGetUsersModule: FormBaseModule {
    private let serviceUsers = UserService()
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
extension FormUsersGetUsersModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceUsers.getUsers().subscribe { userModels in
                NotificationCenter.default.post(name: .showJSON, object: userModels)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
