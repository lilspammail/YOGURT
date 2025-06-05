import Foundation

final class WebhookClient {
    private let url: URL

    init(webhookURL: URL) {
        self.url = webhookURL
    }

    func send<T: Encodable>(
        payload: T,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let jsonString = encodeToJSON(payload) {
            req.httpBody = jsonString.data(using: .utf8)
            print("📦 Sending payload JSON:\n\(jsonString)")
        } else {
            let err = NSError(domain: "WebhookClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode payload"])
            print("❌ Failed to encode payload")
            completion?(.failure(err))
            return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion?(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if (200..<300).contains(httpResponse.statusCode) {
                    print("✅ Server responded with status \(httpResponse.statusCode)")
                    completion?(.success(()))
                } else {
                    let serverMessage = String(data: data ?? Data(), encoding: .utf8) ?? "No response body"
                    print("⚠️ Server error \(httpResponse.statusCode): \(serverMessage)")
                    completion?(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverMessage])))
                }
            } else {
                print("❌ No valid HTTP response")
                completion?(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No valid HTTP response"])))
            }
        }.resume()
    }
}
