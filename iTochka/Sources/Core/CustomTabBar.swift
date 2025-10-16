//
//  CustomTabBar.swift
//  iTochka
//
//  Created by Fedor Donskov on 15.10.2025.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selection: Tab
    var plusTapped: () -> Void

    var barHeight: CGFloat = 60
    var itemSize: CGFloat = 24
    var centralButtonSize: CGFloat = 52
    var avatarSize: CGFloat = 36
    var horizontalPadding: CGFloat = 24
    var spacing: CGFloat = 32

    var body: some View {
        ZStack {

            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.black.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(Capsule())
                )
                .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)
                .frame(height: barHeight)

            // Контент
            HStack(spacing: spacing) {
                tabButton(.home)
                tabButton(.notifications)

                Button(action: plusTapped) {
                    ZStack {
                        Image("plus")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    .frame(width: centralButtonSize, height: centralButtonSize)
                }

                tabButton(.messages)

                Button {
                    selection = .profile
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    AsyncImage(url: URL(string: "https://i.pravatar.cc/120?img=5")) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Color.gray.opacity(0.2)
                        }
                    }
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity(selection == .profile ? 0.9 : 0.25),
                                lineWidth: 2
                            )
                    )
                    .shadow(radius: 4, y: 2)
                }
            }
            .frame(height: barHeight)
            .padding(.horizontal, horizontalPadding)
        }
    }

    // Универсальная кнопка таба
    @ViewBuilder
    private func tabButton(_ tab: Tab) -> some View {
        Button {
            selection = tab
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            Image(systemName: tab.iconName)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: itemSize, weight: .semibold))
                .foregroundStyle(
                    tab == selection ? Color.white : Color.white.opacity(0.55)
                )
                .frame(width: itemSize * 1.8, height: itemSize * 1.8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
