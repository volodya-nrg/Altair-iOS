import Foundation
import RxSwift

final class ProfileService {
    private let http = HTTPClient()

    func getInfo() -> Observable<UserExtModel> {
        return http.get("/api/v1/profile/info")
    }
    func getSettings() -> Observable<EmptyModel> {
        return http.get("/api/v1/profile/settings")
    }
    func create(_ data: [String: Any]) -> Observable<UserModel> {
        return http.post("/api/v1/profile", data)
    }
    func update(_ data: [String: Any]) -> Observable<UserExtModel> {
        return http.put("/api/v1/profile", data, true)
    }
    func delete() -> Observable<EmptyModel> {
        return http.delete("/api/v1/profile")
    }
    func getAds(_ data: [String: Any]) -> Observable<[AdFullModel]> {
        return http.get("/api/v1/profile/ads", data)
    }
    func getAd(_ adID: UInt) -> Observable<AdFullModel> {
        return http.get("/api/v1/profile/ads/\(adID)")
    }
    func checkEmailThroughHash(hash: String) -> Observable<EmptyModel> {
        return http.get("/api/v1/profile/check-email-through/\(hash)")
    }
}
