import SwiftUI
import FactoryKit

public struct OverviewRoot: View {
    @Injected(\.overviewViewModel) var vm
    
    public init() {}
    
    public var body: some View {
        OverviewView(vm: vm)
    }
}

#Preview {
    NavigationStack {
        OverviewRoot()
    }
}
