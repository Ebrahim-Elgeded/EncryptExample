//
//  ContentView.swift
//  encryptExample
//
//  Created by ebrahim.badawy on 22/07/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.shield")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Secure Config Example")
        }
        .padding()
        .onAppear {
            testEncryptionFlow()
        }
    }
}

#Preview {
    ContentView()
}

func testEncryptionFlow() {
    let manager = EncryptionManager.shared
    let keyTag = "com.moh.nusukapp.Revamp.Nusuk.encryptExample"
    let filename = "app_config.json"
    let config: [String: String] = [
        "apiKey": "ABC123SECRETKEY",
        "apiSecret": "XYZ456SECRET"
    ]
    
    do {
        // First time only: generate and store key
        try manager.generateAndStoreKey(tag: keyTag)
        
        // Save config securely
        try manager.saveEncrypted(config: config, filename: filename, keyTag: keyTag)
        
        // Load config securely
        let loadedConfig = try manager.loadEncryptedConfig(filename: filename, keyTag: keyTag)
        print("Loaded config: \(loadedConfig)")
        
    } catch {
        print("Encryption Error: \(error)")
    }
}
