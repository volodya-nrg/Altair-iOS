import UIKit
import RxSwift

protocol BreadcrumbsModuleDelegate: class {
    func didTapBreadcrumbItem(_ sender: UIButton)
}

final class BreadcrumbsModule: UIView {
    private let disposeBag = DisposeBag()
    private let reservedWidth: CGFloat = UIScreen.main.bounds.width - (Helper.globalMarginSide * 2)
    private var isDisabledLastItem = false
    private var _catModels: [CatModel] = []
    public var catModels: [CatModel] {
        get {
            return _catModels
        }
        set (xItems) {
            let x = CatModel()
            x.name = DictionaryWord.catalog.rawValue
            
            _catModels = xItems
            _catModels.insert(x, at: 0)
            refresh()
        }
    }
    
    public weak var delegate: BreadcrumbsModuleDelegate?
    
    init() {
        super.init(frame: .zero)
        
        let x = CatModel()
        _catModels = [x, x, x]
        refresh()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func refresh() {
        let parentWidth: CGFloat = super.frame.width < 1 ? reservedWidth : super.frame.width
        var offsetTop: CGFloat = 0
        var offsetLeft: CGFloat = 0
        var lastBtn: UIButton?
        
        subviews.forEach{ $0.removeFromSuperview() }
        
        _catModels.forEach{ el in
            let btn = ButtonFactory.create(.system, el.name)
            lastBtn = btn
            
            if el.name == "" {
                btn.isEnabled = false
                btn.backgroundColor = Helper.myColorToUIColor(.gray8)
                btn.setTitleColor(btn.backgroundColor, for: .normal)
                btn.setTitle("__________", for: .normal)
            }
            
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.tag = Int(el.catID)
            btn.sizeToFit()
            
            addSubview(btn)
            
            let isWidthOver = (offsetLeft + btn.frame.width) > parentWidth
            
            if isWidthOver {
                offsetTop += btn.frame.height
                offsetLeft = 0
            }
            
            btn.topAnchor.constraint(equalTo: topAnchor, constant: offsetTop).isActive = true
            btn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: offsetLeft).isActive = true
            
            btn.rx.tap.asDriver().drive(onNext:{
                self.delegate?.didTapBreadcrumbItem(btn)
            }).disposed(by: self.disposeBag)
            
            offsetLeft += btn.frame.width + Helper.em1
        }
        
        if let x = lastBtn {
            bottomAnchor.constraint(equalTo: x.bottomAnchor).isActive = true
        }
    }
}
