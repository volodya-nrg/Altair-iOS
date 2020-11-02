import UIKit
import RxSwift

final class FormPropsGetPropsModule: FormBaseModule {
    private let serviceProps = PropService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    
    private var formData: [String: Any] = [:] {
        didSet {
            submitButton.isEnabled = (formData["catID"] as? Int ?? 0) > 0
            
            #if DEBUG
                debugTextView.text = Helper.mapToString(formData)
            #endif
        }
    }
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
extension FormPropsGetPropsModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.categotyID.rawValue, el: inputCatTreeOneLevel))
        addArrangedSubview(submitButton)
        
        #if DEBUG
            addArrangedSubview(debugTextView)
        #endif
    }
    func setConstrains() {
    }
    func addEvents() {
        inputCatTreeOneLevel.rx.observe(Int.self, "tag").subscribe { el in
            self.formData["catID"] = el
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceProps.getPropsFullForCat(self.formData).subscribe { propFullModels in
                NotificationCenter.default.post(name: .showJSON, object: propFullModels)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
