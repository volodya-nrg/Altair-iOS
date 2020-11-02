import UIKit
import RxSwift

final class CatsHorizAccordionModule: UIStackView {
    private let serviceCat = CatService()
    private var _catTree: CatTreeModel?
    private var _catID: UInt = 0
    private let disposeBag = DisposeBag()
    
    public var catID: UInt {
        get {
            return _catID
        }
        set (value) {
            _catID = value
            guard let x = _catTree else {return}
            let catModels = Helper.getAncestors(x.childes, _catID)
           
            for (i, c) in catModels.enumerated() {
                if i == 0 {
                    pasteLevel(levelSrc: i, listSrc: x.childes, catIDSrc: c.catID)
                    
                } else if let node = Helper.getDescendantsNode(listCatTree: x.childes, findCatID: c.parentID) {
                    pasteLevel(levelSrc: i, listSrc: node.childes, catIDSrc: c.catID)
                }
            }
            
            getCatFull(_catID){
                // complete
            }
        }
    }
    
    init(){
        super.init(frame: .zero)
        
        axis = .vertical
        backgroundColor = Helper.myColorToUIColor(.gray7)
        spacing = 10
        // alignment = .leading
        
        Helper.settings$.subscribe { settingsModel in
            self._catTree = settingsModel.catsTree
            self.pasteLevel(levelSrc: 0, listSrc: settingsModel.catsTree.childes, catIDSrc: self._catID)
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func pasteLevel(levelSrc: Int, listSrc: [CatTreeModel], catIDSrc: UInt) {
        // узнать какой уровень, почистить данный уровень и все последующие
        arrangedSubviews.enumerated().forEach { (k, v)  in
            if k >= levelSrc {
                v.removeFromSuperview()
            }
        }
        
        guard listSrc.count > 0 else {return}
        
        let levelStackView = createNewRow()
        
        for v in listSrc {
            let b = ButtonFactory.create(.system, v.name)
            b.tag = Int(v.catID)
            b.backgroundColor = Helper.myColorToUIColor(.gray8)
            b.contentHorizontalAlignment = .left
            b.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            b.semanticContentAttribute = .forceRightToLeft
            
            b.rx.tap.asDriver().drive(onNext: {
                guard let catTree = self._catTree else {return}
                
                let catID = UInt(b.tag)
                let chain = Helper.getAncestors(catTree.childes, catID)
                let level = chain.count
                
                // с текущего уровня отжать кнопки
                self.arrangedSubviews.enumerated().forEach({ (k, v) in
                    if k == level - 1 {
                        (v as! UIStackView).arrangedSubviews.forEach { ($0 as! UIButton).isSelected = false }
                    }
                })
                
                b.isSelected = true
                
                if let node = Helper.getDescendantsNode(listCatTree: catTree.childes, findCatID: catID) {
                    self.pasteLevel(levelSrc: level, listSrc: node.childes, catIDSrc: catID)
                }
                
                if Helper.isLeaf(catTree.childes, catID) > 0 {
                    b.isEnabled = false
                    self.getCatFull(catID) {
                        b.isEnabled = true
                    }
                }
            }).disposed(by: disposeBag)
            
            if v.childes.count > 0 {
                b.setTitleColor(.darkGray, for: .normal)
                b.setImage(UIImage(systemName: "chevron.down"), for: .normal)
                b.imageView?.contentMode = .scaleAspectFit
                b.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            }
            
            if v.catID == catIDSrc {
                b.isSelected = true
            }
            
            levelStackView.addArrangedSubview(b)
        }
        
        addArrangedSubview(levelStackView)
    }
    private func createNewRow() -> UIStackView {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 1
        return x
    }
    private func getCatFull(_ catID: UInt, finished: @escaping () -> Void) {
        serviceCat.getOne(catID, false).subscribe { catFullModel in
            NotificationCenter.default.post(name: .catsHorizAccorditionCatFull, object: catFullModel)
            finished()
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
}
