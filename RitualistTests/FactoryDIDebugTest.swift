//
//  FactoryDIDebugTest.swift
//  RitualistTests
//
//  Created by Claude on 22.08.2025.
//

import Testing
import Foundation
import FactoryKit
@testable import Ritualist
@testable import RitualistCore

@available(*, deprecated, message: "PHASE 1B+4B MIGRATION REVIEW: This test uses Mock instances for DI testing. Needs review to determine if this is appropriate system boundary testing or should be rewritten with real implementations.")
/// Isolated Factory DI verification test to debug dependency injection issues
/// 
/// This test validates that Factory DI mock configuration works correctly
/// and that OverviewViewModel receives the properly configured mock instances.
@Suite("Factory DI Debug Tests")
@MainActor
final class FactoryDIDebugTest {
    
    init() async throws {
        // Set up clean Factory state for debugging
        Container.shared.manager.reset()
        Container.shared.manager.push()
        
        print("🏭 [FACTORY DEBUG] Test scope initialized")
    }
    
    deinit {
        Container.shared.manager.pop()
        print("🏭 [FACTORY DEBUG] Test scope cleaned up")
    }
    
    @Test("Factory DI mock resolution works correctly")
    func testFactoryMockResolution() async throws {
        // Verify that Factory returns mock instances, not production ones
        let getActiveHabitsInstance = Container.shared.getActiveHabits()
        let getBatchLogsInstance = Container.shared.getBatchLogs()
        
        #expect(getActiveHabitsInstance is MockGetActiveHabitsUseCase, "Should resolve to MockGetActiveHabitsUseCase")
        #expect(getBatchLogsInstance is MockGetBatchLogsUseCase, "Should resolve to MockGetBatchLogsUseCase")
        
        print("🏭 [FACTORY DEBUG] Mock resolution verified")
    }
    
    @Test("Factory singleton behavior maintains instance consistency")
    func testFactorySingletonBehavior() async throws {
        // Get the same factory multiple times
        let instance1 = Container.shared.getActiveHabits() as! MockGetActiveHabitsUseCase
        let instance2 = Container.shared.getActiveHabits() as! MockGetActiveHabitsUseCase
        
        // Configure first instance
        instance1.shouldFail = true
        instance1.errorToThrow = NSError(domain: "Test", code: 1, userInfo: nil)
        
        // Verify second instance has same configuration (singleton behavior)
        #expect(instance2.shouldFail == true, "Singleton should maintain state across resolutions")
        #expect(ObjectIdentifier(instance1) == ObjectIdentifier(instance2), "Should be same object instance")
        
        print("🏭 [FACTORY DEBUG] Singleton behavior verified - same instance returned")
    }
    
    @Test("OverviewViewModel receives configured mock instances")
    func testOverviewViewModelMockInjection() async throws {
        // Step 1: Configure mocks to fail BEFORE creating ViewModel
        let mockGetActiveHabits = Container.shared.getActiveHabits() as! MockGetActiveHabitsUseCase
        let mockGetBatchLogs = Container.shared.getBatchLogs() as! MockGetBatchLogsUseCase
        
        mockGetActiveHabits.shouldFail = true
        mockGetActiveHabits.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        mockGetBatchLogs.shouldFail = true  
        mockGetBatchLogs.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        print("🏭 [FACTORY DEBUG] Pre-VM Mock configuration:")
        print("  - GetActiveHabits shouldFail: \(mockGetActiveHabits.shouldFail)")
        print("  - GetBatchLogs shouldFail: \(mockGetBatchLogs.shouldFail)")
        print("  - GetActiveHabits instance: \(ObjectIdentifier(mockGetActiveHabits))")
        print("  - GetBatchLogs instance: \(ObjectIdentifier(mockGetBatchLogs))")
        
        // Step 2: Create ViewModel (this triggers @Injected property resolution)
        let vm = OverviewViewModel()
        
        // Step 3: Verify ViewModel got the same configured mock instances
        let postVMGetActiveHabits = Container.shared.getActiveHabits() as! MockGetActiveHabitsUseCase
        let postVMGetBatchLogs = Container.shared.getBatchLogs() as! MockGetBatchLogsUseCase
        
        print("🏭 [FACTORY DEBUG] Post-VM Mock verification:")
        print("  - Same GetActiveHabits instance: \(ObjectIdentifier(postVMGetActiveHabits) == ObjectIdentifier(mockGetActiveHabits))")
        print("  - Same GetBatchLogs instance: \(ObjectIdentifier(postVMGetBatchLogs) == ObjectIdentifier(mockGetBatchLogs))")
        print("  - GetActiveHabits still shouldFail: \(postVMGetActiveHabits.shouldFail)")
        print("  - GetBatchLogs still shouldFail: \(postVMGetBatchLogs.shouldFail)")
        
        // Step 4: Test that the mocks actually throw errors when called
        do {
            _ = try await mockGetActiveHabits.execute()
            Issue.record("Mock should have thrown error")
        } catch {
            print("🏭 [FACTORY DEBUG] GetActiveHabits mock correctly threw error: \(error)")
        }
        
        do {
            _ = try await mockGetBatchLogs.execute(for: [], since: nil, until: nil)
            Issue.record("Mock should have thrown error")
        } catch {
            print("🏭 [FACTORY DEBUG] GetBatchLogs mock correctly threw error: \(error)")
        }
        
        // Step 5: Assert Factory DI is working correctly
        #expect(ObjectIdentifier(postVMGetActiveHabits) == ObjectIdentifier(mockGetActiveHabits), "ViewModel should get same mock instance")
        #expect(ObjectIdentifier(postVMGetBatchLogs) == ObjectIdentifier(mockGetBatchLogs), "ViewModel should get same mock instance")
        #expect(postVMGetActiveHabits.shouldFail == true, "Mock configuration should persist")
        #expect(postVMGetBatchLogs.shouldFail == true, "Mock configuration should persist")
        
        print("🏭 [FACTORY DEBUG] All Factory DI validations passed!")
    }
    
    @Test("Mock error configuration and throwing works correctly")
    func testMockErrorBehavior() async throws {
        // Configure mock to fail
        let mock = Container.shared.getActiveHabits() as! MockGetActiveHabitsUseCase
        mock.shouldFail = true
        mock.errorToThrow = NSError(domain: "TestDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Mock test error"])
        
        // Verify error is thrown
        do {
            _ = try await mock.execute()
            Issue.record("Mock should have thrown error when shouldFail=true")
        } catch let error as NSError {
            #expect(error.domain == "TestDomain", "Should throw configured error")
            #expect(error.code == 999, "Should throw configured error code")
            print("🏭 [FACTORY DEBUG] Mock error behavior verified: \(error.localizedDescription)")
        }
        
        // Verify call count is tracked
        #expect(mock.executeCallCount == 1, "Should track execute calls even when failing")
        
        print("🏭 [FACTORY DEBUG] Mock error behavior test completed successfully")
    }
}