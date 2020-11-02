import UIKit
import RxSwift

final class FormAdsPostAdsModule: FormBaseModule {
    private let serviceCat = CatService()
    private let adFormModule: AdFormModule
    private let disposeBag = DisposeBag()
    
    init(presentationController: UIViewController) {
        adFormModule = AdFormModule(presentationController: presentationController, isEditThroughAdmin: true)
        super.init()
        
        attachElements()
        setConstrains()
        addEvents()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension FormAdsPostAdsModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.categotyID.rawValue, el: inputCatTreeOneLevel))
        addArrangedSubview(adFormModule)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputCatTreeOneLevel.rx.observe(Int.self, "tag").subscribe { el in
            guard let catTree = self.catTree else {return}
            let catID = UInt(el ?? 0)
            
            if Helper.isLeaf(catTree.childes, catID) > 0 {
                self.serviceCat.getOne(catID, false).subscribe { catFullModel in
                    NotificationCenter.default.post(name: .catsHorizAccorditionCatFull, object: catFullModel)
                } onError: { error in
                } onCompleted: {
                }.disposed(by: self.disposeBag)
            }
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
}
