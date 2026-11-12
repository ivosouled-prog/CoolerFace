//
//  CoolerFaceApp.swift
//  CoolerFace
//
//  Created by Jinwoo Kim on 11/9/26.
//

import SwiftUI

@main
struct CoolerFaceApp: App {
    init() {
        WatchConnectivityManager.shared.activate()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
