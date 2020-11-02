import UIKit
import RxSwift

protocol RadioGroupModuleDelegate {
    func radioGroupModuleOnChange (module: RadioGroupModule, val: UInt)
}

final class RadioGroupModule: UIStackView {
    private let disposeBag = DisposeBag()
    private let side: CGFloat = 35
    private let bgButtonNormal: UIColor = Helper.myColorToUIColor(.gray8)
    private let bgButtonSelected: UIColor = Helper.myColorToUIColor(.gray2)
    private let colorTitleNormal: UIColor = Helper.myColorToUIColor(.gray2)
    private let colorTitleSelected: UIColor = Helper.myColorToUIColor(.gray8)
    private let listStackView: UIStackView = {
        let x = UIStackView()
        x.semanticContentAttribute = .forceLeftToRight
        return x
    }()
    
    public var delegate: RadioGroupModuleDelegate?
    
    init(_ items: [RadioItemModule]) {
        super.init(frame: .zero)
        semanticContentAttribute = .forceRightToLeft
        items.forEach { listStackView.addArrangedSubview(getBtn($0)) }
        addArrangedSubview(UIView())
        addArrangedSubview(listStackView)
        heightAnchor.constraint(equalToConstant: side).isActive = true
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func getBtn(_ v: RadioItemModule) -> UIButton {
        let x = UIButton(type: .custom)
        
        x.setTitle(v.getName(), for: .normal)
        x.tag = Int(v.getValue())
        x.isSelected = v.isChosen()
        x.setTitleColor(colorTitleNormal, for: .normal)
        x.backgroundColor = bgButtonNormal
        x.layer.cornerRadius = 3
        x.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        
        x.translatesAutoresizingMaskIntoConstraints = false
        x.rx.tap.asDriver().drive(onNext:{
            guard x.isSelected == false else {return}
            
            self.listStackView.arrangedSubviews.forEach { el in
                let x = el as! UIButton
                x.isSelected = false
                x.backgroundColor = self.bgButtonNormal
                x.setTitleColor(self.colorTitleNormal, for: .normal)
            }
            
            x.isSelected = true
            x.backgroundColor = self.bgButtonSelected
            x.setTitleColor(self.colorTitleSelected, for: .normal)
            
            self.delegate?.radioGroupModuleOnChange(module: self, val: UInt(x.tag))
        }).disposed(by: disposeBag)
        
        if x.isSelected {
            x.backgroundColor = bgButtonSelected
            x.setTitleColor(colorTitleSelected, for: .normal)
        }
        
        return x
    }
}
final class RadioItemModule {
    private var _name: String
    private var _value: UInt
    private var _isSelected: Bool
    
    init(name: String, value: UInt, isSelected: Bool = false) {
        _name = name
        _value = value
        _isSelected = isSelected
    }
    public func getName() -> String {
        return _name
    }
    public func getValue() -> UInt {
        return _value
    }
    public func isChosen() -> Bool {
        return _isSelected
    }
}
