import UIKit
import RxSwift

final class FormCatsDeleteCatsCatIDModule: FormBaseModule {
    private let serviceCats = CatService()
    private let disposeBag = DisposeBag()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private var requestedCatID: UInt = 0
    
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
extension FormCatsDeleteCatsCatIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.categotyID.rawValue, el: inputCatTreeOneLevel))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputCatTreeOneLevel.rx.observe(Int.self, "tag").subscribe { el in
            self.requestedCatID = UInt(el ?? 0)
            self.submitButton.isEnabled = self.requestedCatID > 0
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
        
        submitButton.rx.tap.asDriver().drive(onNext: {
            self.submitButton.isEnabled = false
            self.serviceCats.delete(self.requestedCatID).subscribe { emptyModel in
                NotificationCenter.default.post(name: .showJSON, object: emptyModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
