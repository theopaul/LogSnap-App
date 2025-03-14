import SwiftUI
import CoreData

// Helper for preview context if not available
private struct PersistentContainer {
    static var preview: NSPersistentContainer = {
        // Use the existing preview context from CoreDataManager
        return NSPersistentContainer(name: "LogSnap")
    }()
}

struct DashboardView: View {
    @Environment(\.managedObjectContext) var viewContext
    @StateObject private var viewModel: DashboardViewModel
    
    init() {
        // Initialize ViewModel with a temporary context
        // The actual context will be injected from the environment
        let vm = DashboardViewModel(context: NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType))
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Cards
                    summaryCardsSection
                    
                    // Recent Products
                    recentProductsSection
                    
                    // Recent Suppliers
                    recentSuppliersSection
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .refreshable {
                viewModel.refreshData(context: viewContext)
            }
            .onAppear {
                // Use the environment's context when the view appears
                viewModel.refreshData(context: viewContext)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Summary Cards Section
    private var summaryCardsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                NavigationLink(destination: ProductListView()) {
                    SummaryCard(
                        title: "Products",
                        count: viewModel.productCount,
                        icon: "cube.fill",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: SupplierListView()) {
                    SummaryCard(
                        title: "Suppliers",
                        count: viewModel.supplierCount,
                        icon: "building.2.fill",
                        color: .green
                    )
                }
                
                NavigationLink(destination: ContactsListView()) {
                    SummaryCard(
                        title: "Contacts",
                        count: viewModel.contactCount,
                        icon: "person.2.fill",
                        color: .orange
                    )
                }
                
                NavigationLink(destination: RecentItemsView()) {
                    SummaryCard(
                        title: "Recent",
                        count: nil,
                        icon: "clock.fill",
                        color: .purple
                    )
                }
            }
        }
    }
    
    // MARK: - Quick Access Section
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Access")
                .font(.headline)
            
            HStack(spacing: 12) {
                NavigationLink(destination: ProductListView()) {
                    QuickAccessButton(
                        title: "Products",
                        count: viewModel.productCount,
                        icon: "cube.fill",
                        color: .blue
                    )
                }
                
                NavigationLink(destination: SupplierListView()) {
                    QuickAccessButton(
                        title: "Suppliers",
                        count: viewModel.supplierCount,
                        icon: "building.2.fill",
                        color: .green
                    )
                }
                
                NavigationLink(destination: ContactsListView()) {
                    QuickAccessButton(
                        title: "Contacts",
                        count: viewModel.contactCount,
                        icon: "person.2.fill",
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Recent Products Section
    private var recentProductsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Products")
                .font(.headline)
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else {
                // Placeholder for recent products
                Text("No recent products")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Recent Suppliers Section
    private var recentSuppliersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Suppliers")
                .font(.headline)
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else {
                // Placeholder for recent suppliers
                Text("No recent suppliers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Helper Views
struct SummaryCard: View {
    let title: String
    let count: Int?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(count != nil ? "\(count!)" : "View")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

struct QuickAccessButton: View {
    let title: String
    let count: Int?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let count = count {
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environment(\.managedObjectContext, CoreDataManager.previewContext)
            .environmentObject(UserSettings())
        
        DashboardView()
            .environment(\.managedObjectContext, CoreDataManager.previewContext)
            .environmentObject(UserSettings())
            .environment(\.locale, .init(identifier: "pt"))
            .preferredColorScheme(.dark)
            .previewDisplayName("Portuguese (Dark)")
    }
}
