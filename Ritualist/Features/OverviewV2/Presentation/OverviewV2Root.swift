import SwiftUI
import FactoryKit

public struct OverviewV2Root: View {
    @Injected(\.overviewV2ViewModel) var vm
    
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