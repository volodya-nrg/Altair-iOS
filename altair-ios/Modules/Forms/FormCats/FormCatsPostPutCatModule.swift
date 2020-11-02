import UIKit
import RxSwift

final class FormCatsPostPutCatModule: FormBaseModule {
    private let serviceCats = CatService()
    private let disposeBag = DisposeBag()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    
    private var formData: [String: Any] = [:] {
        didSet {
            let name = formData["name"] as? String ?? ""
            let pos = formData["pos"] as? UInt ?? 0
            
            if catFull != nil {
                let parentID = formData["parentID"] as? UInt ?? 0 // именно UInt
                let catID = formData["catID"] as? UInt ?? 0
                submitButton.isEnabled = name.count >= 2 && parentID > 0 && pos >= 0 && catID > 0
            } else {
                let sParentID = formData["parentID"] as? String ?? "0" // именно String
                submitButton.isEnabled = name.count >= 2 && sParentID.count > 0 && sParentID != "0" && pos >= 0
            }
            
            #if DEBUG
                debugTextView.text = Helper.mapToString(formData)
            #endif
        }
    }
    public var catFull: CatFullModel? {
        didSet(x) {
            var tmpFormData: [String: Any] = [:]
            
            if let x = catFull {
                tmpFormData["catID"] = x.catID
                tmpFormData["name"] = x.name
                tmpFormData["slug"] = x.name
                tmpFormData["parentID"] = x.parentID // именно UInt
                tmpFormData["pos"] = x.pos
                tmpFormData["priceAlias"] = x.priceAlias
                tmpFormData["priceSuffix"] = x.priceSuffix
                tmpFormData["titleHelp"] = x.titleHelp
                tmpFormData["titleComment"] = x.titleComment
                tmpFormData["isAutogenerateTitle"] = x.isAutogenerateTitle
                tmpFormData["isDisabled"] = x.isDisabled
                
                formData = tmpFormData
                
                catTreeOneLevel.forEach { el in
                    if el.catID == x.parentID {
                        inputCatTreeOneLevel.text = el.name
                    }
                }
                
                inputName.text = x.name
                inputSlug.text = x.slug
                inputPos.text = String(x.pos)
                inputPriceAlias.text = x.priceAlias
                inputPriceSuffix.text = x.priceSuffix
                inputTitleHelp.text = x.titleHelp
                inputTitleComment.text = x.titleComment
                switchIsAutogenerateTitle.isOn = x.isAutogenerateTitle
                switchIsDisabled.isOn = x.isDisabled
                
                var propsAssigned: [PropAssignedForCatModel] = []
                x.props.forEach { propsAssigned.append(PropAssignedForCatModel($0)) }
                if propsAssigned.count > 0 {
                    dynamicPropsModule.setItems(propsAssigned)
                }
                
                submitButton.setTitle(DictionaryWord.save.rawValue, for: .normal)
                
                arrangedSubviews.forEach { $0.removeFromSuperview() }
                attachElements()
            }
        }
    }
    private let inputName = TextFieldFactory.create()
    private let inputSlug: UITextField = {
        let x = TextFieldFactory.create()
        x.isEnabled = false
        return x
    }()
    private lazy var inputPos: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        return x
    }()
    private let inputPriceAlias: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private let inputPriceSuffix: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private let inputTitleHelp: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private let inputTitleComment: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private let switchIsAutogenerateTitle = UISwitch()
    private let switchIsDisabled = UISwitch()
    private lazy var dynamicPropsModule: DynamicPropsModule = {
        let x = DynamicPropsModule(inputProps)
        x.delegate = self
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
extension FormCatsPostPutCatModule: DisciplineProtocol {
    func attachElements() {
        let hasCatFull = catFull != nil
        
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.name.rawValue, el: inputName))
        
        if hasCatFull {
            addArrangedSubview(Helper.generateRow(title: DictionaryWord.slug.rawValue, el: inputSlug))
        }
        
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.parentID.rawValue, el: inputCatTreeOneLevel))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.pos.rawValue, el: inputPos))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.aliasForPrice.rawValue, el: inputPriceAlias))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.suffixOnPrice.rawValue, el: inputPriceSuffix))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.helperTextForTitle.rawValue, el: inputTitleHelp))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.commentUnderTitle.rawValue, el: inputTitleComment))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.isAutogenerateTitle.rawValue, el: switchIsAutogenerateTitle))
        
        if hasCatFull {
            addArrangedSubview(Helper.generateRow(title: DictionaryWord.isDisabled.rawValue, el: switchIsDisabled))
        }
        
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.assignedProps.rawValue, el: dynamicPropsModule))
        addArrangedSubview(submitButton)
        
        #if DEBUG
            addArrangedSubview(debugTextView)
        #endif
    }
    func setConstrains() {
    }
    func addEvents() {
        inputName.rx.text.orEmpty.bind{self.formData["name"] = $0}.disposed(by: disposeBag)
        
        inputCatTreeOneLevel.rx.observe(Int.self, "tag").subscribe { el in
            guard !el.isStopEvent else {return}
            
            if self.catFull != nil {
                self.formData["parentID"] = UInt(el.element!!) // именно UInt
            } else {
                self.formData["parentID"] = String(el.element!!) // именно String
            }
        }.disposed(by: disposeBag)
        
        inputPos.rx.text
            .orEmpty
            .map{ UInt($0) ?? 0 }
            .bind{ self.formData["pos"] = $0 }
            .disposed(by: disposeBag)
        
        inputPriceAlias.rx.text.orEmpty.bind{ self.formData["priceAlias"] = $0 }.disposed(by: disposeBag)
        inputPriceSuffix.rx.text.orEmpty.bind{ self.formData["priceSuffix"] = $0 }.disposed(by: disposeBag)
        inputTitleHelp.rx.text.orEmpty.bind{ self.formData["titleHelp"] = $0 }.disposed(by: disposeBag)
        inputTitleComment.rx.text.orEmpty.bind{ self.formData["titleComment"] = $0 }.disposed(by: disposeBag)
        switchIsAutogenerateTitle.rx.value.bind { self.formData["isAutogenerateTitle"] = $0 }.disposed(by: disposeBag)
        switchIsDisabled.rx.value.bind { self.formData["isDisabled"] = $0 }.disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            
            if let x = self.catFull {
                self.serviceCats.update(x.catID, self.formData).subscribe { catFullModel in
                    NotificationCenter.default.post(name: .showJSON, object: catFullModel)
                } onError: { error in
                    self.submitButton.isEnabled = true
                } onCompleted: {
                    self.submitButton.isEnabled = true
                }.disposed(by: self.disposeBag)
            } else {
                self.serviceCats.create(self.formData).subscribe { catFullModel in
                    NotificationCenter.default.post(name: .showJSON, object: catFullModel)
                } onError: { error in
                    self.submitButton.isEnabled = true
                } onCompleted: {
                    self.submitButton.isEnabled = true
                }.disposed(by: self.disposeBag)
            }
            
        }).disposed(by: disposeBag)
    }
}
extension FormCatsPostPutCatModule: DynamicPropsModuleDelegate {
    func onChangeDynamicProps(_ items: [PropAssignedForCatModel]) {
        let jsonEncoder = JSONEncoder()
        
        do {
            let jsonData = try jsonEncoder.encode(items)
            let jObj = try JSONSerialization.jsonObject(with: jsonData)
            formData["propsAssignedForCat"] = jObj
            
        } catch (let error) {
            print(error)
        }
    }
}
