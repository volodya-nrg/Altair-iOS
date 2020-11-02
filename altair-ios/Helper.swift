import UIKit
import RxSwift

//if let value = ProcessInfo.processInfo.environment["KEY"] {
//    ...
//}

class Helper {
    private static var imageCache = NSCache<NSString, UIImage>()
    
    static let profile$ = BehaviorSubject<UserExtModel?>(value: nil)
    static let settings$ = AsyncSubject<SettingsModel>()
    static let paddingLg: CGFloat = 20
    static let paddingMd: CGFloat = 10
    static let paddingSm: CGFloat = 5
    static let globalMarginSide: CGFloat = 10
    static let btnHeight: CGFloat = 40
    static let em1: CGFloat = 17
    static let adMiniCubeWidth: CGFloat = 200
    static let adMiniCubeHeight: CGFloat = 280
    static let adMiniLineHeight: CGFloat = 160
    static let defaultBoxWidth: CGFloat = 300
    static let production: Bool = false
    // static let APIServer: String = "http://194.87.102.144:1027"
    static let APIServer: String = "http://localhost:8080"
    static let emailSupport: String = "support@altair.uz"
    static let curYear: UInt = 2020
    static let minLenPassword: UInt = 6
    static let minLenHash: UInt = 32
    // static let domain: String = "http://194.87.102.144:1027"
    static let domain: String = "http://localhost:8080"
    // ymapsPathScript: '============',
    static let ymapsKey: String = "============"
    static let youTubeExampleLink: String = "https://www.youtube.com/watch?v=zU-LndSG5RE"
    static let youTubeEmbed: String = "https://www.youtube.com/embed/"
    static let timeSecBlockForPhoneSend: UInt = 60
    static let timeSecWaitErrorFly: UInt = 6
    static let socAppIdVk: String = "============"
    static let socAppIdOk: String = "============"
    static let socAppIdFb: String = "============"
    static let socAppIdGgl: String = "============"
    static let defaultSizeFont: CGFloat = 17
    static let tagKindNumber = ["checkbox", "radio", "select", "input_number", "photo"]
    static let defaultCenterMap: [Double] = [41.311151, 69.279737] // именно Double
    static let timeWhenRemoveFlyError: TimeInterval = 10
}
extension Helper {
    static func myColorToUIColor(_ myColor: MyColor, _ alphaSrc: CGFloat = 1.0) -> UIColor {
        let hex = myColor.rawValue
        var cString = hex.trim().uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if cString.count != 6 {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alphaSrc
        )
    }
    static func downloadImage(_ url: URL, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage)
            return
        }
        
        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 10)
        let dataTask = URLSession.shared.dataTask(with: request){ data, response, error in
            guard error == nil,
                  data != nil,
                  let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else { return }
            guard let image = UIImage(data: data!) else { return }
            
            imageCache.setObject(image, forKey: url.absoluteString as NSString)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
        
        dataTask.resume()
    }
    static func priceBeauty(price: UInt) -> String {
        var result = ""
        let sPrice = String(price)
        let range = NSMakeRange(0, sPrice.count)
        
        do {
            let regex = try NSRegularExpression(
                pattern: "(\\d)(?=(\\d{3})+(?!\\d))",
                options: NSRegularExpression.Options.caseInsensitive)
            result = regex.stringByReplacingMatches(in: sPrice, options: [], range: range, withTemplate: ("$1 "))
            
        } catch {
            result = error.localizedDescription
        }
        
        return result
    }
    static func getFormattedDate(string: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.locale = Locale(identifier: "ru_RU")
        dateFormatterPrint.dateFormat = "dd MMM yyyy г."
        
        var result = ""
        
        if let date = dateFormatterGet.date(from: string) {
            result = dateFormatterPrint.string(from: date)
        }
        
        return result
    }
    // предки
    static func getAncestors(_ listCatTree: [CatTreeModel], _ findCatID: UInt) -> [CatModel] {
        var list: [CatModel] = []
        
        for item in listCatTree {
            if item.catID == findCatID {
                let a = CatModel()
                a.catID = item.catID
                a.catID = item.catID
                a.name = item.name
                a.slug = item.slug
                a.parentID = item.parentID
                a.pos = item.pos
                a.isDisabled = item.isDisabled
                a.priceAlias = item.priceAlias
                a.priceSuffix = item.priceSuffix
                a.titleHelp = item.titleHelp
                a.titleComment = item.titleComment
                a.isAutogenerateTitle = item.isAutogenerateTitle
                
                list.insert(a, at: 0)
                
                return list
            }
            if item.childes.count > 0 {
                let res = getAncestors(item.childes, findCatID)
                
                if res.count > 0 {
                    let a = CatModel()
                    a.catID = item.catID
                    a.catID = item.catID
                    a.name = item.name
                    a.slug = item.slug
                    a.parentID = item.parentID
                    a.pos = item.pos
                    a.isDisabled = item.isDisabled
                    a.priceAlias = item.priceAlias
                    a.priceSuffix = item.priceSuffix
                    a.titleHelp = item.titleHelp
                    a.titleComment = item.titleComment
                    a.isAutogenerateTitle = item.isAutogenerateTitle
                    
                    list.insert(contentsOf: res, at: 0)
                    list.insert(a, at:0)
                    
                    return list
                }
            }
        }
        
        return list
    }
    // потомки
    static func getDescendants(listCatTree: [CatTreeModel], findCatID: UInt, receiver: inout [CatModel], deep: UInt) -> Bool {
        for cat in listCatTree {
            if cat.catID == findCatID {
                let a = CatModel()
                a.catID = cat.catID
                a.catID = cat.catID
                a.name = cat.name
                a.slug = cat.slug
                a.parentID = cat.parentID
                a.pos = cat.pos
                a.isDisabled = cat.isDisabled
                a.priceAlias = cat.priceAlias
                a.priceSuffix = cat.priceSuffix
                a.titleHelp = cat.titleHelp
                a.titleComment = cat.titleComment
                a.isAutogenerateTitle = cat.isAutogenerateTitle
                
                receiver.insert(a, at: 0)
                
                return true;
            }
            if cat.childes.count > 0 {
                let res = getDescendants(listCatTree: cat.childes, findCatID: findCatID, receiver: &receiver, deep: deep + 1)
                
                if res == true {
                    let a = CatModel()
                    a.catID = cat.catID
                    a.catID = cat.catID
                    a.name = cat.name
                    a.slug = cat.slug
                    a.parentID = cat.parentID
                    a.pos = cat.pos
                    a.isDisabled = cat.isDisabled
                    a.priceAlias = cat.priceAlias
                    a.priceSuffix = cat.priceSuffix
                    a.titleHelp = cat.titleHelp
                    a.titleComment = cat.titleComment
                    a.isAutogenerateTitle = cat.isAutogenerateTitle
                    
                    receiver.insert(a, at: 0)
                    
                    if deep < 1 {
                        // тут конец
                    }
                    
                    return res
                }
            }
        }
        
        return false
    }
    // потомки в виде дерева
    static func getDescendantsNode(listCatTree: [CatTreeModel], findCatID: UInt) -> CatTreeModel? {
        for v in listCatTree {
            if v.catID == findCatID {
                return v
                
            } else if v.childes.count > 0 {
                let r = getDescendantsNode(listCatTree: v.childes, findCatID: findCatID)
                
                if r != nil {
                    return r
                }
            }
        }
        
        return nil
    }
    static func getCatTreeAsOneLevel(_ catTree: [CatTreeModel]) -> [CatWithDeepModel] {
        var list: [CatWithDeepModel] = []
        walkGetCatTreeAsOneLevel(catTree: catTree, deep: 0, receiver: &list);
        return list
    }
    static func walkGetCatTreeAsOneLevel(catTree: [CatTreeModel], deep: UInt, receiver: inout [CatWithDeepModel]) -> Void {
        for x in catTree {
            var y = CatWithDeepModel()
            y.catID = x.catID
            y.name = x.name
            y.slug = x.slug
            y.parentID = x.parentID
            y.pos = x.pos
            y.isDisabled = x.isDisabled
            y.priceAlias = x.priceAlias
            y.priceSuffix = x.priceSuffix
            y.titleHelp = x.titleHelp
            y.titleComment = x.titleComment
            y.isAutogenerateTitle = x.isAutogenerateTitle
            y.deep = deep
            
            receiver.append(y)
            
            if (x.childes.count > 0) {
                walkGetCatTreeAsOneLevel(catTree: x.childes, deep: deep+1, receiver: &receiver);
            }
        }
    }
    static func isLeaf(_ catsTree: [CatTreeModel], _ catID: UInt) -> Int {
        for el in catsTree {
            if el.catID == catID {
                if el.childes.count > 0 {
                    return 0
                }

                return 1
            }
            if el.childes.count > 0 {
                let tmp = Helper.isLeaf(el.childes, catID)

                if tmp > -1 {
                    return tmp
                }
            }
        }

        return -1
    }
    static func getUniqHash(_ length: UInt = 32, _ prefix: String = "") -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        let result = String((0..<length).map{ _ in letters.randomElement()! })
        
        return prefix + result
    }
    static func queryString(_ list: [String: Any]) -> String {
        var output: String = ""
        
        for (key, value) in list {
            output +=  "\(key)=\(value)&"
        }
        
        output = String(output.dropLast())
        
        return output
    }
    static func getElClassName(_ el: AnyObject) -> String {
        return NSStringFromClass(type(of: el.self))
    }
    static func validateEmail(_ email: String) -> Bool {
        let emailRegEx = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        
        return emailPred.evaluate(with: email)
    }
    static func youTubeLink(_ str: String) -> String {
        var result = ""
        let aParts = str.components(separatedBy: "/")
        
        if aParts.count > 0 {
            let lastPart = aParts[aParts.count - 1]
            let hash = lastPart.replacingOccurrences(of: "watch?v=", with: "")
            
            if hash != "" {
                result = "\(Helper.youTubeEmbed)\(hash)"
            }
        }

        return result
    }
    static func getCookie() -> [HTTPCookie]? {
        guard let cookies = HTTPCookieStorage.shared.cookies else {return nil}
        return cookies
    }
    static func generateRow(title: String, el: UIView) -> UIStackView {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 5
        
        if title != "" {
            x.addArrangedSubview(MyText.getSmallMuteLabel(title))
        }
        
        x.addArrangedSubview(el)
        
        return x
    }
    static func mapToString(_ dic: [String: Any]) -> String {
        var result = ""

        do {
            let theJSONData = try JSONSerialization.data(withJSONObject: dic, options: .sortedKeys)

            if let theJSONText = String(data: theJSONData, encoding: .utf8) {
                result = theJSONText
            }

        } catch (let error) {
            result = error.localizedDescription
        }

        return result
    }
}

extension Notification.Name {
    static let phoneModuleListener = Notification.Name("phoneModuleListener")
    static let deletePhone = Notification.Name("deletePhone")
    static let flyError = Notification.Name("flyError")
    static let goToLogin = Notification.Name("goToLogin")
    static let didTapOnTopCatTree = Notification.Name("didTapOnTopCatTree")
    static let catsHorizAccorditionCatFull = Notification.Name("catsHorizAccorditionCatFull")
    static let profileAdsUpdate = Notification.Name("profileAdsUpdate")
    static let showJSON = Notification.Name("showJSON")
}

enum MyColor: String {
    case black = "#000000"
    case white = "#ffffff"
    case floralwhite = "#fffaf0"
    case danger = "#ffb3b3"
    case warning = "#ffc107"
    case gray1 = "#353535"
    case gray2 = "#4f4f4f"
    case gray3 = "#666666"
    case gray4 = "#808080"
    case gray5 = "#999999"
    case gray6 = "#b3b3b3"
    case gray7 = "#d3d3d3"
    case gray8 = "#f5f5f5"
}
enum UserDefKeys: String {
    case JWT = "JWT"
    case userExt = "userExt"
}
enum DictionaryWord: String {
    case add = "Добавить"
    case addAd = "Добавить объявление"
    case addWithPrefixPlus = "+ Добавить"
    case adID = "ID объявления"
    case adm = "Администрирование"
    case ads = "Объявления"
    case aLetterHasBeenSentToYourEmail = "На ваш е-мейл было выслано письмо, для его подтверждения. Следуйте инструкциям, указанным в письме."
    case aliasForPrice = "алиас для цены"
    case altairUz = "AltairUz"
    case announcementAddedAndSentForReview = "Объявление добавлено и отправлено на проверку"
    case announcementUpdatedAndSentForReview = "Объявление обновлено и отправленно на проверку"
    case areYouSureYouWantToDeleteYourPhoneNumber = "Вы точно хотите удалить номер телефона?"
    case asFilterToo = "как фильтр (тоже)"
    case assignedProps = "Назначенные свойства"
    case asTree = "Как дерево"
    case attachPhoto = "Прикрепить фото"
    case attrName = "[name=]"
    case avatar = "Аватар"
    case aVerificationCodeHasBeenSentToYourEmail = "На Ваш е-мэйл отправлен проверочный код.\nСледуйте указаниям в письме."
    case cameraRoll = "Фотопленка"
    case cancel = "Отмена"
    case catalog = "Каталог"
    case catalogWithColon = "Каталог:"
    case categories = "Категории"
    case categoriesWithColon = "Категории:"
    case categotyID = "ID категории"
    case clickOnMap = "Кликнете по карте, чтоб определить координаты"
    case codeIsShort = "код короткий"
    case comment = "Комментарий"
    case commentUnderTitle = "комментарий под заголовок"
    case commentWillAppearUnderTheProperty = "комментарий (покажется под свойством)"
    case confirmationCode = "код подтверждения"
    case create = "Создать"
    case createdAtWithColon = "Созданно:"
    case dateRegisterWithColon = "Дата регистрации:"
    case description = "Описание"
    case descriptionAd = "Описание объявления"
    case edit = "Изменить"
    case editAd = "Редактирование объявления"
    case email = "Е-мэйл"
    case emailIsConfirmed = "Е-мэйл подтвержден"
    case emailWithColon = "Е-мэйл:"
    case exit = "Выход"
    case firstName = "Имя"
    case forgotPassword = "Забыли пароль?"
    case free = "Бесплатно"
    case good = "Хорошо"
    case helperTextForTitle = "вспомог-ый текст для заголовка"
    case hidden = "Скрыть"
    case info = "Информация"
    case inModeration = "на модерации"
    case isApproved = "Заапрувлен"
    case isAutogenerateTitle = "авто-заголовок"
    case isDisabled = "Выключено"
    case isOn = "Включен"
    case isRequire = "обязателен"
    case itRemoveImage = "Удалить картинку?"
    case kindOfTag = "Разновидность тега"
    case kindPropID = "ID вида свойства"
    case kindPropsForCats = "Разновидности типов св-в для категорий"
    case limit = "Лимит"
    case login = "Вход"
    case maxFiles = "макс. %d файлов"
    case myAds = "Мои объявления"
    case name = "Название"
    case no = "Нет"
    case notFitPhoneByMask = "номер тел. не проходит по маске"
    case nowIsRequesting = "происходит загрузка данных, нажмите чуть по позже"
    case off = "выключено"
    case offset = "Смещение"
    case open = "открыто"
    case pages = "Страницы"
    case parametresWithColon = "Параметры:"
    case parentID = "ID родителя"
    case password = "Пароль"
    case passwordConfirm = "Пароль (повтор)"
    case passwordConfirmWithColon = "Пароль (повтор):"
    case passwordNew = "Новый пароль"
    case passwordNewConfirm = "Новый пароль (повтор)"
    case passwordWithColon = "Пароль:"
    case phoneNumber2 = "Номер телефона"
    case phoneNumber = "номер телефона"
    case phoneNumbersWithColon = "Номера телефонов:"
    case photo = "Фото"
    case photoIsAtteched = "Фото прикреплено"
    case photoLibrary = "Фотогаллерея"
    case pos = "позиция"
    case price = "Цена"
    case priceWithColon = "Цена:"
    case privateComment = "Приватный комментарий"
    case profile = "Профиль"
    case propAlreadySelected = "Свойство уже выбрано"
    case propID = "ID свойства"
    case propIsEmpty = "Свойство пустое"
    case propsAsFilters = "Свойства как фильтры"
    case propsForCats = "Свойства для категорий"
    case recover = "Восстановление пароля"
    case register = "Регистрация"
    case registrationCompletedSuccessfully = "Регистрация прошла успешно"
    case save = "Сохранить"
    case search = "Поиск"
    case searchPhrase = "Поисковая фраза"
    case send = "Отправить"
    case showPhone = "Показать телефон"
    case slug = "Slug"
    case statusWithColon = "Статус:"
    case suffix = "Суффикс"
    case suffixOnPrice = "суффик на цену"
    case sum = "сум"
    case takePhoto = "Сфотографировать"
    case tellMeYouFoundThisAdOnAltairUz = "Скажите что нашли это объявление на Altair.uz"
    case test = "Тест"
    case timeOfLock = "время разблокировки: %d сек."
    case title = "Заголовок"
    case titleOfAd = "Название объявления"
    case updateAtWithColon = "Изменено:"
    case userID = "ID пользователя"
    case users = "Пользователи"
    case valueForProp = "Значения для св-ва"
    case video = "Видео"
    case videoFromYoutube = "Видео c YouTube"
    case yes = "Да"
    case zaRegister = "Зарегистрироваться"
    case conversionFailed = "Конвертация прошла неудачно"
    case notCorrectURL = "Не корректный URL"
    case errorInQueryParam = "ошибка в Query"
}
