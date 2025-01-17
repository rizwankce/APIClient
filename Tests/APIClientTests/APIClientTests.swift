// The MIT License (MIT)
//
// Copyright (c) 2021 Alexander Grebenyuk (github.com/kean).

import XCTest
import Mocker
@testable import APIClient

final class APIClientTests: XCTestCase {
    var client: APIClient!
    
    override func setUp() {
        super.setUp()
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]

        client = APIClient(host: "api.github.com", configuration: configuration)
    }
    
    // You don't need to provide a predefined list of resources in your app.
    // You can define the requests inline instead.
    func testDefiningRequestInline() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            .get: json(named: "user")
        ]).register()
        
        // WHEN
        let user: User = try await client.send(.get("/user"))
                                               
        // THEN
        XCTAssertEqual(user.login, "kean")
    }
    
    func testCancellingTheRequest() async throws {
        // Given
        let url = URL(string: "https://api.github.com/users/kean")!
        var mock = Mock(url: url, dataType: .json, statusCode: 200, data: [
            .get: json(named: "user")
        ])
        mock.delay = DispatchTimeInterval.seconds(60)
        mock.register()
        
        // When
        let task = Task {
            try await client.send(URLRequest(url: url))
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            task.cancel()
        }
        
        // Then
        do {
            let _ = try await task.value
        } catch {
            XCTAssertTrue(error is URLError)
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        }
    }
    
    // MARK: Decoding
    
    func testDecodingWithDecodableResponse() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            .get: json(named: "user")
        ]).register()
        
        // WHEN
        let user: User = try await client.send(.get("/user"))
                                               
        // THEN
        XCTAssertEqual(user.login, "kean")
    }
    
    func testDecodingWithVoidResponse() async throws {
        // GIVEN
        let url = URL(string: "https://api.github.com/user")!
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            .post: json(named: "user")
        ]).register()
        
        // WHEN
        let request = Request<Void>.post("/user", body: ["login": "kean"])
        try await client.send(request)
    }
}

final class APIClientIntegrationTests: XCTestCase {
    var sut: APIClient!
    
    override func setUp() {
        super.setUp()
        
        sut = APIClient(host: "api.github.com")
    }

    func _testGitHubUsersApi() async throws {
        let user = try await sut.send(Resources.users("kean").get)
        
        XCTAssertEqual(user.login, "kean")
    }
}

private func json(named name: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: "json")
    return try! Data(contentsOf: url!)
}
