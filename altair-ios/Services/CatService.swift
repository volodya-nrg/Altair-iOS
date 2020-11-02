import Foundation
import RxSwift

final class CatService {
    private let http = HTTPClient()

    func getList() -> Observable<[CatModel]> {
        let data: [String: Any] = [
            "asTree": false
        ]
        return http.get("/api/v1/cats", data)
    }
    func getTree() -> Observable<CatTreeModel> {
        let data: [String: Any] = [
            "asTree": true
        ]
        return http.get("/api/v1/cats", data)
    }
    func getOne(_ catID: UInt, _ isWithPropsOnlyFiltered: Bool) -> Observable<CatFullModel> {
        let data: [String: Any] = [
            "withPropsOnlyFiltered": isWithPropsOnlyFiltered
        ]
        return http.get("/api/v1/cats/\(catID)", data)
    }
    func create(_ data: [String: Any]) -> Observable<CatFullModel> {
        return http.post("/api/v1/cats", data)
    }
    func update(_ catID: UInt, _ data: [String: Any]) -> Observable<CatFullModel> {
        return http.put("/api/v1/cats/\(catID)", data)
    }
    func delete(_ catID: UInt) -> Observable<EmptyModel> {
        return http.delete("/api/v1/cats/\(catID)")
    }
}
