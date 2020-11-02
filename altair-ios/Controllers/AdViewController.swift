import UIKit
import WebKit
import RxSwift

final class AdViewController: BaseViewController {
    private let servicePhone = PhoneService()
    private let servicePages = PagesService()
    private let disposeBag = DisposeBag()
    private let adID: UInt
    private var adFull: AdFullModel?
    private var catFull: CatFullModel?
    private var dopImages: [ImageModel] = []
    private let cellID = "AdViewControllerCellID"
    
    private lazy var breadcrumbs: BreadcrumbsModule = {
        let x = BreadcrumbsModule()
        x.delegate = self
        return x
    }()
    private let titleAdLabel: UILabel = {
        let x = UILabel()
        x.numberOfLines = 0
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        return x
    }()
    private let imageView: UIImageView = {
        let x = UIImageView()
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        x.contentMode = .scaleAspectFit
        x.isUserInteractionEnabled = true
        x.translatesAutoresizingMaskIntoConstraints = false // надо
        x.heightAnchor.constraint(equalToConstant: 320).isActive = true
        return x
    }()
    private lazy var smallImagesCollectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.scrollDirection = .horizontal
        
        let x = UICollectionView(frame: .zero, collectionViewLayout: layout)
        x.backgroundColor = .none // необходим, иначе черный цвет
        x.translatesAutoresizingMaskIntoConstraints = false // надо
        x.heightAnchor.constraint(equalToConstant: 50).isActive = true
        x.delegate = self
        x.dataSource = self
        x.register(SmallImageModule.self, forCellWithReuseIdentifier: cellID)
        
        return x
    }()
    private let propsStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        return x
    }()
    private let priceLabel = UILabel()
    private let showPhoneButtton: UIButton = {
        let x = ButtonFactory.create(.custom, DictionaryWord.showPhone.rawValue)
        x.isEnabled = false
        return x
    }()
    private let phoneLabel = UILabel()
    private let titleDescLabel = UILabel()
    private let descriptionTextView: UITextView = {
        let x = UITextView()
        x.isEditable = false
        x.isSelectable = false
        x.isScrollEnabled = false
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        return x
    }()
    private let titleVideoLabel = UILabel()
    private let youtubeWebView: WKWebView = {
        let x = WKWebView()
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        x.translatesAutoresizingMaskIntoConstraints = false
        x.heightAnchor.constraint(equalToConstant: 200).isActive = true
        return x
    }()
    private let dateLabel: UILabel = {
        let x = UILabel()
        x.textAlignment = .right
        return x
    }()
    private let tellLabel: UILabel = {
        let x = MyText.getSmallMuteLabel(DictionaryWord.tellMeYouFoundThisAdOnAltairUz.rawValue)
        x.isHidden = true
        x.textAlignment = .right
        return x
    }()
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let x = UITapGestureRecognizer(target: self,
                                       action: #selector(imageMainTapped(tapGestureRecognizer:)))
        return x
    }()
    
    init (_ adIDSrc: UInt) {
        adID = adIDSrc
        super.init(nibName: nil, bundle: nil) // именно так
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attachElements()
        setConstrains()
        addEvents()
        render()
        
        servicePages.pageAd(adID).subscribe { x in
            self.adFull = x.adFull
            self.catFull = x.catFull
            self.render()
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
    private func render(){
        let isHasAdFull = adFull != nil
        
        boxStackView.subviews.forEach{ $0.removeFromSuperview() }

        // хлебные крошки
        Helper.settings$.subscribe { settingsModel in
            self.boxStackView.addArrangedSubview(self.breadcrumbs)
            if let ad = self.adFull {
                self.breadcrumbs.catModels = Helper.getAncestors(settingsModel.catsTree.childes, ad.catID)
            }
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
        
        // заголовок объявления
        titleAdLabel.attributedText = MyText.getH1Attr(adFull?.title ?? " ")
        boxStackView.addArrangedSubview(titleAdLabel)
        
        if isHasAdFull {
            titleAdLabel.backgroundColor = .clear
        }
        
        // фотографии
        boxStackView.addArrangedSubview(imageView)
        
        if let ad = adFull {
            if ad.images.count > 0 {
                if let url = URL(string: "\(Helper.domain)/api/v1/resample/0/320/\(ad.images[0].filepath)") {
                    Helper.downloadImage(url) { self.imageView.image = $0 }
                }
                
                imageView.removeGestureRecognizer(tapGestureRecognizer)
                imageView.addGestureRecognizer(tapGestureRecognizer)
                
                if ad.images.count > 1 {
                    for (k, v) in ad.images.enumerated() {
                        if k < 1 {
                            continue
                        }
                        dopImages.append(v)
                    }
                    
                    smallImagesCollectionView.reloadData()
                    
                    if dopImages.count > 0 {
                        boxStackView.addArrangedSubview(smallImagesCollectionView)
                    }
                }
            
            } else {
                imageView.removeFromSuperview()
            }
        }
        
        // доп-ые св-ва
        if let ad = adFull {
            if ad.detailsExt.count > 0 {
                for detailExt in ad.detailsExt {
                    if detailExt.kindPropName != "photo" {
                        let finalProp = NSMutableAttributedString()
                        
                        if let catFull = catFull {
                            for prop in catFull.props {
                                if prop.propID == detailExt.propID {
                                    finalProp.append(MyText.getMutedAttr("\(prop.title): "))
                                }
                            }
                        }
                        
                        let tmpValue = (detailExt.valueName != "" ? detailExt.valueName : detailExt.value)
                        finalProp.append(NSMutableAttributedString(string: tmpValue))
                        
                        let proplabel = UILabel()
                        proplabel.numberOfLines = 0
                        proplabel.attributedText = finalProp
                        
                        propsStackView.addArrangedSubview(proplabel)
                    }
                }
                
                boxStackView.addArrangedSubview(propsStackView)
            }
        }
        
        let tmpHorizStackView = UIStackView()
        tmpHorizStackView.distribution = .equalSpacing
        
        // цена
        let sPrice = Helper.priceBeauty(price: adFull?.price ?? 0)
        let finalPrice = MyText.getMutedAttr("\(DictionaryWord.priceWithColon.rawValue) ")
        finalPrice.append(MyText.getH2Attr(sPrice))
        finalPrice.append(MyText.getMutedAttr(" \(DictionaryWord.sum.rawValue)"))
        priceLabel.attributedText = finalPrice
        
        tmpHorizStackView.addArrangedSubview(priceLabel)
        tmpHorizStackView.addArrangedSubview(phoneLabel)
        tmpHorizStackView.addArrangedSubview(showPhoneButtton)
        
        if isHasAdFull {
            showPhoneButtton.isEnabled = true
        }
        
        boxStackView.addArrangedSubview(tmpHorizStackView)
        boxStackView.addArrangedSubview(tellLabel)
        
        // заголовок описания
        titleDescLabel.attributedText = MyText.getH2Attr(DictionaryWord.description.rawValue)
        boxStackView.addArrangedSubview(titleDescLabel)
        
        // описание
        descriptionTextView.attributedText = MyText.getDefaultSizeAttr(adFull?.description ?? "")
        boxStackView.addArrangedSubview(descriptionTextView)
        
        if isHasAdFull {
            descriptionTextView.backgroundColor = .none
        }
        
        // заголовок для видео
        titleVideoLabel.attributedText = MyText.getH2Attr(DictionaryWord.video.rawValue)
        boxStackView.addArrangedSubview(titleVideoLabel)
        
        // видео
        boxStackView.addArrangedSubview(youtubeWebView)
        if let ad = adFull {
            var isRemoveVideo = true
            
            if ad.youtube != "" {
                if let sUrl = URL(string: "\(Helper.youTubeEmbed)\(ad.youtube)")  {
                    youtubeWebView.load(URLRequest(url: sUrl))
                    isRemoveVideo = false
                }
            }
            
            if isRemoveVideo {
                titleVideoLabel.removeFromSuperview()
                youtubeWebView.removeFromSuperview()
            }
        }
        
        // дата создания/изменения
        let finalDate = NSMutableAttributedString()
        finalDate.append(MyText.getSmallMuteAttr(DictionaryWord.createdAtWithColon.rawValue + " "))
        finalDate.append(MyText.getSmallAttr(Helper.getFormattedDate(string: adFull?.createdAt ?? "")))
        finalDate.append(MyText.getSmallMuteAttr(" / \(DictionaryWord.updateAtWithColon.rawValue) "))
        finalDate.append(MyText.getSmallAttr(Helper.getFormattedDate(string: adFull?.updatedAt ?? "")))
        dateLabel.attributedText = finalDate
        
        boxStackView.addArrangedSubview(dateLabel)
    }
}
extension AdViewController: DisciplineProtocol {
    func attachElements() {
    }
    func setConstrains() {
    }
    func addEvents() {
        showPhoneButtton.rx.tap.asDriver().drive(onNext: {
            guard let ad = self.adFull else {return}
            self.showPhoneButtton.isEnabled = false
            self.servicePhone.getByID(phoneID: ad.phoneID).subscribe { phoneModel in
                self.showPhoneButtton.isEnabled = true
                self.showPhoneButtton.isHidden = true
                self.phoneLabel.attributedText = MyText.getH1Attr(phoneModel.number)
                self.tellLabel.isHidden = false
            } onError: { error in
                self.showPhoneButtton.isEnabled = true
            } onCompleted: {
            }.disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
}
extension AdViewController {
    @objc func imageMainTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let ad = adFull else {return}
        let x = PhotoGalleryViewController()
        x.items = ad.images
        x.startIndex = 0
        navigationController?.pushViewController(x, animated: true)
    }
}
extension AdViewController: BreadcrumbsModuleDelegate {
    func didTapBreadcrumbItem(_ sender: UIButton) {
        let x = CatViewController()
        x.catID = UInt(sender.tag)
        navigationController?.pushViewController(x, animated: true)
    }
}
extension AdViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dopImages.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! SmallImageModule
        let index = indexPath.item
        cell.setup(dopImages[index].filepath)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let ad = adFull else {return}
        let x = PhotoGalleryViewController()
        x.items = ad.images
        x.startIndex = indexPath.row + 1
        navigationController?.pushViewController(x, animated: true)
    }
}
