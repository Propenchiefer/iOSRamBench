//
//  InfoSheetView.swift
//  RamBench
//
//  Created by Autumn on 8/4/25.
//

import SwiftUI
import CoreHaptics // doesnt work rn

struct InfoSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    let gradientColors = [
        Color.blue, Color.blue.opacity(0.7),
        Color.purple, Color.purple.opacity(0.8), Color.blue,
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color.blue.opacity(0.03),
                        Color.purple.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        VStack(spacing: 20) {
                            Image("ffff")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 8) {
                                ZStack {
                                    Text("About RAMBench")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.clear)
                                        .background(
                                            FluidGradient(colors: gradientColors)
                                            .mask(Text("About RAMBench").font(.system(size: 32, weight: .bold, design: .rounded)))
                                        )
                                    Text("About RAMBench")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.clear)
                                        .shadow(color: Color.purple.opacity(0.3), radius: 1, x: 0.5, y: 0.5)
                                }
                            }
                        }
                        .padding(.top, 20)
    
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                            }
                            
                            Text("RAMBench tests your device's RAM limits by allocating memory until it hits the system limit. Using both vm_allocate and malloc.")
                                .font(.system(size: 16, weight: .medium))
                                .lineSpacing(4)
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        )

                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Thanks to:")
                                    .font(.system(size: 20, weight: .semibold))
                                Spacer()
                            }
                            
                            VStack(spacing: 16) {
                                ContributorCard(
                                    name: "Autumn",
                                    role: "Creator",
                                    url: "https://github.com/Propenchiefer",
                                    imageName: "AutumnImage",
                                    color: .blue
                                )
                                
                                ContributorCard(
                                    name: "Stossy11",
                                    role: "Memory allocation help & device detection",
                                    url: "https://github.com/Stossy11",
                                    imageName: "Stossyimage",
                                    color: .blue
                                )
                                
                                ContributorCard(
                                    name: "CycloKid",
                                    role: "App icon & graphics",
                                    url: "https://github.com/CycloKid",
                                    imageName: "Cyclokidimage",
                                    color: .blue
                                )
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        )
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color(.tertiarySystemBackground))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct ContributorCard: View {
    let name: String
    let role: String
    let url: String
    let imageName: String
    let color: Color
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(role)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}
