import Foundation
import RxSwift

final class PropService {
    private let http = HTTPClient()

    func getPropsFullForCat(_ data: [String: Any]) -> Observable<[PropFullModel]> {
        return http.get("/api/v1/props", data)
    }
    func getOne(_ propID: UInt) -> Observable<PropFullModel> {
        return http.get("/api/v1/props/\(propID)")
    }
    func create(_ data: [String: Any]) -> Observable<PropFullModel> {
        return http.post("/api/v1/props", data)
    }
    func update(_ propID: UInt, _ data: [String: Any]) -> Observable<PropFullModel> {
        return http.put("/api/v1/props/\(propID)", data)
    }
    func delete(_ propID: UInt) -> Observable<EmptyModel> {
        return http.delete("/api/v1/props/\(propID)")
    }
}
