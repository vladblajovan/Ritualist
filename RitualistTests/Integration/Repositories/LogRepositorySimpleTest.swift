//
//  LogRepositorySimpleTest.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
import SwiftData
import Testing
@testable import Ritualist
@testable import RitualistCore

/// Simple test to verify LogRepositoryImpl basic functionality
/// This ensures our core implementation compiles and works
@Suite("LogRepository Simple Tests")
struct LogRepositorySimpleTest {
    
    @Test("LogRepositoryImpl can be instantiated")
    func testLogRepositoryInstantiation() async throws {
        // Arrange: Create in-memory database components
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        
        // Act: Create repository
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Assert: Repository should be created successfully
        #expect(logRepository != nil)
        
        // Test that empty fetch works
        let emptyResults = try await logRepository.logs(for: UUID())
        #expect(emptyResults.isEmpty)
    }
    
    @Test("LogRepository can create and retrieve a log")
    func testBasicLogCreationAndRetrieval() async throws {
        // Arrange: Set up repository and create a habit
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit first
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        
        let habit = HabitBuilder()
            .withName("Test Habit")
            .build()
        
        try await habitRepository.create(habit)
        
        // Create a log
        let log = HabitLogBuilder()
            .withHabit(habit)
            .withValue(42.0)
            .build()
        
        // Act: Upsert the log
        try await logRepository.upsert(log)
        
        // Assert: Log should be retrievable
        let logs = try await logRepository.logs(for: habit.id)
        #expect(logs.count == 1)
        #expect(logs[0].id == log.id)
        #expect(logs[0].value == 42.0)
        #expect(logs[0].habitID == habit.id)
    }
    
    @Test("LogRepository can delete a log")
    func testLogDeletion() async throws {
        // Arrange: Set up repository with a log
        let (container, context) = try TestModelContainer.createContainerAndContext()
        let logDataSource = LogLocalDataSource(modelContainer: container)
        let logRepository = LogRepositoryImpl(local: logDataSource)
        
        // Create habit and log
        let habitDataSource = HabitLocalDataSource(modelContainer: container)
        let habitRepository = HabitRepositoryImpl(local: habitDataSource)
        
        let habit = HabitBuilder().withName("Deletable Habit").build()
        try await habitRepository.create(habit)
        
        let log = HabitLogBuilder().withHabit(habit).build()
        try await logRepository.upsert(log)
        
        // Verify log exists
        let beforeDelete = try await logRepository.logs(for: habit.id)
        #expect(beforeDelete.count == 1)
        
        // Act: Delete the log
        try await logRepository.deleteLog(id: log.id)
        
        // Assert: Log should be gone
        let afterDelete = try await logRepository.logs(for: habit.id)
        #expect(afterDelete.isEmpty)
    }
}