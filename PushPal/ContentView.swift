import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(0)
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            GroupsView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.accentOrange)
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
