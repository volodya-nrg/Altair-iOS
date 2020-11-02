import UIKit
import RxSwift

protocol FileModuleDelegate: class {
    func fileModuleDidSelect(image: UIImage?)
}

final class FileModule: UIStackView {
    private let disposeBag = DisposeBag()
    private let side: CGFloat = 35
    private let isEditing = false
    private lazy var pickerController: UIImagePickerController = {
        let x = UIImagePickerController()
        x.allowsEditing = isEditing
        x.mediaTypes = ["public.image"]
        x.delegate = self
        return x
    }()
    private var presentationController: UIViewController
    private var _images: [UIImageView] = []
    public var images: [UIImageView] {
        get {
            return _images
        }
        set (ar) {
            _images = ar
            refresh()
        }
    }
    private let btn: UIButton = {
        let x = UIButton(type: .system)
        x.backgroundColor = Helper.myColorToUIColor(.gray7)
        x.setTitle(DictionaryWord.attachPhoto.rawValue, for: .normal)
        x.sizeToFit()
        x.widthAnchor.constraint(equalToConstant: x.frame.width + 20).isActive = true
        return x
    }()
    private let imagesStackView: UIStackView = {
        let x = UIStackView()
        x.spacing = 5
        x.semanticContentAttribute = .forceRightToLeft
        return x
    }()
    
    public weak var delegate: FileModuleDelegate? // слабая ссылка
    
    init(presentationController: UIViewController, limit: UInt, imagesSrc: [UIImageView] = []) {
        self.presentationController = presentationController
        
        super.init(frame: .zero)
        
        spacing = 10
        backgroundColor = Helper.myColorToUIColor(.gray8)
        layer.cornerRadius = 4
        heightAnchor.constraint(equalToConstant: side).isActive = true
        
        attachElements()
        setConstrains()
        addEvents()
        
        if imagesSrc.count > 0 {
            var listImageView: [UIImageView] = []
            imagesSrc.forEach {
                if let x = $0.image {
                    listImageView.append(getTrueImageView(image: x))
                }
            }
            images = listImageView
        
        } else {
            refresh()
        }
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func refresh(){
        imagesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        imagesStackView.addArrangedSubview(UIView())
        images.forEach { imagesStackView.addArrangedSubview($0) }
    }
    private func myPickerController(_ picker: UIImagePickerController, didSelect image: UIImage?) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let x = image else {
            reset()
            delegate?.fileModuleDidSelect(image: nil)
            return
        }
        
        let imageView = getTrueImageView(image: x)
        images = [imageView] // пока только один. images.append(y)
        delegate?.fileModuleDidSelect(image: x)
    }
    public func reset() {
        images = []
    }
    private func getTrueImageView(image: UIImage) -> UIImageView {
        let x = UIImageView()
        x.backgroundColor = Helper.myColorToUIColor(.gray7)
        x.contentMode = .scaleAspectFit
        x.image = image
        x.widthAnchor.constraint(equalToConstant: side).isActive = true
        x.heightAnchor.constraint(equalToConstant: side).isActive = true
        return x
    }
}
extension FileModule: DisciplineProtocol {
    internal func attachElements() {
        addArrangedSubview(btn)
        addArrangedSubview(imagesStackView)
    }
    internal func setConstrains() {
    }
    internal func addEvents() {
        btn.rx.tap.asDriver().drive(onNext:{
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if let action = self.myAction(for: .camera, title: DictionaryWord.takePhoto.rawValue) {
                alertController.addAction(action)
            }
            if let action = self.myAction(for: .savedPhotosAlbum, title: DictionaryWord.cameraRoll.rawValue) {
                alertController.addAction(action)
            }
            if let action = self.myAction(for: .photoLibrary, title: DictionaryWord.photoLibrary.rawValue) {
                alertController.addAction(action)
            }
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertController.popoverPresentationController?.sourceView = self.btn
                alertController.popoverPresentationController?.sourceRect = self.btn.bounds
                alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
            }
            
            alertController.addAction(UIAlertAction(title: DictionaryWord.cancel.rawValue, style: .cancel, handler: nil))
            alertController.pruneNegativeWidthConstraints() // затык от бага
            self.presentationController.present(alertController, animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
}
extension FileModule {
    private func myAction(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {return nil}
        
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController.present(self.pickerController, animated: true, completion: nil)
        }
    }
}
extension FileModule: UIImagePickerControllerDelegate {
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        myPickerController(picker, didSelect: nil)
    }
    internal func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[isEditing ? .editedImage : .originalImage] as? UIImage else {
            return self.myPickerController(picker, didSelect: nil)
        }

        myPickerController(picker, didSelect: image)
    }
}
extension FileModule: UINavigationControllerDelegate {
}
