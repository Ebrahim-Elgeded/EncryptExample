//
//  EncryptionManager.swift
//  encryptExample
//
//  Created by ebrahim.badawy on 22/07/2025.
//

import Foundation
import CryptoKit
import Security

final class EncryptionManager {
    static let shared = EncryptionManager()
    
    private init() {}
    
    private let fileManager = FileManager.default
    
    // MARK: - Key Management
    
    func generateAndStoreKey(tag: String) throws {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
        }
    }
    // MARK: - File Operations
    
    func saveEncrypted(config: [String: String], filename: String, keyTag: String) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: config, options: [])
        let key = try retrieveKey(tag: keyTag)
        let encryptedData = try encrypt(jsonData, using: key)
        let obfuscatedName = obfuscatedFileName(for: filename)
        
        let fileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(obfuscatedName)
        
        try encryptedData.write(to: fileURL)
        print("Encrypted config saved at: \(fileURL.path)")
    }
    
    func loadEncryptedConfig(filename: String, keyTag: String) throws -> [String: String] {
        let key = try retrieveKey(tag: keyTag)
        let obfuscatedName = obfuscatedFileName(for: filename)
        
        let fileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(obfuscatedName)
        
        let encryptedData = try Data(contentsOf: fileURL)
        let decryptedData = try decrypt(encryptedData, using: key)
        
        guard let config = try JSONSerialization.jsonObject(with: decryptedData, options: []) as? [String: String] else {
            throw NSError(domain: "ParseError", code: -1, userInfo: nil)
        }
        
        return config
    }
    
    func obfuscatedFileName(for originalName: String) -> String {
        let hash = SHA256.hash(data: originalName.data(using: .utf8)!)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Retrieve Key Management

    func retrieveKey(tag: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let keyData = item as? Data else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
        }
        
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Encryption / Decryption
    
    func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(_ ciphertext: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealedBox, using: key)
    }
    

}
