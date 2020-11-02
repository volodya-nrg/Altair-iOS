import UIKit
import RxSwift

final class FormCatsGetCatsModule: FormBaseModule {
    private let serviceCats = CatService()
    private let disposeBag = DisposeBag()
    private let submitButton = ButtonFactory.create(.custom, DictionaryWord.send.rawValue)
    private let switchAsTree = UISwitch()
    
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
extension FormCatsGetCatsModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(Helper.generateRow(title: DictionaryWord.asTree.rawValue, el: switchAsTree))
        addArrangedSubview(submitButton)
    }
    func setConstrains() {
    }
    func addEvents() {
        submitButton.rx.tap.asDriver().drive(onNext:{
            self.submitButton.isEnabled = false
            
            if self.switchAsTree.isOn {
                self.serviceCats.getTree().subscribe { catTreeModel in
                    NotificationCenter.default.post(name: .showJSON, object: catTreeModel)
                } onError: { error in
                    self.submitButton.isEnabled = true
                } onCompleted: {
                    self.submitButton.isEnabled = true
                }.disposed(by: self.disposeBag)
                
            } else {
                self.serviceCats.getList().subscribe { catModels in
                    NotificationCenter.default.post(name: .showJSON, object: catModels)
                } onError: { error in
                    self.submitButton.isEnabled = true
                } onCompleted: {
                    self.submitButton.isEnabled = true
                }.disposed(by: self.disposeBag)
            }
            
        }).disposed(by: disposeBag)
    }
}
