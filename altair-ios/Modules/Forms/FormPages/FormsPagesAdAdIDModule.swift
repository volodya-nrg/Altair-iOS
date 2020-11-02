import UIKit
import RxSwift

final class FormPagesAdAdIDModule: FormBaseModule {
    private let servicePages = PagesService()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private var adID: UInt = 0
    private let disposeBag = DisposeBag()
    
    private lazy var inputAdID: UITextField = {
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
extension FormPagesAdAdIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.adID.rawValue, el: inputAdID))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputAdID.rx.text
            .orEmpty
            .map{ UInt($0) ?? 0 }
            .bind {
                self.adID = $0
                self.submitButton.isEnabled = self.adID > 0
            }
            .disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.servicePages.pageAd(self.adID).subscribe { pageAdModel in
                NotificationCenter.default.post(name: .showJSON, object: pageAdModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
