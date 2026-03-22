import Foundation

enum LinkUpdaterError: LocalizedError {
    case invalidURL
    case missingURL
    case badStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The LinkUpdater URL is invalid."
        case .missingURL:
            return "Add your LinkUpdater URL first."
        case .badStatusCode(let code):
            return "The updater returned HTTP \(code)."
        }
    }
}

struct LinkUpdaterService {
    func performUpdate(with urlString: String?) async throws -> Date {
        guard let urlString, !urlString.isEmpty else {
            throw LinkUpdaterError.missingURL
        }

        guard let url = URL(string: urlString) else {
            throw LinkUpdaterError.invalidURL
        }

        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return Date()
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw LinkUpdaterError.badStatusCode(httpResponse.statusCode)
        }

        return Date()
    }
}
