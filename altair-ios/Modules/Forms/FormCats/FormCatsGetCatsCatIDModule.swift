import UIKit
import RxSwift

final class FormCatsGetCatsCatIDModule: FormBaseModule {
    private let serviceCats = CatService()
    private let disposeBag = DisposeBag()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let switchWithPropsOnlyFiltered = UISwitch()
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
extension FormCatsGetCatsCatIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.categotyID.rawValue, el: inputCatTreeOneLevel))
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.propsAsFilters.rawValue, el: switchWithPropsOnlyFiltered))
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
            self.serviceCats.getOne(self.requestedCatID, self.switchWithPropsOnlyFiltered.isOn).subscribe { catFullModel in
                NotificationCenter.default.post(name: .showJSON, object: catFullModel)
            } onError: { error in
                self.submitButton.isEnabled = true
            } onCompleted: {
                self.submitButton.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
