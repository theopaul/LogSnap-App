import SwiftUI

public struct ContentView: View {
    public var body: some View {
        TabView {
            Text("LogSnap App")
                .font(.largeTitle)
                .padding()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            Text("Products")
                .font(.largeTitle)
                .padding()
                .tabItem {
                    Label("Products", systemImage: "cube.box")
                }
            
            Text("Settings")
                .font(.largeTitle)
                .padding()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
} 