import UIKit
import RxSwift

final class FormKindPropsGetOneModule: FormBaseModule {
    private let serviceKindProps = KindPropsService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    private var requestedKindPropID: UInt = 0
    
    private lazy var inputKindPropID: UITextField = {
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
extension FormKindPropsGetOneModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.kindPropID.rawValue, el: inputKindPropID))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputKindPropID.rx.text
            .orEmpty
            .bind{
                self.requestedKindPropID = UInt($0) ?? 0
                self.submitButton.isEnabled = self.requestedKindPropID > 0
            }
            .disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceKindProps.getOne(self.requestedKindPropID).subscribe { kindPropModel in
                NotificationCenter.default.post(name: .showJSON, object: kindPropModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
