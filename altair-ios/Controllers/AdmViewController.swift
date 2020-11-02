import UIKit

final class AdmViewController: BaseViewController {
    private let storageStackView: UIStackView = {
        let x = UIStackView()
        x.spacing = 10
        x.alignment = .top
        return x
    }()
    private let formsStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.spacing = 5
        return x
    }()
    private let JSONResultTextView: UITextView = {
        let x = UITextView()
        x.isScrollEnabled = false
        x.isEditable = false
        x.isSelectable = false
        x.backgroundColor = Helper.myColorToUIColor(.gray8)
        return x
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.adm.rawValue
        
        attachElements()
        setConstrains()
        addEvents()
    }
}
extension AdmViewController: DisciplineProtocol {
    func attachElements() {
        let listForms = [
            AccordionModule(title: DictionaryWord.categories.rawValue, items: [
                AccordionModule(title: "GET: /api/v1/cats", items: [FormCatsGetCatsModule()]),
                AccordionModule(title: "GET: /api/v1/cats/:catID", items: [FormCatsGetCatsCatIDModule()]),
                AccordionModule(title: "POST: /api/v1/cats", items: [FormCatsPostCatsModule()]),
                AccordionModule(title: "PUT: /api/v1/cats/:catID", items: [FormCatsPutCatsCatIDModule()]),
                AccordionModule(title: "DELETE: /api/v1/cats/:catID", items: [FormCatsDeleteCatsCatIDModule()]),
            ]),
            AccordionModule(title: DictionaryWord.users.rawValue, items: [
                AccordionModule(title: "GET: /api/v1/users", items: [FormUsersGetUsersModule()]),
                AccordionModule(title: "GET: /api/v1/users/:userID", items: [FormUsersGetUsersUserIDModule()]),
                AccordionModule(title: "POST: /api/v1/users", items: [FormUsersPostUsersModule(presentationController: self)]),
                AccordionModule(title: "PUT: /api/v1/user", items: [FormUsersPutUsersUserIDModule(presentationController: self)]),
                AccordionModule(title: "DELETE: /api/v1/users/:userID", items: [FormUsersDeleteUsersUserIDModule()]),
            ]),
            AccordionModule(title: DictionaryWord.ads.rawValue, items: [
                AccordionModule(title: "GET: /api/v1/ads", items: [FormAdsGetAdsModule()]),
                AccordionModule(title: "GET: /api/v1/ads/:adID", items: [FormAdsGetAdsAdIDModule()]),
                AccordionModule(title: "POST: /api/v1/ads", items: [FormAdsPostAdsModule(presentationController: self)]),
                AccordionModule(title: "PUT: /api/v1/ads/:adID", items: [FormAdsPutAdsAdIDModule(presentationController: self)]),
                AccordionModule(title: "DELETE: /api/v1/ads/:adID", items: [FormAdsDeleteAdsAdIDModule()]),
            ]),
            AccordionModule(title: DictionaryWord.propsForCats.rawValue, items: [
                AccordionModule(title: "GET: /api/v1/props", items: [FormPropsGetPropsModule()]),
                AccordionModule(title: "GET: /api/v1/props/:propID", items: [FormPropsGetPropsPropIDModule()]),
                AccordionModule(title: "POST: /api/v1/props", items: [FormPropsPostPropsModule()]),
                AccordionModule(title: "PUT: /api/v1/props/:propID", items: [FormPropsPutPropsPropIDModule()]),
                AccordionModule(title: "DELETE: /api/v1/props/:propID", items: [FormPropsDeletePropsPropIDModule()]),
            ]),
            AccordionModule(title: DictionaryWord.kindPropsForCats.rawValue, items: [
                AccordionModule(title: "GET: /api/v1/kind_props", items: [FormKindPropsGetAllModule()]),
                AccordionModule(title: "GET: /api/v1/kind_props/:kindPropID", items: [FormKindPropsGetOneModule()]),
                AccordionModule(title: "POST: /api/v1/kind_props", items: [FormKindPropsPostModule()]),
                AccordionModule(title: "PUT: /api/v1/kind_props/:kindPropID", items: [FormKindPropsPutModule()]),
                AccordionModule(title: "DELETE: /api/v1/kind_props/:kindPropID", items: [FormKindPropsDeleteModule()]),
            ]),
            AccordionModule(title: DictionaryWord.pages.rawValue, items: [
                AccordionModule(title: "GET: /api/v1/pages/ad/:adID", items: [FormPagesAdAdIDModule()]),
                AccordionModule(title: "GET: /api/v1/pages/main", items: [FormPagesMainModule()]),
            ]),
            AccordionModule(title: DictionaryWord.search.rawValue, items: [
                AccordionModule(title: "GET: /api/v1/search/ads", items: [FormSearchAdsModule()]),
            ]),
            AccordionModule(title: DictionaryWord.test.rawValue, items: [
                AccordionModule(title: "GET: /api/v1/test", items: [FormTestModule()]),
            ]),
        ]
        
        listForms.forEach{formsStackView.addArrangedSubview($0)}
        
        storageStackView.addArrangedSubview(formsStackView)
        storageStackView.addArrangedSubview(JSONResultTextView)
        boxStackView.addArrangedSubview(storageStackView)
    }
    func setConstrains() {
        formsStackView.widthAnchor.constraint(equalToConstant: 250).isActive = true
    }
    func addEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(onListenerShowJSON(_:)), name: .showJSON, object: nil)
    }
}
extension AdmViewController {
    @objc private func onListenerShowJSON(_ notif: Notification) {
        guard let x = notif.object, let obj = x as? Codable else {
            JSONResultTextView.text = ""
            NotificationCenter.default.post(name: .flyError,
                                            object: FlyErrorModule(kindVisual: .danger,
                                                                   msg: DictionaryWord.conversionFailed.rawValue))
            return
        }
        
        do {
            let object = try JSONSerialization.jsonObject(with: obj.myData(), options: [])
            let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .prettyPrinted])

            if let prettyPrintedString = String(data: data, encoding: .utf8) {
                JSONResultTextView.text = prettyPrintedString
            }
        } catch (let error) {
            NotificationCenter.default.post(name: .flyError,
                                            object: FlyErrorModule(kindVisual: .danger,
                                                                   msg: error.localizedDescription))
        }
    }
}
