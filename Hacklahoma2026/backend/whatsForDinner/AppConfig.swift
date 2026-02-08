//
//  AppConfig.swift
//  whatsForDinner
//
//  Central configuration for API base URL (backend).
//

import Foundation

enum AppConfig {
    /// Backend What's For Dinner API base URL. Use your machine's IP for device; localhost for simulator.
    static var apiBaseURL: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8000"
        #else
        return "http://127.0.0.1:8000" // Replace with your Mac's IP when testing on device
        #endif
    }

    static var apiURL: URL? { URL(string: apiBaseURL) }
}
