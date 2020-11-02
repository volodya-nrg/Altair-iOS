import UIKit
import RxSwift

@objc protocol AdDelegate {
    func showAdFull(_ adID: UInt)
    @objc optional func goToEdit(_ adID: UInt)
}
enum AdViewOption {
    case line, cube
}

final class AdModule: UICollectionViewCell {
    private var adFull: AdFullModel?
    private var opt: AdViewOption = .cube
    private var inProfile = false
    private var isTemplate = false
    private var disposeBag = DisposeBag()
    
    public weak var delegate: AdDelegate? // слабая ссылка
    
    private let storageStackView: UIStackView = {
        let x = UIStackView()
        x.spacing = 10
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    private let imageView: UIImageView = {
        let x = UIImageView()
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        x.contentMode = .scaleAspectFit
        return x
    }()
    private let title: UILabel = {
        let x = UILabel()
        x.numberOfLines = 2
        x.font = UIFont.boldSystemFont(ofSize: Helper.defaultSizeFont)
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        x.textColor = Helper.myColorToUIColor(.gray2)
        return x
    }()
    private let city: UILabel = {
        let x = MyText.getSmallMuteLabel(" ")
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        return x
    }()
    private let date: UILabel = {
        let x = MyText.getSmallMuteLabel(" ")
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        return x
    }()
    private lazy var editButton: UIButton = {
        let x = ButtonFactory.create(.system, DictionaryWord.edit.rawValue)
        return x
    }()
    private let cityAndDate: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 5
        return x
    }()
    private let statusAndEdit: UIStackView = {
        let x = UIStackView()
        x.distribution = .equalSpacing
        return x
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        imageView.image = nil
        imageView.removeGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:))))
        imageView.isUserInteractionEnabled = false
        title.removeGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleTapped(tapGestureRecognizer:))))
        title.isUserInteractionEnabled = false
        title.textColor = Helper.myColorToUIColor(.gray2)
    }
    public func setup(adFull: AdFullModel, opt: AdViewOption = .cube, inProfile: Bool = false) {
        self.adFull = adFull
        self.opt = opt
        self.inProfile = inProfile
        self.isTemplate = adFull.adID == 0
        
        if isTemplate == false {
            if adFull.images.count > 0 {
                if let url = URL(string: "\(Helper.domain)/api/v1/resample/224/0/\(adFull.images[0].filepath)") {
                    Helper.downloadImage(url) { self.imageView.image = $0 }
                }
            }
            
            if adFull.title != "" {
                title.text = adFull.title
                title.backgroundColor = .clear
            }
            
            if adFull.cityName != "" {
                city.text = adFull.cityName
                city.backgroundColor = .clear
            }
            
            if adFull.createdAt != "" {
                date.text = Helper.getFormattedDate(string: adFull.createdAt)
                date.backgroundColor = .clear
            }
        }
        
        attachElements()
        setConstrains()
        addEvents()
    }
    private func getPrice() -> UILabel {
        var price = "0"
        var currency = DictionaryWord.sum.rawValue
        let x = UILabel()
        
        if !isTemplate {
            if let ad = adFull {
                if ad.price > 0 {
                    price = Helper.priceBeauty(price: ad.price)
                    
                } else {
                    price = DictionaryWord.free.rawValue
                    currency = ""
                }
            }
        }
        
        let attrPrice = MyText.getBoldSmallAttr(price)
        
        if currency != "" {
            attrPrice.append(MyText.getMutedAttr(" \(currency)"))
        }
        
        x.attributedText = attrPrice
        
        return x
    }
    private func getStatus() -> UILabel {
        let x = UILabel()
        var sStatusDesc = "-"
        let tmpStatus = MyText.getSmallMuteAttr(DictionaryWord.statusWithColon.rawValue + " ")

        if let ad = adFull {
            if !ad.isDisabled && !ad.isApproved {
                sStatusDesc = DictionaryWord.inModeration.rawValue

            } else if ad.isDisabled && !ad.isApproved {
                sStatusDesc = DictionaryWord.off.rawValue

            } else if !ad.isDisabled && ad.isApproved {
                sStatusDesc = DictionaryWord.open.rawValue
            }
        }

        let tmpStatusDesc = MyText.getSmallAttr(sStatusDesc)
        tmpStatus.append(tmpStatusDesc)
        x.attributedText = tmpStatus
        return x
    }
}
extension AdModule: DisciplineProtocol {
    internal func attachElements() {
        statusAndEdit.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cityAndDate.arrangedSubviews.forEach { $0.removeFromSuperview() }
        storageStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        subviews.forEach { $0.removeFromSuperview() }
        
        cityAndDate.addArrangedSubview(city)
        cityAndDate.addArrangedSubview(date)
        
        if opt == .line {
            storageStackView.addArrangedSubview(imageView)
            
            let x = UIStackView()
            x.axis = .vertical
            x.spacing = 10

            x.addArrangedSubview(title)
            x.addArrangedSubview(getPrice())
            x.addArrangedSubview(cityAndDate)

            if inProfile {
                statusAndEdit.addArrangedSubview(getStatus())
                statusAndEdit.addArrangedSubview(editButton)
                x.addArrangedSubview(statusAndEdit)
            }

            storageStackView.addArrangedSubview(x)
            
        } else {
            storageStackView.axis = .vertical
            
            storageStackView.addArrangedSubview(imageView)
            storageStackView.addArrangedSubview(title)
            storageStackView.addArrangedSubview(getPrice())
            storageStackView.addArrangedSubview(cityAndDate)
        }
        
        addSubview(storageStackView)
    }
    internal func setConstrains() {
        storageStackView.widthAnchor.constraint(equalTo: super.widthAnchor).isActive = true
        title.heightAnchor.constraint(equalToConstant: 41).isActive = true // так работает корректно в двух вариантах
        
        if opt == .line {
            imageView.widthAnchor.constraint(equalToConstant: 135).isActive = true
            imageView.heightAnchor.constraint(equalTo: super.heightAnchor).isActive = true // относительно родителя выглядит интересней
            
        } else {
            imageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        }
    }
    internal func addEvents() {
        guard !isTemplate else {return}
        guard let ad = adFull else {return}
        
        if !ad.isDisabled && !ad.isApproved {
            // на модерации
        } else if ad.isDisabled && !ad.isApproved {
            // выключен
        } else if !ad.isDisabled && ad.isApproved {
            // открыто
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:))))
            imageView.isUserInteractionEnabled = true
            
            title.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleTapped(tapGestureRecognizer:))))
            title.isUserInteractionEnabled = true
            title.textColor = .systemBlue
        }
        
        if inProfile {
            editButton.rx.tap.asDriver().drive (onNext: {
                guard let x = self.adFull else {return}
                self.delegate?.goToEdit?(x.adID)
            }).disposed(by: disposeBag)
        }
    }
}
extension AdModule {
    @objc private func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        goToAdFull(el: tappedImage)
    }
    @objc private func titleTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedTitle = tapGestureRecognizer.view as! UILabel
        goToAdFull(el: tappedTitle)
    }
    private func goToAdFull(el: AnyObject) {
        guard let x = adFull else {return}
        delegate?.showAdFull(x.adID)
    }
}
