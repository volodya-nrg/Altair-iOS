import Foundation
import RxSwift

final class UserService {
    private let http = HTTPClient()
    
    func getUsers() -> Observable<[UserModel]> {
        return http.get("/api/v1/users")
    }
    func getUser(_ userID: UInt) -> Observable<UserModel> {
        return http.get("/api/v1/users/\(userID)")
    }
    func create(_ data: [String: Any]) -> Observable<UserModel> {
        return http.post("/api/v1/users", data, true)
    }
    func update(_ userID: UInt, _ data: [String: Any]) -> Observable<UserModel> {
        return http.put("/api/v1/users/\(userID)", data, true)
    }
    func delete(_ userID: UInt) -> Observable<EmptyModel> {
        return http.delete("/api/v1/users/\(userID)")
    }
}
