import UIKit
import RxSwift

final class FormUsersDeleteUsersUserIDModule: FormBaseModule {
    private let serviceUsers = UserService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    private var requestedUserID: UInt = 0
    
    private lazy var inputUserID: UITextField = {
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
        requestedUserID = 0
        inputUserID.rx.text.onNext(String(requestedUserID))
    }
}
extension FormUsersDeleteUsersUserIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.userID.rawValue, el: inputUserID))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputUserID.rx.text
            .orEmpty
            .map{ UInt($0) ?? 0 }
            .bind{
                self.requestedUserID = $0
                self.submitButton.isEnabled = self.requestedUserID > 0
            }
            .disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext: {
            self.submitButton.isEnabled = false
            self.serviceUsers.delete(self.requestedUserID).subscribe { emptyModel in
                self.reset()
                NotificationCenter.default.post(name: .showJSON, object: emptyModel)
            } onError: { error in
            } onCompleted: {
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
