import UIKit
import RxSwift
import RxCocoa // один раз глобально на все
import YandexMapKit // один раз глобально на все

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let serviceManager = ManagerService()
    private let serviceAuth = AuthService()
    private let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        serviceManager.getFirstSettings().subscribe { settingsModel in
            Helper.settings$.onNext(settingsModel)
        } onError: { error in
        } onCompleted: {
            Helper.settings$.onCompleted()
        }.disposed(by: disposeBag)
        
        if JWTSingleton.instance.data != "" {
            serviceAuth.refreshTokens().subscribe { JWTModel in
                JWTSingleton.instance.data = JWTModel.JWT
                Helper.profile$.onNext(JWTModel.userExt)
            } onError: { error in
            } onCompleted: {
            }.disposed(by: disposeBag)
        }
        
        YMKMapKit.setApiKey(Helper.ymapsKey)
        YMKMapKit.setLocale("ru_RU")
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
