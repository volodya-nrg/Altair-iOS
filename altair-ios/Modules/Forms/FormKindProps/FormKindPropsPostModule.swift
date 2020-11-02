import UIKit
import RxSwift

final class FormKindPropsPostModule: FormBaseModule {
    private let serviceKindProps = KindPropsService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    
    private var formData: [String: Any] = [:] {
        didSet {
            submitButton.isEnabled = (formData["name"] as? String ?? "").trim().count > 0
            
            #if DEBUG
                debugTextView.text = Helper.mapToString(formData)
            #endif
        }
    }
    private let inputName: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
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
extension FormKindPropsPostModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.name.rawValue, el: inputName))
        addArrangedSubview(submitButton)
        
        #if DEBUG
            addArrangedSubview(debugTextView)
        #endif
    }
    func setConstrains() {
    }
    func addEvents() {
        inputName.rx.text.orEmpty.bind{self.formData["name"] = $0}.disposed(by: disposeBag)
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceKindProps.create(self.formData).subscribe { kindPropModel in
                NotificationCenter.default.post(name: .showJSON, object: kindPropModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
