//
//  RootView.swift
//  iTochka
//
//  Created by Fedor Donskov on 15.10.2025.
//

import SwiftUI

enum Tab: Hashable, CaseIterable {
    case home, notifications, create, messages, profile
    
    var iconName: String {
        switch self {
        case .home: 
            return "house.fill"
        case .notifications:
            return "bell.fill"
        case .create:
            return "plus"
        case .messages:
            return "ellipsis.bubble.fill"
        case .profile:
            return "person.crop.circle.fill"
        }
    }
}

struct RootView: View {
    @State private var selection: Tab = .home

    var body: some View {
        ZStack {
            Group {
                switch selection {
                case .home:
                    HomeView()
                case .notifications:
                    NotificationsView()
                case .create:
                    HomeView()
                case .messages:
                    MessagesView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
        }

        .safeAreaInset(edge: .bottom) {
            CustomTabBar(selection: $selection, plusTapped: {
                print("Add object")
            })
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
