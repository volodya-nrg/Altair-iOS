import UIKit
import RxSwift

final class AccordionModule: UIStackView {
    private let disposeBag = DisposeBag()
    
    private let headerButton: UIButton = {
        let x = UIButton(type: .system)
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        x.contentHorizontalAlignment = .left
        x.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return x
    }()
    private let contentStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 5
        x.translatesAutoresizingMaskIntoConstraints = false
        x.layoutMargins = UIEdgeInsets(top: 0, left: Helper.globalMarginSide, bottom: 0, right: 0)
        x.isLayoutMarginsRelativeArrangement = true
        x.isHidden = true
        return x
    }()
    
    init(title: String, items: [UIView], level: UInt = 0) {
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 5
        
        headerButton.setTitle(title, for: .normal)
        
        if level == 0 {
            headerButton.backgroundColor = Helper.myColorToUIColor(.gray8)
        }
        
        items.forEach { contentStackView.addArrangedSubview($0) }
        
        attachElements()
        setConstrains()
        addEvents()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension AccordionModule: DisciplineProtocol {
    func attachElements() {
        addArrangedSubview(headerButton)
        addArrangedSubview(contentStackView)
    }
    func setConstrains() {
    }
    func addEvents() {
        headerButton.rx.tap.asDriver().drive(onNext:{
            self.contentStackView.isHidden = !self.contentStackView.isHidden
        }).disposed(by: disposeBag)
    }
}
