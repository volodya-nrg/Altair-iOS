import UIKit
import RxSwift

final class FormPagesMainModule: FormBaseModule {
    private let servicePages = PagesService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private var limit: UInt = 4
    private let disposeBag = DisposeBag()
    
    private lazy var inputLimit: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        x.text = "2"
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
extension FormPagesMainModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.limit.rawValue, el: inputLimit))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputLimit.rx.text
            .orEmpty
            .map{ UInt($0) ?? 0 }
            .bind{
                self.limit = $0
                self.submitButton.isEnabled = self.limit > 0 && self.limit <= 10
            }
            .disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.servicePages.pageMain(limit: self.limit).subscribe { pageMainModel in
                NotificationCenter.default.post(name: .showJSON, object: pageMainModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
