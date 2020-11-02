import UIKit
import RxSwift

class FormBaseModule: UIStackView {
    private let disposeBag = DisposeBag()
    internal var catTreeOneLevel: [CatWithDeepModel] = []
    internal var catTree: CatTreeModel?
    internal var kindProps: [KindPropModel] = []
    internal var props: [PropModel] = []
    internal let inputCatTreeOneLevel = TextFieldFactory.create()
    internal let inputKindTag = TextFieldFactory.create()
    internal let inputProps = TextFieldFactory.create()
    internal let debugTextView: UITextView = {
        let x = UITextView()
        x.isSelectable = false
        x.isScrollEnabled = false
        return x
    }()
    
    internal lazy var catTreePickerView: UIPickerView = {
        let x = UIPickerView()
        x.delegate = self
        x.tag = 1
        return x
    }()
    internal lazy var kindTagPickerView: UIPickerView = {
        let x = UIPickerView()
        x.delegate = self
        x.tag = 2
        return x
    }()
    internal lazy var propsPickerView: UIPickerView = {
        let x = UIPickerView()
        x.delegate = self
        x.tag = 3
        return x
    }()
    
    internal lazy var toolbar: UIToolbar = {
        let doneButton = UIBarButtonItem(title: DictionaryWord.hidden.rawValue, style: .plain, target: self, action: #selector(closePanel))
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 35)) // затык от бага
        
        toolBar.sizeToFit()
        toolBar.setItems([doneButton], animated: true)
        toolBar.isUserInteractionEnabled = true
        
        return toolBar
    }()
    
    init() {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 10
        
        inputCatTreeOneLevel.inputView = catTreePickerView
        inputCatTreeOneLevel.inputAccessoryView = toolbar
        
        inputKindTag.inputView = kindTagPickerView
        inputKindTag.inputAccessoryView = toolbar
        
        inputProps.inputView = propsPickerView
        inputProps.inputAccessoryView = toolbar
        
        Helper.settings$.subscribe { settingsModel in
            self.catTreeOneLevel.removeAll()
            self.catTreeOneLevel.append(CatWithDeepModel())
            self.catTreeOneLevel.append(contentsOf: Helper.getCatTreeAsOneLevel(settingsModel.catsTree.childes))
            
            self.catTree = settingsModel.catsTree
            
            self.kindProps = settingsModel.kindProps
            self.kindProps.insert(KindPropModel(), at: 0) // нужен еще один, т.к. не у всех эл-ов есть доп. опции
            
            self.props = settingsModel.props
            self.props.insert(PropModel(), at: 0) // нужен еще один, т.к. не у всех эл-ов есть доп. опции
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension FormBaseModule: UITextFieldDelegate {
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        let isAllow = allowedCharacters.isSuperset(of: characterSet)
        return isAllow
    }
}
extension FormBaseModule {
    @objc private func closePanel() {
        endEditing(true)
    }
}
extension FormBaseModule: UIPickerViewDelegate, UIPickerViewDataSource {
    internal func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    internal func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var res = 0
        
        if pickerView.tag == 1 {
            res = catTreeOneLevel.count
            
        } else if pickerView.tag == 2 {
            res = kindProps.count
        
        } else if pickerView.tag == 3 {
            res = props.count
        }
        
        return res
    }
    internal func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            let el = catTreeOneLevel[row]
            inputCatTreeOneLevel.tag = Int(el.catID)
            inputCatTreeOneLevel.text = el.name
            
        } else if pickerView.tag == 2 {
            let el = kindProps[row]
            inputKindTag.tag = Int(el.kindPropID)
            inputKindTag.text = el.name
        
        } else if pickerView.tag == 3 {
            let el = props[row]
            var x = el.title
            
            if el.privateComment != "" {
                x += " (\(el.privateComment))"
            }
            
            inputProps.tag = Int(el.propID)
            inputProps.text = x
        }
    }
    internal func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var result = ""
        var attrCurrency = NSAttributedString()
        
        if pickerView.tag == 1 {
            let el = catTreeOneLevel[row]
            let prefix = String(repeating: "|--", count: Int(el.deep))
            result = "\(prefix)\(el.name)"
            
            let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.left
            
            let x: [NSAttributedString.Key: Any] = [.paragraphStyle : paragraphStyle]
            attrCurrency = NSAttributedString(string: result, attributes: x)
            
        } else if pickerView.tag == 2 {
            attrCurrency = NSAttributedString(string: kindProps[row].name)
        
        } else if pickerView.tag == 3 {
            let el = props[row]
            var x = el.title
            
            if el.privateComment != "" {
                x += " (\(el.privateComment))"
            }
            
            attrCurrency = NSAttributedString(string: x)
        }
        
        return attrCurrency
    }
}
