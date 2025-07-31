import SwiftUI
import Foundation

/// A helper for creating StateObject ViewModels with proper lifecycle management
public struct ViewModelFactory {
    
    /// Creates a StateObject wrapper for ViewModels that ensures proper initialization
    /// and lifecycle management in SwiftUI views
    public static func createStateObject<T: ObservableObject>(
        _ viewModelFactory: @escaping () -> T
    ) -> StateObject<T> {
        StateObject(wrappedValue: viewModelFactory())
    }
}

/// A property wrapper that provides better state management for ViewModels
/// with dependency injection support
@propertyWrapper
public struct ManagedStateObject<T: ObservableObject>: DynamicProperty {
    @StateObject private var viewModel: T
    
    public var wrappedValue: T {
        viewModel
    }
    
    public var projectedValue: ObservedObject<T>.Wrapper {
        $viewModel
    }
    
    public init(factory: @autoclosure @escaping () -> T) {
        self._viewModel = StateObject(wrappedValue: factory())
    }
}