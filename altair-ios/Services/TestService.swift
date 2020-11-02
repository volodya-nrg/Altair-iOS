import Foundation
import RxSwift

final class TestService {
    private let http = HTTPClient()
    
    func request() -> Observable<EmptyModel> {
        return http.get("/api/v1/test")
    }
}
