//
//  SplashScreenView.swift
//  SubTracker
//
//  Created by Karol on 11/05/2026.
//


import SwiftUI

struct SplashScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var logoOpacity = 0.0 // Zaczynamy od całkowicie niewidocznego logo
    
    var backgroundColorJasne: Color { Color(hex: "F4F1EA") }
    var backgroundColorCiemne: Color { Color(hex: "18181B") }
    
    var body: some View {
        ZStack {
            if colorScheme == .dark {
                backgroundColorCiemne.edgesIgnoringSafeArea(.all)
            } else {
                backgroundColorJasne.edgesIgnoringSafeArea(.all)
            }
            
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .opacity(logoOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.6)) {
                        self.logoOpacity = 1.0
                    }
                    
                    // 2. Krok: Płynne zgaśnięcie (Fade Out) po krótkiej chwili
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.logoOpacity = 0.0
                        }
                    }
                }
        }
    }
}

