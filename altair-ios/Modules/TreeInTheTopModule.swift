import UIKit
import RxSwift

final class TreeInTheTopModule: UIStackView {
    private let disposeBag = DisposeBag()
    private let level: Int
    
    init(cats: CatTreeModel, level: Int) {
        self.level = level
        
        super.init(frame: .zero)
        
        backgroundColor = Helper.myColorToUIColor(.gray7)
        axis = .vertical
        spacing = 1
        tag = level // по этому уровню отсчитывается что удалять/взаимозаменять
        
        for v in cats.childes {
            let b = ButtonFactory.create(.system, v.name)
            
            b.tag = Int(v.catID)
            b.backgroundColor = Helper.myColorToUIColor(.gray8)
            b.contentHorizontalAlignment = .left
            b.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            b.semanticContentAttribute = .forceRightToLeft
            
            b.rx.tap.asDriver().drive(onNext:{
                let x = ForTopCatTreeModel(catID: UInt(b.tag),
                                           topA: b.topAnchor,
                                           leftA: b.trailingAnchor,
                                           level: level)
                NotificationCenter.default.post(name: .didTapOnTopCatTree, object: x)
            }).disposed(by: disposeBag)
            
            if v.childes.count > 0 {
                b.setTitleColor(.darkGray, for: .normal)
                b.setImage(UIImage(systemName: "chevron.right"), for: .normal)
                b.imageView?.contentMode = .scaleAspectFit
                b.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            }
            
            addArrangedSubview(b)
        }
        
        addShadow()
        addBorder()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func addShadow() {
        layer.shadowColor = Helper.myColorToUIColor(.gray3).cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 3, height: 5)
        layer.shadowRadius = 5
    }
    private func addBorder() {
        let border = UIView()
        border.backgroundColor = Helper.myColorToUIColor(.gray7)
        border.frame = CGRect(x: 0, y: 0, width: 1, height: frame.size.height)
        border.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        addSubview(border)
    }
}
