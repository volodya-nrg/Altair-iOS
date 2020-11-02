import UIKit
import RxSwift

final class FormCatsPutCatsCatIDModule: FormBaseModule {
    private let serviceCats = CatService()
    private let commonForm: FormCatsPostPutCatModule = {
        let x = FormCatsPostPutCatModule()
        x.isHidden = true
        return x
    }()
    private let submitButtonGet = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let disposeBag = DisposeBag()
    private var requestedCatID: UInt = 0
    private var catFull: CatFullModel? {
        didSet {
            guard let x = catFull else {
                commonForm.isHidden = true
                return
            }
            
            commonForm.isHidden = false
            commonForm.catFull = x
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
extension FormCatsPutCatsCatIDModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.categotyID.rawValue, el: inputCatTreeOneLevel))
        addArrangedSubview(submitButtonGet)
        addArrangedSubview(commonForm)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputCatTreeOneLevel.rx.observe(Int.self, "tag").subscribe { el in
            self.requestedCatID = UInt(el ?? 0)
            self.submitButtonGet.isEnabled = self.requestedCatID > 0
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
        
        submitButtonGet.rx.tap.asDriver().drive(onNext:{
            self.submitButtonGet.isEnabled = false
            self.serviceCats.getOne(self.requestedCatID, false).subscribe { catFullModel in
                NotificationCenter.default.post(name: .showJSON, object: catFullModel)
                self.catFull = catFullModel
            } onError: { error in
                self.submitButtonGet.isEnabled = true
            } onCompleted: {
                self.submitButtonGet.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
