import Foundation
import RxSwift

final class ManagerService {
    private let http = HTTPClient()
    
    func getFirstSettings() -> Observable<SettingsModel> {
        return http.get("/api/v1")
    }
}
