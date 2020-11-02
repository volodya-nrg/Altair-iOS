import Foundation
import RxSwift

final class SearchService {
    private let http = HTTPClient()
    
    func ads(_ data: [String: Any]) -> Observable<[AdFullModel]> {
        return http.get("/api/v1/search/ads", data)
    }
}
