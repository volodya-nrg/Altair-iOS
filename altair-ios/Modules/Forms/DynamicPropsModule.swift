import UIKit
import RxSwift

protocol DynamicPropsModuleDelegate: class {
    func onChangeDynamicProps(_ items: [PropAssignedForCatModel])
}

final class DynamicPropsModule: UIStackView {
    private let cellID = "DynamicPropsModuleCellID"
    private var items: [PropAssignedForCatModel] = [] {
        didSet {
            // уведомляем об изменении. Рендер сюда не ставить, т.к. происходит зацикливание
            self.delegate?.onChangeDynamicProps(self.items)
        }
    }
    private let disposeBag = DisposeBag()
    private let headerStackView: UIStackView = {
        let x = UIStackView()
        x.spacing = 5
        return x
    }()
    private let dataStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 10
        return x
    }()
    private let addButton: UIButton = {
        let x = UIButton(type: .system)
        x.setImage(UIImage(systemName: "plus"), for: .normal)
        x.widthAnchor.constraint(equalToConstant: 40).isActive = true
        return x
    }()
    private var inputProps: UITextField
    public weak var delegate: DynamicPropsModuleDelegate?
    
    init (_ inputProps: UITextField) {
        self.inputProps = inputProps
        
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 10
        
        headerStackView.addArrangedSubview(self.inputProps)
        headerStackView.addArrangedSubview(addButton)
        
        addArrangedSubview(headerStackView)
        addArrangedSubview(dataStackView)
        
        addButton.rx.tap.asDriver().drive(onNext: { el in
            let title = self.inputProps.text ?? ""
            if title == "" {
                NotificationCenter.default.post(name: .flyError,
                                                object: FlyErrorModule(kindVisual: .warning,
                                                                       msg: DictionaryWord.propIsEmpty.rawValue))
                return
            }
            
            let propID = UInt(self.inputProps.tag)
            var isHas = false
            
            self.items.forEach { item in
                if item.propID == propID {
                    isHas = true
                }
            }
            
            if isHas {
                let x = FlyErrorModule(kindVisual: .warning, msg: "\(DictionaryWord.propAlreadySelected.rawValue) (\(title))")
                NotificationCenter.default.post(name: .flyError, object: x)
                return
            }
            
            var row = PropAssignedForCatModel(nil)
            row.pos = UInt(self.items.count + 1)
            row.title = title
            row.propID = propID
            
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
    private func generateRow(_ data: PropAssignedForCatModel, _ index: Int) -> UIStackView {
        let mainStackView = UIStackView()
        let aStackView = UIStackView()
        let bStackView = UIStackView()
        let cStackView = UIStackView()
        let inputComment = TextFieldFactory.create(.roundedRect, DictionaryWord.commentWillAppearUnderTheProperty.rawValue)
        let inputPos = TextFieldFactory.create()
        let minusBtn = UIButton(type: .system)
        let switchRequired = UISwitch()
        let switchAsFilter = UISwitch()
        let titleLabel = UILabel()
        let requiredLabel = MyText.getSmallMuteLabel(DictionaryWord.isRequire.rawValue)
        let asFilterLabel = MyText.getSmallMuteLabel(DictionaryWord.asFilterToo.rawValue)
        
        titleLabel.attributedText = MyText.getBoldSmallAttr(data.title)
        
        inputComment.text = data.comment
        inputComment.tag = index
        inputComment.autocapitalizationType = .none
        
        inputPos.text = String(data.pos)
        inputPos.widthAnchor.constraint(equalToConstant: 40).isActive = true
        inputPos.textAlignment = .center
        inputPos.delegate = self
        
        if items.indices.contains(index) {
            switchRequired.isOn = items[index].isRequire
            switchAsFilter.isOn = items[index].isCanAsFilter
        }
        
        minusBtn.setImage(UIImage(systemName: "minus"), for: .normal)
        minusBtn.backgroundColor = Helper.myColorToUIColor(.gray7)
        minusBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        inputComment.rx.text
            .orEmpty
            .filter{ _ in self.items.indices.contains(index)}
            .bind {self.items[index].comment = $0}
            .disposed(by: disposeBag)

        inputPos.rx.text
            .orEmpty
            .filter{ _ in self.items.indices.contains(index)}
            .bind {self.items[index].pos = UInt($0) ?? 1}
            .disposed(by: disposeBag)
        
        switchRequired.rx.value
            .filter{ _ in self.items.indices.contains(index)}
            .bind{self.items[index].isRequire = $0}
            .disposed(by: disposeBag)
        
        switchAsFilter.rx.value
            .filter{ _ in self.items.indices.contains(index)}
            .bind {self.items[index].isCanAsFilter = $0}
            .disposed(by: disposeBag)
        
        minusBtn.rx.tap.asDriver().drive(onNext: { el in
            guard self.items.indices.contains(index) else {return}
            self.items.remove(at: index)
            self.render()
        }).disposed(by: disposeBag)

        mainStackView.spacing = 5
        mainStackView.axis = .vertical
        aStackView.spacing = 5
        bStackView.spacing = 10
        cStackView.spacing = 10
        
        aStackView.addArrangedSubview(inputComment)
        aStackView.addArrangedSubview(inputPos)
        aStackView.addArrangedSubview(minusBtn)
        bStackView.addArrangedSubview(switchRequired)
        bStackView.addArrangedSubview(requiredLabel)
        cStackView.addArrangedSubview(switchAsFilter)
        cStackView.addArrangedSubview(asFilterLabel)
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(aStackView)
        mainStackView.addArrangedSubview(bStackView)
        mainStackView.addArrangedSubview(cStackView)
        
        return mainStackView
    }
    public func reset() {
        items.removeAll()
        render()
    }
    public func setItems(_ items: [PropAssignedForCatModel]) {
        self.items = items
        render()
    }
}
extension DynamicPropsModule: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        let isAllow = allowedCharacters.isSuperset(of: characterSet)
        return isAllow
    }
}
