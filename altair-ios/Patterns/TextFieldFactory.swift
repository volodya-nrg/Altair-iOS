import UIKit

final class TextFieldFactory {
    static func create(_ borderStyleSrc: UITextField.BorderStyle = .roundedRect, _ placeholder: String = "") -> UITextField {
        let el = UITextField()
        
        el.borderStyle = borderStyleSrc
        
        if placeholder != "" {
            el.placeholder = placeholder
        }
        
        return el
    }
}
