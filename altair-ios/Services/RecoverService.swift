import Foundation
import RxSwift

final class RecoverService {
    private let http = HTTPClient()
    
    func sendHash(_ data: [String: Any]) -> Observable<EmptyModel> {
        return http.post("/api/v1/recover/send-hash", data)
    }
    func changePassword(_ data: [String: Any]) -> Observable<EmptyModel> {
        return http.post("/api/v1/recover/change-pass", data)
    }
}
