import UIKit
import RxSwift

final class FormAdsGetAdsAdIDModule: FormBaseModule {
    private let serviceAds = AdService()
    private let disposeBag = DisposeBag()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private var requestedAdID: UInt = 0
    
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
extension FormAdsGetAdsAdIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.adID.rawValue, el: inputAdID))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputAdID.rx.text.orEmpty.bind {
            self.requestedAdID = UInt($0) ?? 0
            self.submitButton.isEnabled = self.requestedAdID > 0
        }.disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            self.serviceAds.getOne(self.requestedAdID).subscribe { adFullModel in
                NotificationCenter.default.post(name: .showJSON, object: adFullModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
