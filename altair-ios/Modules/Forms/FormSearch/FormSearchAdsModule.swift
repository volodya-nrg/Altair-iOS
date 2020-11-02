import UIKit
import RxSwift

final class FormSearchAdsModule: FormBaseModule {
    private let serviceSearch = SearchService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    
    private var formData: [String: Any] = [:] {
        didSet {
            let isCorrectQuery = (formData["q"] as? String ?? "").count >= 2
            let isCorrectCatID = (formData["catID"] as? UInt ?? 0) >= 0 // ноль в счет - поиск глобально по всему
            let isCorrectOffset = (formData["offset"] as? UInt ?? 0) >= 0
            let tmpLimit = formData["limit"] as? UInt ?? 0
            let isCorrectLimit = tmpLimit >= 1 && tmpLimit <= 10

            submitButton.isEnabled = isCorrectQuery && isCorrectCatID && isCorrectLimit && isCorrectOffset
            
            #if DEBUG
                debugTextView.text = Helper.mapToString(formData)
            #endif
        }
    }
    private let inputSearch: UITextField = {
        let x = TextFieldFactory.create()
        x.autocapitalizationType = .none
        return x
    }()
    private lazy var inputLimit: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        x.text = "5"
        return x
    }()
    private lazy var inputOffset: UITextField = {
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
extension FormSearchAdsModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.searchPhrase.rawValue, el: inputSearch))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.categotyID.rawValue, el: inputCatTreeOneLevel))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.limit.rawValue, el: inputLimit))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.offset.rawValue, el: inputOffset))
        addArrangedSubview(submitButton)
        addArrangedSubview(debugTextView)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputSearch.rx.text.orEmpty.bind{self.formData["q"] = $0}.disposed(by: disposeBag)
        inputLimit.rx.text.orEmpty.map{ UInt($0) ?? 0 }.bind{self.formData["limit"] = $0}.disposed(by: disposeBag)
        inputOffset.rx.text.orEmpty.map{ UInt($0) ?? 0 }.bind{self.formData["offset"] = $0}.disposed(by: disposeBag)
        inputCatTreeOneLevel.rx.observe(Int.self, "tag").subscribe {
            self.formData["catID"] = $0
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
       
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceSearch.ads(self.formData).subscribe { adFullModels in
                NotificationCenter.default.post(name: .showJSON, object: adFullModels)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
