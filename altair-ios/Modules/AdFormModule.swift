import UIKit
import RxSwift
import YandexMapKitSearch

private struct SaveValuePropForSelect {
    public var inputField: UITextField
    public var valueProp: ValuePropModel?
}

final class AdFormModule: UIStackView {
    private let serviceAd = AdService()
    private var presentationController: UIViewController
    private var catTree: CatTreeModel?
    private var catFull: CatFullModel? = nil { // выбранный на данный момент каталог-лист
        didSet {
            render()
        }
    }
    private var phones: [PhoneModel] = []
    private var tagSelectMap: [String: [SaveValuePropForSelect]] = [:]
    private var filesAlreadyHas: [UIImageView] = []
    private let miniImgSize: CGFloat = 30
    private let cellID = "AdFormModuleCellID"
    public let fileModule: FileModule
    private var saveControlNameYmaps = "" // переменная для сохранения имени св-ва (Яндекс-карта) для позднего обнаружения
    private var savePropNameForFile = "" // сохраним название св-ва, чтоб удобней можно было обращаться к нему
    private var checkerProps: [(name: String, isRequire: Bool)] = []
    private var isEditThroughAdmin: Bool
    private let debugTextView: UITextView = {
        let x = UITextView()
        x.isSelectable = false
        x.isScrollEnabled = false
        return x
    }()
    
    // map
    private let defaultMapZoom: Float = 10
    private let searchManager = YMKSearch.sharedInstance().createSearchManager(with: .combined)
    private var searchSession: YMKSearchSession?
    // \ map
    
    private let disposeBag = DisposeBag()
    private var formData: [String: Any] = [:] {
        didSet {
            let isCorrectCatID = (formData["catID"] as? UInt ?? 0) > 0
            let isCorrectDescription = (formData["description"] as? String ?? "").count > 0
            let isCorrectPhoneID = (formData["phoneID"] as? UInt ?? 0) > 0
            var isCorrectTitle = false
            var checkTitle = true
            var coof = 0
            
            if let c = catFull {
                c.props.forEach { p in
                    guard p.propIsRequire else {return}
                    let tmpPropID = "p\(p.propID)"
                    coof -= 1
                    
                    if formData.keys.contains(tmpPropID) {
                        let val = formData[tmpPropID]
                        var isValid = false
                        
                        if Helper.tagKindNumber.contains(p.kindPropName) {
                            let val2 = val as? UInt ?? 0
                            isValid = val2 > 0
                            
                        } else  {
                            let val2 = val as? String ?? ""
                            isValid = val2.trim().count > 0
                        }
                        
                        if isValid {
                            coof += 1
                        }
                    }
                }
            }
            
            if let x = catFull, x.isAutogenerateTitle {
                isCorrectTitle = true
                checkTitle = false
            }
            if checkTitle {
                let y = formData["title"] as? String ?? ""
                isCorrectTitle = y.trim().count > 0
            }
            
            sendButton.isEnabled = isCorrectCatID && isCorrectDescription && isCorrectPhoneID && coof == 0 && isCorrectTitle
            
            #if DEBUG
                // debugTextView.text = Helper.mapToString(formData) // тут ломается
            #endif
        }
    }

    public var adFull: AdFullModel? = nil {
        didSet {
            render()
        }
    }

    // elements form
    private let inputTitle = TextFieldFactory.create()
    private let inputSlug: UITextField = {
        let x = TextFieldFactory.create()
        x.isEnabled = false
        return x
    }()
    private lazy var inputUserID: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        return x
    }()
    private let switchIsDisabled = UISwitch()
    private let switchIsApproved = UISwitch()
    private let descriptionTextarea: UITextView = {
        let x = UITextView()
        x.isScrollEnabled = false
        x.layer.borderWidth = 1
        x.layer.borderColor = Helper.myColorToUIColor(.gray7).cgColor
        return x
    }()
    private lazy var inputPrice: UITextField = {
        let x = TextFieldFactory.create()
        x.delegate = self
        return x
    }()
    private let inputYoutube: UITextField = {
        let x = TextFieldFactory.create(.roundedRect, Helper.youTubeExampleLink)
        x.autocapitalizationType = .none
        return x
    }()
    private lazy var inputPhone: UITextField = {
        let pickerView = UIPickerView()
        pickerView.accessibilityValue = "phone"
        pickerView.delegate = self
        
        let x = TextFieldFactory.create()
        x.inputView = pickerView
        x.inputAccessoryView = toolbar
        
        return x
    }()
    private let sendButton = ButtonFactory.create(.custom, DictionaryWord.create.rawValue)
    // \ elements form
    
    // вспомогательные элементы
    private lazy var toolbar: UIToolbar = {
        let doneButton = UIBarButtonItem(title: DictionaryWord.hidden.rawValue, style: .plain, target: self, action: #selector(closePanel))
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 35)) // затык от бага
        
        toolBar.sizeToFit()
        toolBar.setItems([doneButton], animated: true)
        toolBar.isUserInteractionEnabled = true

        return toolBar
    }()
    private lazy var mapView: YMKMapView = {
        let x = YMKMapView()
        x.clearsContextBeforeDrawing = true
        x.heightAnchor.constraint(equalToConstant: 200).isActive = true

        x.mapWindow.map.move(
            with: YMKCameraPosition.init(target: YMKPoint(latitude: Helper.defaultCenterMap[0],
                                                          longitude: Helper.defaultCenterMap[1]),
                                         zoom: defaultMapZoom,
                                         azimuth: 0,
                                         tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 3),
            cameraCallback: nil)
        
        x.mapWindow.map.addInputListener(with: self) // слушаем объект, тот который подписался на YMKMapInputListener
        return x
    }()
    private lazy var fileAlreadyHasCollectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: miniImgSize, height: miniImgSize)
        layout.scrollDirection = .horizontal
        
        let x = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        x.backgroundColor = .none
        x.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        x.translatesAutoresizingMaskIntoConstraints = false
        x.heightAnchor.constraint(equalToConstant: miniImgSize).isActive = true
        x.delegate = self
        x.dataSource = self
        
        return x
    }()
    
    init(presentationController: UIViewController, isEditThroughAdmin: Bool = false) {
        self.presentationController = presentationController
        self.fileModule = FileModule(presentationController: presentationController, limit: 1)
        self.isEditThroughAdmin = isEditThroughAdmin
        
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 10
        
        Helper.settings$.subscribe { settingsModel in
            self.catTree = settingsModel.catsTree
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)

        Helper.profile$.subscribe { userExtModel in
            self.phones = userExtModel?.phones ?? []
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
        
        fileModule.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onListenChangeCatFullFromAccordition(_:)),
                                               name: .catsHorizAccorditionCatFull,
                                               object: nil)
        
        inputTitle.rx.text.orEmpty.bind{self.formData["title"] = $0}.disposed(by: disposeBag)
        
        if isEditThroughAdmin {
            inputUserID.rx.text
                .orEmpty
                .map{ UInt($0) ?? 0 }
                .bind{ self.formData["userID"] = $0 }
                .disposed(by: disposeBag)
            
            switchIsDisabled.rx.value.bind{self.formData["isDisabled"] = $0}.disposed(by: disposeBag)
            switchIsApproved.rx.value.bind{self.formData["isApproved"] = $0}.disposed(by: disposeBag)
        }
        
        descriptionTextarea.rx.text.orEmpty.bind {self.formData["description"] = $0}.disposed(by: disposeBag)
        
        inputPrice.rx.text
            .orEmpty
            .map{ UInt($0) ?? 0 }
            .bind{ self.formData["price"] = $0 }
            .disposed(by: disposeBag)
        
        inputYoutube.rx.text.orEmpty.bind{self.formData["youtube"] = $0}.disposed(by: disposeBag)
        
        sendButton.rx.tap.asDriver().drive (onNext: {
            if self.fileModule.images.count > 0 {
                self.formData["files"] = self.fileModule.images[0].image?.pngData()
                //                var aData: [Data] = []
                //                for img in fileModule.images {
                //                    if let data = img.image?.pngData() {
                //                        aData.append(data)
                //                    }
                //                }
                //                data["files"] = aData
            }
            
            self.sendButton.isEnabled = false

            if let tmpAdFull = self.adFull {
                self.serviceAd.update(tmpAdFull.adID, self.formData).subscribe { adFullModel in
                    self.responseHandler(adFullModel)
                } onError: { error in
                    self.sendButton.isEnabled = true
                } onCompleted: {
                    self.sendButton.isEnabled = true
                }.disposed(by: self.disposeBag)

            } else {
                self.serviceAd.create(self.formData).subscribe { adFullModel in
                    self.responseHandler(adFullModel)
                } onError: { error in
                    self.sendButton.isEnabled = true
                } onCompleted: {
                    self.sendButton.isEnabled = true
                }.disposed(by: self.disposeBag)
            }
        }).disposed(by: disposeBag)
        
        render()
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    private func render() {
        arrangedSubviews.forEach{$0.removeFromSuperview()}
        filesAlreadyHas.removeAll()
        saveControlNameYmaps = ""
        savePropNameForFile = ""
        var tmpFormData: [String: Any] = [:]
        // formData -не стираем, т.к. можно взять ее предыдущие значения, при смене категории
        
        adFull?.images.forEach { img in
            let y = UIImageView()
            
            y.backgroundColor = Helper.myColorToUIColor(.gray8)
            y.contentMode = .scaleAspectFit
            y.accessibilityValue = img.filepath
            y.translatesAutoresizingMaskIntoConstraints = false
            y.widthAnchor.constraint(equalToConstant: miniImgSize).isActive = true
            y.heightAnchor.constraint(equalToConstant: miniImgSize).isActive = true
            
            if let url = URL(string: "\(Helper.domain)/api/v1/resample/0/48/\(img.filepath)") {
                Helper.downloadImage(url) { image in
                    y.image = image
                }
            }
            
            filesAlreadyHas.append(y)
        }
        
        if let c = catFull {
            tmpFormData["catID"] = c.catID // имеем категорию, установим занчение тут, чем в самом низу ф-ии
            
            // динамические св-ва
            c.props.forEach { p in
                var tmpTitle = p.title
                var oldVal: Any = EMPTY
                let tmpPropID = "p\(p.propID)"
                
                // подхватим старое значение
                formData.forEach { (key, value) in
                    if key == tmpPropID {
                        oldVal = value
                    }
                }
                
                if p.propIsRequire == true {
                    tmpTitle += " *"
                }
                
                if p.kindPropName == "input" || p.kindPropName == "input_number" {
                    let elForm = TextFieldFactory.create()
                    
                    if p.kindPropName == "input_number" {
                        elForm.delegate = self // вводимые значения - только цифры
                    }
                    
                    addArrangedSubview(generateRowForForm(title: tmpTitle,
                                                          el: elForm,
                                                          suffix: p.suffix,
                                                          propComment: p.propComment,
                                                          comment: p.comment))
                    
                    // если есть объявление, то подхватим его значения
                    if let tmpAdFull = adFull {
                        for d in tmpAdFull.detailsExt {
                            if d.propID == p.propID {
                                elForm.text = d.value
                                oldVal = d.value
                                break
                            }
                        }
                    }
                    
                    tmpFormData[tmpPropID] = oldVal
                    elForm.text = oldVal as? String ?? ""
                    
                } else if p.kindPropName == "select" {
                    let pickerView = UIPickerView()
                    pickerView.tag = Int(p.propID)
                    pickerView.accessibilityValue = "select"
                    pickerView.delegate = self
                    
                    let elForm = TextFieldFactory.create()
                    elForm.inputView = pickerView
                    elForm.inputAccessoryView = toolbar
                    
                    var selectOptions: [SaveValuePropForSelect] = []
                    selectOptions.append( SaveValuePropForSelect(inputField: elForm, valueProp: nil) )
                    
                    for propValue in p.values {
                        selectOptions.append( SaveValuePropForSelect(inputField: elForm, valueProp: propValue) )
                    }
                    
                    tagSelectMap[tmpPropID] = selectOptions
                    addArrangedSubview(generateRowForForm(title: tmpTitle,
                                                          el: elForm,
                                                          suffix: p.suffix,
                                                          propComment: p.propComment,
                                                          comment: p.comment))
                    
                    // если есть объявление, то подхватим его значения
                    if let tmpAdFull = adFull {
                        for d in tmpAdFull.detailsExt {
                            if d.propID == p.propID {
                                elForm.text = d.valueName
                                
                                // вид select явл. цифровым значение, в отличии от Ангуляра. Будем конвертить в число
                                if let f = UInt(d.value) {
                                    oldVal = f
                                }
                                
                                break
                            }
                        }
                    }
                    
                    tmpFormData[tmpPropID] = oldVal
                    
                } else if p.kindPropName == "radio" {
                    var radios: [RadioItemModule] = []
                    
                    for v in p.values {
                        var isSelected = false
                        
                        // если есть объявление, то подхватим его значения
                        if let tmpAdFull = adFull {
                            for d in tmpAdFull.detailsExt {
                                if d.propID == v.propID && UInt(d.value) == v.valueID {
                                    isSelected = true
                                    tmpFormData[tmpPropID] = d.value // тут берем только актуальное
                                    break
                                }
                            }
                        }
                        
                        radios.append(RadioItemModule(name: v.title, value: v.valueID, isSelected: isSelected))
                    }
                    
                    let radioGroupModule = RadioGroupModule(radios)
                    radioGroupModule.delegate = self
                    radioGroupModule.accessibilityValue = tmpPropID
                    
                    addArrangedSubview(generateRowForForm(title: tmpTitle,
                                                          el: radioGroupModule,
                                                          suffix: p.suffix,
                                                          propComment: p.propComment,
                                                          comment: p.comment))
                    
                } else if p.kindPropName == "textarea" {
                    let elForm = UITextView()
                    elForm.isScrollEnabled = false
                    elForm.layer.borderWidth = 1
                    elForm.layer.borderColor = Helper.myColorToUIColor(.gray7).cgColor
                    
                    addArrangedSubview(generateRowForForm(title: tmpTitle,
                                                          el: elForm,
                                                          suffix: p.suffix,
                                                          propComment: p.propComment,
                                                          comment: p.comment))
                    
                    if let tmpAdFull = adFull {
                        for d in tmpAdFull.detailsExt {
                            if d.propID == p.propID {
                                elForm.text = d.value
                                oldVal = d.value
                                break
                            }
                        }
                    }
                    
                    tmpFormData[tmpPropID] = oldVal
                    
                } else if p.kindPropName == "photo" {
                    let maxFiles = String(format: DictionaryWord.maxFiles.rawValue, Int(p.propComment) ?? 0)
                    tmpTitle = "\(tmpTitle) (\(maxFiles))"
                    savePropNameForFile = tmpPropID
                    tmpFormData[tmpPropID] = oldVal // подхватим ранее значение
                    
                    addArrangedSubview(generateRowForForm(title: tmpTitle,
                                                          el: fileModule,
                                                          suffix: p.suffix,
                                                          propComment: "",
                                                          comment: p.comment))
                    
                    // подгрузим изображения
                    if adFull != nil && filesAlreadyHas.count > 0 {
                        for (i, img) in filesAlreadyHas.enumerated() {
                            tmpFormData["filesAlreadyHas[\(i)]"] = img.accessibilityValue // filepath
                        }
                        
                        tmpFormData[tmpPropID] = getTotalImages()
                        addArrangedSubview(generateRowForForm(title: "", el: fileAlreadyHasCollectionView))
                    }
                    
                } else if p.kindPropName == "ymaps" {
                    let elForm = TextFieldFactory.create()
                    elForm.accessibilityValue = tmpPropID // потом найти, чтоб вставить полный адрес
                    
                    addArrangedSubview(generateRowForForm(title: tmpTitle,
                                                          el: elForm,
                                                          suffix: p.suffix,
                                                          propComment: p.propComment,
                                                          comment: p.comment))
                    addArrangedSubview(generateRowForForm(title: DictionaryWord.clickOnMap.rawValue, el: mapView))
                    
                    if formData.keys.contains("latitude") {
                        tmpFormData["latitude"] = formData["latitude"]
                    }
                    if formData.keys.contains("longitude") {
                        tmpFormData["longitude"] = formData["longitude"]
                    }
                    
                    if let tmpAdFull = adFull {
                        for d in tmpAdFull.detailsExt {
                            if d.propID == p.propID {
                                elForm.text = d.value
                                oldVal = d.value
                            }
                        }
                        
                        // выставим карту
                        mySetPoint(point: YMKPoint(latitude: Double(tmpAdFull.latitude), longitude: Double(tmpAdFull.longitude)))
                        tmpFormData["latitude"] = tmpAdFull.latitude
                        tmpFormData["longitude"] = tmpAdFull.longitude
                    }
                    
                    saveControlNameYmaps = tmpPropID
                    tmpFormData[tmpPropID] = oldVal
                    elForm.text = oldVal as? String ?? ""
                }
            }
            // \динамические св-ва
        }
        
        if catFull == nil || catFull != nil && catFull!.isAutogenerateTitle == false {
            var x = DictionaryWord.titleOfAd.rawValue
            var titleComment = ""
            tmpFormData["title"] = ""
            
            if formData.keys.contains("title") {
                tmpFormData["title"] = formData["title"]
            }
            
            if let tmpCat = catFull {
                if tmpCat.isAutogenerateTitle == false {
                    x += " *"
                    
                    if tmpCat.titleComment != "" {
                        titleComment = tmpCat.titleComment
                    }
                }
                if let y = adFull {
                    inputTitle.text = y.title
                    tmpFormData["title"] = y.title
                }
            }
            
            addArrangedSubview(generateRowForForm(title: x, el: inputTitle, suffix: titleComment))
        }
        
        if formData.keys.contains("description") {
            tmpFormData["description"] = formData["description"]
        }
        if formData.keys.contains("phoneID") {
            tmpFormData["phoneID"] = formData["phoneID"]
        }
        
        if let tmpAdFull = adFull {
            tmpFormData["slug"] = tmpAdFull.slug
            tmpFormData["userID"] = tmpAdFull.userID
            tmpFormData["isDisabled"] = tmpAdFull.isDisabled
            tmpFormData["isApproved"] = tmpAdFull.isApproved
        }
        
        if isEditThroughAdmin == true {
            if let tmpAdFull = adFull {
                inputSlug.text = tmpAdFull.slug
                inputUserID.text = String(tmpAdFull.userID)
                switchIsDisabled.isOn = tmpAdFull.isDisabled
                switchIsApproved.isOn = tmpAdFull.isApproved
            }
            
            addArrangedSubview(generateRowForForm(title: DictionaryWord.slug.rawValue, el: inputSlug))
            addArrangedSubview(generateRowForForm(title: DictionaryWord.userID.rawValue, el: inputUserID))
            addArrangedSubview(generateRowForForm(title: DictionaryWord.isOn.rawValue, el: switchIsDisabled))
            addArrangedSubview(generateRowForForm(title: DictionaryWord.isApproved.rawValue, el: switchIsApproved))
        }
        
        addArrangedSubview(generateRowForForm(title: "\(DictionaryWord.descriptionAd.rawValue) *", el: descriptionTextarea))
        addArrangedSubview(generateRowForForm(title: "\(DictionaryWord.phoneNumber2.rawValue) *", el: inputPhone))
        
        if let tmpAdFull = adFull {
            tmpFormData["description"] = descriptionTextarea.text = tmpAdFull.description
            
            for p in phones {
                if p.phoneID == tmpAdFull.phoneID {
                    inputPhone.text = p.number
                    tmpFormData["phoneID"] = p.phoneID
                }
            }
        }
        
        var priceTitle = DictionaryWord.price.rawValue
        var priceCurrency = DictionaryWord.sum.rawValue
        if let tmpCat = catFull {
            if tmpCat.priceAlias != "" {
                priceTitle = tmpCat.priceAlias
            }
            if tmpCat.priceSuffix != "" {
                priceCurrency += " \(tmpCat.priceSuffix)"
            }
        }
        
        if formData.keys.contains("price") {
            tmpFormData["price"] = formData["price"]
        }
        if formData.keys.contains("youtube") {
            tmpFormData["youtube"] = formData["youtube"]
        }
        
        addArrangedSubview(generateRowForForm(title: "\(priceTitle) (\(priceCurrency))", el: inputPrice))
        addArrangedSubview(generateRowForForm(title: DictionaryWord.videoFromYoutube.rawValue, el: inputYoutube))
        
        if let tmpAdFull = adFull {
            inputPrice.text = String(tmpAdFull.price)
            tmpFormData["price"] = tmpAdFull.price
            
            if tmpAdFull.youtube != "" {
                let tmpYouTube = Helper.youTubeLink(tmpAdFull.youtube)
                inputYoutube.text = tmpYouTube
                tmpFormData["youtube"] = tmpYouTube
            }
            
            sendButton.setTitle(DictionaryWord.edit.rawValue, for: .normal)
        }
        
        addArrangedSubview(sendButton)
        
        if formData.keys.contains("cityName") {
            tmpFormData["cityName"] = formData["cityName"]
        }
        if formData.keys.contains("countryName") {
            tmpFormData["countryName"] = formData["countryName"]
        }
        
        if let tmpAdFull = adFull {
            tmpFormData["adID"] = tmpAdFull.adID
            tmpFormData["catID"] = tmpAdFull.catID
            tmpFormData["cityName"] = tmpAdFull.cityName
            tmpFormData["countryName"] = tmpAdFull.countryName
            tmpFormData["createdAt"] = tmpAdFull.createdAt
            tmpFormData["updatedAt"] = tmpAdFull.updatedAt
        }
        
        formData = tmpFormData
        fileAlreadyHasCollectionView.reloadData()
        
        #if DEBUG
            // addArrangedSubview(debugTextView)
        #endif
    }
    func generateRowForForm(title: String,
                            el: UIView,
                            suffix: String = "",
                            propComment: String = "",
                            comment: String = "") -> UIStackView {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 5
        
        var tmpTitle = title
        
        if suffix != "" {
            tmpTitle += " (\(suffix))"
        }
        
        x.addArrangedSubview(MyText.getSmallMuteLabel(tmpTitle))
        x.addArrangedSubview(el)
        
        if propComment != "" {
            x.addArrangedSubview(MyText.getSmallMuteLabel(propComment))
        }
        if comment != "" {
            x.addArrangedSubview(MyText.getSmallMuteLabel(comment))
        }
        
        return x
    }
    func getTotalImages() -> UInt {
        let attachedFiles = fileModule.images.count
        let oldFiles = filesAlreadyHas.count
        let totalFiles = attachedFiles + oldFiles
        return UInt(totalFiles)
    }
    func mySetPoint(point: YMKPoint) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        
        mapObjects.clear()
        
        if let img = UIImage(systemName: "mappin.circle.fill") {
            img.withTintColor(UIColor.systemRed)
            mapObjects.addPlacemark(with: point).setIconWith(img)
        }
        
        // mapView.mapWindow.map.cameraPosition.zoom
        let y = YMKCameraPosition.init(target: point, zoom: defaultMapZoom, azimuth: 0, tilt: 0)
        mapView.mapWindow.map.move(with: y)
    }
    private func responseHandler(_ x: AdFullModel) {
        let tmpTitle = (self.adFull != nil ?
                            DictionaryWord.announcementUpdatedAndSentForReview.rawValue :
                            DictionaryWord.announcementAddedAndSentForReview.rawValue)
       
        let alert = UIAlertController(title: tmpTitle, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: DictionaryWord.good.rawValue, style: .cancel) { (alert) in
            self.fileModule.reset()
            self.adFull = x
            self.fileAlreadyHasCollectionView.reloadData()
            
            if self.isEditThroughAdmin {
                NotificationCenter.default.post(name: .showJSON, object: x)
            } else {
                self.presentationController.navigationController?.popViewController(animated: true)
                // необходимо у профиля, его объявления обновить
                NotificationCenter.default.post(name: .profileAdsUpdate, object: nil)
            }
        }
        
        alert.addAction(okAction)
        self.presentationController.present(alert, animated: true, completion: nil)
    }
}

extension AdFormModule {
    @objc private func onListenChangeCatFullFromAccordition(_ notif: Notification) {
        guard let x = notif.object else {return}
        let c = x as! CatFullModel
        catFull = c
    }
    @objc private func closePanel() {
        endEditing(true)
    }
}
extension AdFormModule: UITextFieldDelegate {
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        let isAllow = allowedCharacters.isSuperset(of: characterSet)
        return isAllow
    }
}
extension AdFormModule: UIPickerViewDelegate, UIPickerViewDataSource {
    internal func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    internal func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let opt = pickerView.accessibilityValue
        var c = 0

        if opt == "phone" {
            c = phones.count

        } else if opt == "select" {
            guard let x = tagSelectMap["p\(pickerView.tag)"] else {return 0}
            c = x.count
        }

        return c
    }
    internal func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let opt = pickerView.accessibilityValue
        var title = ""

        if opt == "phone" {
            title = phones[row].number

        } else if opt == "select" {
            guard let x = tagSelectMap["p\(pickerView.tag)"] else {return ""}
            guard let vp = x[row].valueProp else {return ""}

            title = vp.title
        }

        return title
    }
    internal func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let opt = pickerView.accessibilityValue

        if opt == "phone" {
            if phones.count > 0 {
                formData["phoneID"] = phones[row].phoneID
                inputPhone.text = phones[row].number
            }

        } else if opt == "select" {
            let name = "p\(pickerView.tag)"
            guard let x = tagSelectMap[name] else {return}

            if let vp = x[row].valueProp {
                x[row].inputField.text = vp.title
                formData[name] = vp.valueID

            } else {
                x[row].inputField.text = ""
                formData.removeValue(forKey: name)
            }
        }
    }
}
extension AdFormModule: YMKMapInputListener {
    internal func onMapTap(with map: YMKMap, point: YMKPoint) {
        mySetPoint(point: point)
        searchSession = searchManager.submit(with: point,
                                             zoom: defaultMapZoom as NSNumber,
                                             searchOptions: YMKSearchOptions()) { (searchResponse: YMKSearchResponse?, error: Error?) in
            if let err = error {
                NotificationCenter.default.post(name: .flyError,
                                                object: FlyErrorModule(kindVisual: .danger,
                                                                       msg: err.localizedDescription))
                return
            }

            guard let response = searchResponse else {return}
            guard let firstGeoObject = response.collection.children.first else {return}
            guard let metadata = firstGeoObject.obj?.metadataContainer.getItemOf(YMKSearchToponymObjectMetadata.self) as? YMKSearchToponymObjectMetadata else {return}

            // выставим все найденные значения
            self.formData[self.saveControlNameYmaps] = metadata.address.formattedAddress
            self.formData["latitude"] = point.latitude
            self.formData["longitude"] = point.longitude

            let tmpParts = metadata.address.formattedAddress.components(separatedBy: ", ")
            if tmpParts.count > 0 {
                self.formData["countryName"] = tmpParts[0]

                if tmpParts.count > 1 {
                    self.formData["cityName"] = tmpParts[1]
                }
            }

            // найдем значение полного адреса
            self.arrangedSubviews.forEach { el1 in
                if el1 is UIStackView {
                    (el1 as! UIStackView).arrangedSubviews.forEach { el2 in
                        if (el2 is UITextField) && el2.accessibilityValue == self.saveControlNameYmaps {
                            (el2 as! UITextField).text = self.formData[self.saveControlNameYmaps] as? String
                        }
                    }
                }
            }
        }
    }
    internal func onMapLongTap(with map: YMKMap, point: YMKPoint) {
    }
}
extension AdFormModule: UICollectionViewDelegate, UICollectionViewDataSource {
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filesAlreadyHas.count
    }
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
        cell.addSubview(filesAlreadyHas[indexPath.row])
        return cell
    }
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alert = UIAlertController(title: DictionaryWord.itRemoveImage.rawValue, message: nil, preferredStyle: .alert)
        let noAction = UIAlertAction(title: DictionaryWord.no.rawValue, style: .cancel, handler: nil)
        let yesAction = UIAlertAction(title: DictionaryWord.yes.rawValue, style: .default) { alert in
            let index = indexPath.row

            self.formData.removeValue(forKey: "filesAlreadyHas[\(index)]")
            self.filesAlreadyHas.remove(at: index)
            collectionView.reloadData()
            
            if self.savePropNameForFile != "" {
                self.formData[self.savePropNameForFile] = self.getTotalImages()
            }
        }

        alert.addAction(yesAction)
        alert.addAction(noAction)

        presentationController.present(alert, animated: true, completion: nil)
    }
}
extension AdFormModule: FileModuleDelegate {
    internal func fileModuleDidSelect(image: UIImage?) {
        guard savePropNameForFile != "" else {return}
        formData[savePropNameForFile] = getTotalImages()
    }
}
extension AdFormModule: RadioGroupModuleDelegate {
    internal func radioGroupModuleOnChange(module: RadioGroupModule, val: UInt) {
        guard let propName = module.accessibilityValue else {return}
        formData[propName] = val
    }
}
