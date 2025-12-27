import SwiftUI
import FactoryKit

public struct StatsRoot: View {
    @Injected(\.statsViewModel) var vm
    
    public init() {}
    
    public var body: some View {
        StatsView(vm: vm)
    }
}

#Preview {
    NavigationStack {
        StatsRoot()
    }
}
