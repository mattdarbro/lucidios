//
//  APIConfig.swift
//  Lucid
//
//  Created by Matt Darbro on 11/15/25.
//

import Foundation

struct APIConfig {
    // Railway deployment URL
    static let baseURL = "https://lucid-agent-production.up.railway.app/v1"
    
    static var headers: [String: String] {
        [
            "Content-Type": "application/json",
            // Add auth header when implemented:
            // "Authorization": "Bearer \(authToken)"
        ]
    }
}

