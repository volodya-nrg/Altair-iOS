import Foundation
import RxSwift

final class PagesService {
    private let http = HTTPClient()
    
    func pageAd(_ adID: UInt) -> Observable<PageAdModel> {
        return http.get("/api/v1/pages/ad/\(adID)")
    }
    func pageMain(limit: UInt = 4) -> Observable<PageMainModel> {
        let data: [String: Any] = [
            "limit": limit
        ]
        return http.get("/api/v1/pages/main", data)
    }
}
