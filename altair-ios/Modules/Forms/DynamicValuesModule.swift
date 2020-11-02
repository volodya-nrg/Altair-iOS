import UIKit
import RxSwift

protocol DynamicValuesModuleDelegate: class {
    func onChangeDynamicValues(_ items: [ValuePropModel])
}

final class DynamicValuesModule: UIStackView {
    private let cellID = "DynamicValuesModuleCellID"
    private var propID: UInt = 0
    private var items: [ValuePropModel] = [] {
        didSet {
            // уведомляем об изменении. Рендер сюда не ставить, т.к. происходит зацикливание
            self.delegate?.onChangeDynamicValues(self.items)
        }
    }
    private let disposeBag = DisposeBag()
    
    private let dataStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 5
        return x
    }()
    private let addButton: UIButton = {
        let x = UIButton(type: .system)
        x.setImage(UIImage(systemName: "plus"), for: .normal)
        return x
    }()
    
    public weak var delegate: DynamicValuesModuleDelegate?
    
    init () {
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 10
        
        addArrangedSubview(addButton)
        addArrangedSubview(dataStackView)
        
        addButton.rx.tap.asDriver().drive(onNext: { el in
            var row = ValuePropModel()
            row.pos = UInt(self.items.count + 1)
            row.propID = self.propID
            self.items.append(row)
            self.render()
        }).disposed(by: disposeBag)
        
        render()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func render() {
        dataStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        items.enumerated().forEach { (i, el) in
            dataStackView.addArrangedSubview(generateRow(el, i))
        }
    }
    private func generateRow(_ data: ValuePropModel, _ index: Int) -> UIStackView {
        let x = UIStackView()
        let inputValue = TextFieldFactory.create(.roundedRect, DictionaryWord.name.rawValue)
        let inputPos = TextFieldFactory.create()
        let minusBtn = UIButton(type: .system)
        
        inputValue.text = data.title
        inputValue.tag = index
        inputValue.autocapitalizationType = .none
        inputValue.rx.text
            .orEmpty
            .filter{ _ in self.items.indices.contains(index)}
            .bind {self.items[index].title = $0}
            .disposed(by: disposeBag)
        
        inputPos.text = String(data.pos)
        inputPos.widthAnchor.constraint(equalToConstant: 40).isActive = true
        inputPos.textAlignment = .center
        inputPos.delegate = self
        inputPos.rx.text
            .orEmpty
            .filter{ _ in self.items.indices.contains(index)}
            .bind {
                if let x = UInt($0) {
                    self.items[index].pos = x
                } else {
                    self.items[index].pos = 1
                }
            }.disposed(by: disposeBag)
        
        minusBtn.setImage(UIImage(systemName: "minus"), for: .normal)
        minusBtn.backgroundColor = .systemGroupedBackground
        minusBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        x.spacing = 5
        x.addArrangedSubview(inputValue)
        x.addArrangedSubview(inputPos)
        x.addArrangedSubview(minusBtn)
        
        minusBtn.rx.tap.asDriver().drive(onNext: { el in
            guard self.items.indices.contains(index) else {return}
            self.items.remove(at: index)
            self.render()
        }).disposed(by: disposeBag)
        
        return x
    }
    public func reset() {
        propID = 0
        items.removeAll()
        render()
    }
    public func setItems(_ propID: UInt, _ items: [ValuePropModel]) {
        self.propID = propID
        self.items = items
        render()
    }
}
extension DynamicValuesModule: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        let isAllow = allowedCharacters.isSuperset(of: characterSet)
        return isAllow
    }
}
