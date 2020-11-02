import UIKit
import RxSwift

final class FormAdsPutAdsAdIDModule: FormBaseModule {
    private let serviceAds = AdService()
    private let serviceCat = CatService()
    private let adFormModule: AdFormModule
    private let disposeBag = DisposeBag()
    private let submitButtonGet = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private var requestedAdID: UInt = 0
    
    private var adFull: AdFullModel? {
        didSet {
            if let x = adFull {
                formPutStackView.isHidden = false
                for (i, k) in catTreeOneLevel.enumerated() {
                    if k.catID == x.catID {
                        inputCatTreeOneLevel.tag = Int(catTreeOneLevel[i].catID)
                        inputCatTreeOneLevel.text = catTreeOneLevel[i].name
                        catTreePickerView.selectRow(i, inComponent: 0, animated: true)
                        break
                    }
                }
            } else {
                catTreePickerView.selectRow(0, inComponent: 0, animated: true)
                adFormModule.adFull = nil
                formPutStackView.isHidden = true
            }
        }
    }
    private let formPutStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 10
        x.isHidden = true
        return x
    }()
    private lazy var inputAdIDGet: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        x.text = "0"
        return x
    }()
    
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
extension FormAdsPutAdsAdIDModule: DisciplineProtocol {
    func attachElements() {
        formPutStackView.addArrangedSubview(Helper.generateRow(title: DictionaryWord.categotyID.rawValue, el: inputCatTreeOneLevel))
        formPutStackView.addArrangedSubview(adFormModule)
        
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.adID.rawValue, el: inputAdIDGet))
        addArrangedSubview(submitButtonGet)
        addArrangedSubview(formPutStackView)
    }
    func setConstrains() {
    }
    func addEvents() {
        inputAdIDGet.rx.text
            .orEmpty
            .map{ UInt($0) ?? 0 }
            .bind{
                self.requestedAdID = $0
                self.submitButtonGet.isEnabled = self.requestedAdID > 0
            }
            .disposed(by: disposeBag)
        
        inputCatTreeOneLevel.rx.observe(Int.self, "tag").subscribe { el in
            guard let catTree = self.catTree else {return}
            let catID = UInt(el ?? 0)
            
            if Helper.isLeaf(catTree.childes, catID) > 0 {
                self.serviceCat.getOne(catID, false).subscribe { catFullModel in
                    NotificationCenter.default.post(name: .catsHorizAccorditionCatFull, object: catFullModel)
                    self.adFormModule.adFull = self.adFull
                } onError: { error in
                } onCompleted: {
                }.disposed(by: self.disposeBag)
            }
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)

        submitButtonGet.rx.tap.asDriver().drive(onNext:{
            self.submitButtonGet.isEnabled = false
            self.serviceAds.getOne(self.requestedAdID).subscribe { adFullModel in
                NotificationCenter.default.post(name: .showJSON, object: adFullModel)
                self.adFull = adFullModel
            } onError: { error in
                self.submitButtonGet.isEnabled = true
            } onCompleted: {
                self.submitButtonGet.isEnabled = true
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
