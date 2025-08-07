import SwiftUI
import FactoryKit

public struct OverviewV2Root: View {
    @StateObject private var vm = OverviewV2ViewModel()
    
    public init() {}
    
    public var body: some View {
        OverviewV2View(vm: vm)
            .navigationTitle("Ritualist")
            .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        OverviewV2Root()
    }
}