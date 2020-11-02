import Foundation
import RxSwift

final class AdService {
    private let http = HTTPClient()
    
    func getOne(_ adID: UInt) -> Observable<AdFullModel> {
        return http.get("/api/v1/ads/\(adID)")
    }
    func create(_ data: [String: Any]) -> Observable<AdFullModel> {
        return http.post("/api/v1/ads", data, true)
    }
    func update(_ adId: UInt, _ data: [String: Any]) -> Observable<AdFullModel> {
        return http.put("/api/v1/ads/\(adId)", data, true)
    }
    func delete(_ adId: UInt) -> Observable<EmptyModel> {
        return http.delete("/api/v1/ads/\(adId)")
    }
    func getFromCat(_ data: [String: Any]) -> Observable<[AdFullModel]> {
        return http.get("/api/v1/ads", data)
    }
    func getByQuery(_ data: [String: Any]) -> Observable<[AdFullModel]> {
        return http.get("/api/v1/search/ads", data)
    }
}
