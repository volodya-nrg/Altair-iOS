import Foundation
import RxSwift

final class PhoneService {
    private let http = HTTPClient()

    func getByID(phoneID: UInt) -> Observable<PhoneModel> {
        return http.get("/api/v1/phones/\(phoneID)")
    }
    func create(_ data: [String: Any]) -> Observable<PhoneModel> {
        return http.post("/api/v1/profile/phone", data)
    }
    func check(_ num: String, _ code: String) -> Observable<UserExtModel> {
        return http.put("/api/v1/profile/phone/\(num)/\(code)")
    }
    func delete(_ num: String) -> Observable<UserExtModel> {
        return http.delete("/api/v1/profile/phone/\(num)")
    }
}
