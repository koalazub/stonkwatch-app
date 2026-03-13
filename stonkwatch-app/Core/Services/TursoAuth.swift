import Foundation
import Security

/// Manages authentication tokens for Turso DB
/// Stores tokens securely in iOS Keychain
actor TursoAuth {
    static let shared = TursoAuth()
    
    private let keychainService = "com.stonkwatch.turso"
    private let accessTokenKey = "turso_access_token"
    private let refreshTokenKey = "turso_refresh_token"
    private let tokenExpiryKey = "turso_token_expiry"
    
    private init() {}
    
    // MARK: - Token Storage
    
    /// Store access token in Keychain
    func storeAccessToken(_ token: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: accessTokenKey,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing token first
        SecItemDelete(query as CFDictionary)
        
        // Store new token
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TursoAuthError.keychainError(status)
        }
    }
    
    /// Retrieve access token from Keychain
    func getAccessToken() async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: accessTokenKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw TursoAuthError.keychainError(status)
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    /// Store refresh token
    func storeRefreshToken(_ token: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: refreshTokenKey,
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TursoAuthError.keychainError(status)
        }
    }
    
    /// Clear all stored tokens
    func clearTokens() async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Token Validation
    
    /// Check if current token is valid
    func isTokenValid() async -> Bool {
        guard let token = try? await getAccessToken() else {
            return false
        }
        
        // Basic validation - check if token is not empty
        // In production, decode PASETO and check expiration
        return !token.isEmpty
    }
    
    // MARK: - Authentication Flow
    
    /// Authenticate with StonkWatch backend
    /// This would call the StonkWatch auth endpoint
    func authenticate(username: String, password: String) async throws -> AuthTokens {
        // TODO: Implement actual auth call to StonkWatch backend
        // This is a placeholder - real implementation would:
        // 1. POST to StonkWatch auth endpoint
        // 2. Receive PASETO access token + refresh token
        // 3. Store both securely
        
        throw TursoAuthError.notImplemented
    }
    
    /// Refresh access token using refresh token
    func refreshAccessToken() async throws -> String {
        guard let _ = try? await getRefreshToken() else {
            throw TursoAuthError.noRefreshToken
        }
        
        throw TursoAuthError.notImplemented
    }

    private func getRefreshToken() async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: refreshTokenKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        guard let data = result as? Data else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
}

/// Auth tokens returned from StonkWatch
struct AuthTokens {
    let accessToken: String
    let refreshToken: String
    let expiresIn: TimeInterval
    let tokenType: String
}

/// Auth error types
enum TursoAuthError: Error {
    case keychainError(OSStatus)
    case noRefreshToken
    case tokenExpired
    case invalidCredentials
    case networkError(Error)
    case notImplemented
    
    var localizedDescription: String {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenExpired:
            return "Token has expired"
        case .invalidCredentials:
            return "Invalid username or password"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .notImplemented:
            return "Authentication not yet implemented"
        }
    }
}
