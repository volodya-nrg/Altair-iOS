import Foundation
import RxSwift

final class KindPropsService {
    private let http = HTTPClient()

    func getAll() -> Observable<[KindPropModel]> {
        return http.get("/api/v1/kind_props")
    }
    func getOne(_ elID: UInt) -> Observable<KindPropModel> {
        return http.get("/api/v1/kind_props/\(elID)")
    }
    func create(_ data: [String: Any]) -> Observable<KindPropModel> {
        return http.post("/api/v1/kind_props", data)
    }
    func update(_ elID: UInt, _ data: [String: Any]) -> Observable<KindPropModel> {
        return http.put("/api/v1/kind_props/\(elID)", data)
    }
    func delete(_ elID: UInt) -> Observable<EmptyModel> {
        return http.delete("/api/v1/kind_props/\(elID)")
    }
}
