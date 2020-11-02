import UIKit
import RxSwift

final class AdCreateEditViewController: BaseViewController {
    private let serviceCat = CatService()
    private let serviceProfile = ProfileService()
    private let disposeBag = DisposeBag()
    public var adID: UInt = 0
    
    private let titleCatalog = MyText.getH2Label(DictionaryWord.catalogWithColon.rawValue)
    private let titleParams = MyText.getH2Label(DictionaryWord.parametresWithColon.rawValue)
    private lazy var catsHorizAccordionModule = CatsHorizAccordionModule()
    private lazy var adFormModule: AdFormModule = {
        let x = AdFormModule(presentationController: self)
        return x
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = (adID > 0 ? DictionaryWord.editAd.rawValue : DictionaryWord.addAd.rawValue)
        
        boxStackView.addArrangedSubview(titleCatalog)
        boxStackView.addArrangedSubview(catsHorizAccordionModule)
        boxStackView.addArrangedSubview(titleParams)
        boxStackView.addArrangedSubview(adFormModule)
        
        // сделать запрос на сервер чтоб получить данные для редактирования объявления
        if adID > 0 {
            serviceProfile.getAd(adID).subscribe { adFullModel in
                self.adFormModule.adFull = adFullModel
                self.catsHorizAccordionModule.catID = adFullModel.catID // тут доп. берутся полные данные с сервера для каталога
            } onError: { error in
            } onCompleted: {
            }.disposed(by: disposeBag)
        }
    }
}
