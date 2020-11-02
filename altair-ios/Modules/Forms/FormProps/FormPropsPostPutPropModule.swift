import UIKit
import RxSwift

final class FormPropsPostPutPropModule: FormBaseModule {
    private let serviceProps = PropService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    
    private var formData: [String: Any] = [:] {
        didSet {
            let isCorrectTitle = (formData["title"] as? String ?? "").trim().count > 0
            let isCorrectName = (formData["name"] as? String ?? "").trim().count > 0
            let tmpKindPropID = formData["kindPropID"] as? String ?? "0"
            var isCorrectKindPropID = false
            
            if let x = UInt(tmpKindPropID) {
                isCorrectKindPropID = x >= 0 // на беке он обязателен, ноль в счет.
            }
            
            submitButton.isEnabled = isCorrectTitle && isCorrectName && isCorrectKindPropID
            
            #if DEBUG
                debugTextView.text = Helper.mapToString(formData)
            #endif
        }
    }
    public var propFull: PropFullModel? {
        didSet(x) {
            var tmpFormData: [String: Any] = [:]
            
            if let x = propFull {
                tmpFormData["propID"] = x.propID
                tmpFormData["title"] = x.title
                tmpFormData["name"] = x.name
                tmpFormData["kindPropID"] = String(x.kindPropID) // нужна именно строчка
                tmpFormData["suffix"] = x.suffix
                tmpFormData["comment"] = x.comment
                tmpFormData["privateComment"] = x.privateComment
                
                formData = tmpFormData
                
                inputTitle.text = x.title
                inputAttrName.text = x.name
                inputSuffix.text = x.suffix
                inputComment.text = x.comment
                inputPrivateComment.text = x.privateComment
                
                for (i, k) in kindProps.enumerated() {
                    if k.kindPropID == x.kindPropID {
                        inputKindTag.tag = Int(kindProps[i].kindPropID)
                        inputKindTag.text = kindProps[i].name
                        kindTagPickerView.selectRow(i, inComponent: 0, animated: true)
                        break
                    }
                }
                
                valuesModuleView.setItems(x.propID, x.values)
            }
        }
    }
    
    private lazy var valuesModuleView: DynamicValuesModule = {
        let x = DynamicValuesModule()
        x.delegate = self
        return x
    }()
    private lazy var inputPropID: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        x.text = "0"
        return x
    }()
    private let inputTitle = TextFieldFactory.create()
    private let inputAttrName: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private let inputSuffix: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private let inputComment: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private let inputPrivateComment: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private let selectAsTextarea: UITextView = {
        let x = UITextView()
        x.isSelectable = false
        x.isScrollEnabled = false
        x.heightAnchor.constraint(equalToConstant: 50).isActive = true
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
    public func reset() {
        inputTitle.rx.text.onNext("")
        inputAttrName.rx.text.onNext("")
        inputSuffix.rx.text.onNext("")
        inputComment.rx.text.onNext("")
        inputPrivateComment.rx.text.onNext("")
        inputKindTag.rx.text.onNext("")
        kindTagPickerView.selectRow(0, inComponent: 0, animated: true)
        
        valuesModuleView.reset()
        formData.removeAll()
        propFull = nil
    }
}
extension FormPropsPostPutPropModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: "\(DictionaryWord.title.rawValue) *", el: inputTitle))
        addArrangedSubview(Helper.generateRow(title: "\(DictionaryWord.attrName.rawValue) *", el: inputAttrName))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.suffix.rawValue, el: inputSuffix))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.comment.rawValue, el: inputComment))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.privateComment.rawValue, el: inputPrivateComment))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.kindOfTag.rawValue, el: inputKindTag))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.valueForProp.rawValue, el: valuesModuleView))
        addArrangedSubview(submitButton)
        
        #if DEBUG
            addArrangedSubview(debugTextView)
        #endif
    }
    func setConstrains() {
    }
    func addEvents() {
        inputTitle.rx.text.orEmpty.bind{self.formData["title"] = $0}.disposed(by: disposeBag)
        inputAttrName.rx.text.orEmpty.bind{self.formData["name"] = $0}.disposed(by: disposeBag)
        inputSuffix.rx.text.orEmpty.bind{self.formData["suffix"] = $0}.disposed(by: disposeBag)
        inputComment.rx.text.orEmpty.bind{self.formData["comment"] = $0}.disposed(by: disposeBag)
        inputPrivateComment.rx.text.orEmpty.bind {self.formData["privateComment"] = $0}.disposed(by: disposeBag)
        
        inputKindTag.rx.observe(Int.self, "tag").subscribe { el in
            self.formData["kindPropID"] = String(format: "%d", el ?? 0) // бек слушает String
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext: {
            self.submitButton.isEnabled = false
            
            if let x = self.propFull {
                self.serviceProps.update(x.propID, self.formData).subscribe { propFullModel in
                    NotificationCenter.default.post(name: .showJSON, object: propFullModel)
                } onError: { error in
                    self.submitButton.isEnabled = true
                } onCompleted: {
                    self.submitButton.isEnabled = true
                }.disposed(by: self.disposeBag)
                
            } else {
                self.serviceProps.create(self.formData).subscribe { propFullModel in
                    NotificationCenter.default.post(name: .showJSON, object: propFullModel)
                } onError: { error in
                    self.submitButton.isEnabled = true
                } onCompleted: {
                    self.submitButton.isEnabled = true
                }.disposed(by: self.disposeBag)
            }
            
        }).disposed(by: disposeBag)
    }
}
extension FormPropsPostPutPropModule: DynamicValuesModuleDelegate {
    func onChangeDynamicValues(_ items: [ValuePropModel]) {
        let jsonEncoder = JSONEncoder()
        
        do {
            let jsonData = try jsonEncoder.encode(items)
            let jObj = try JSONSerialization.jsonObject(with: jsonData)
            formData["values"] = jObj
            
        } catch (let error) {
            print(error)
        }
    }
}
