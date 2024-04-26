//
//  APIClient.swift
//  github-search-app
//
//  Created by jun.ogino on 2024/04/26.
//

import Foundation

protocol Requestable {
    // 準拠時に確定させる型
    associatedtype Model

    var url: String { get }
    var httpMethod: String { get }
    var headers: [String: String] { get }

    func decode(from data: Data) throws -> Model
}

extension Requestable {
    var urlRequest: URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}

struct GitHubSearchRepositoriesAPIRequest: Requestable {
    typealias Model = GitHubRepositories

    let searchWord: String

    var url: String {
        return "https://api.github.com/search/repositories?q=\(searchWord)"
    }
    var httpMethod: String {
        return "GET"
    }
    var headers: [String : String] {
        return [:]
    }

    func decode(from data: Data) throws -> GitHubRepositories {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GitHubRepositories.self, from: data)
    }

    init(searchWord: String) {
        self.searchWord = searchWord
    }
}

class APIClient {
    func request<T: Requestable>(_ requestable: T, completion: @escaping(Result<T.Model?, APIError>) -> Void) {
        guard let request = requestable.urlRequest else { return }
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error {
                completion(.failure(APIError.unknown(error)))
                return
            }
            guard let data, let response = response as? HTTPURLResponse else {
                completion(.failure(APIError.noResponse))
                return
            }
            if case 200..<300 = response.statusCode {
                do {
                    let model = try requestable.decode(from: data)
                    completion(.success(model))
                } catch let decodeError {
                    completion(.failure(APIError.decode(decodeError)))
                }
            } else {
                completion(.failure(APIError.server(response.statusCode)))
            }
        })
        task.resume()
    }
}

struct GitHubAccount: Codable {
    let name: String
    let bio: String
}

struct GitHubRepositories: Codable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [GitHubRepository]?
    
    struct GitHubRepository: Codable {
        let name: String
        let htmlUrl: String
    }
}

enum APIError: Error {
    case server(Int)
    case decode(Error)
    case noResponse
    case unknown(Error)
}
