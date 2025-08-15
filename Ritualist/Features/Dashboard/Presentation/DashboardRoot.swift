import SwiftUI
import FactoryKit

public struct DashboardRoot: View {
    @Injected(\.dashboardViewModel) var vm
    
    public init() {}
    
    public var body: some View {
        DashboardView(vm: vm)
    }
}

#Preview {
    NavigationStack {
        DashboardRoot()
    }
}