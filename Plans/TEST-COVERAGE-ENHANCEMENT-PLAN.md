# Test Coverage Enhancement Plan to Achieve 80%+ Coverage

## Current Status
- Overall test coverage: ~82%
- Target coverage: 90%+
- Priority: Functional coverage first, then performance tests
- Integration tests: Yes, spanning multiple services

## Priority 1: Critical Missing Tests (Must Have)

### 1. StreakUseCasesTests - Add CalculateLongestStreak Tests
**Current Coverage: 75% → Target: 90%**
- [ ] Test longest streak for daily habits with multiple streak periods
- [ ] Test longest streak for daysOfWeek habits 
- [ ] Test longest streak for timesPerWeek habits
- [ ] Test edge cases: empty logs, single day, habit with gaps
- [ ] Test numeric habit longest streak with daily targets
- [ ] Test habit start/end date impact on longest streak

### 2. HabitScheduleTests - Add Serialization Tests
**Current Coverage: 70% → Target: 85%**
- [ ] Test Codable encoding/decoding for all schedule types
- [ ] Test invalid JSON deserialization handling
- [ ] Test equality and comparison operators
- [ ] Test invalid schedule configurations (empty arrays, zero values)

### 3. ValidateHabitScheduleUseCaseTests - Add Lifecycle Tests
**Current Coverage: 85% → Target: 95%**
- [ ] Test validation before habit start date (should be invalid)
- [ ] Test validation after habit end date (should be invalid)  
- [ ] Test validation on exact start/end date boundaries
- [ ] Test habits with nil end dates (indefinite habits)
- [ ] Test timezone edge cases

## Priority 2: Important Coverage Gaps

### 4. StreakCalculationServiceTests - Add Performance Tests
**Current Coverage: 90% → Target: 95%**
- [ ] Test with 1000+ log entries
- [ ] Test concurrent access patterns
- [ ] Test memory usage with large datasets
- [ ] Test calculation optimization for different schedule types
- [ ] Test thread safety

### 5. NotificationUseCaseTests - Add System Integration Tests
**Current Coverage: 88% → Target: 95%**
- [ ] Test notification permission denied scenarios
- [ ] Test system notification limits (64 pending notifications)
- [ ] Test background vs foreground app states
- [ ] Test notification scheduling conflicts
- [ ] Test rich notification payloads

### 6. HabitCompletionServiceTests - Add Edge Cases
**Current Coverage: 92% → Target: 95%**
- [ ] Test timezone changes impact on completion
- [ ] Test floating-point precision for numeric targets (9.99 vs 10.0)
- [ ] Test habit modification mid-streak
- [ ] Test completion calculation with daylight saving transitions
- [ ] Test concurrent log access

## Priority 3: Integration Tests (Cross-Service)

### 7. Cross-Service Integration Tests
**New Test Suite**
- [ ] Test StreakCalculationService + HabitCompletionService integration
- [ ] Test NotificationService + HabitCompletionService integration
- [ ] Test NavigationService + NotificationService integration
- [ ] Test end-to-end habit creation → logging → streak calculation flow
- [ ] Test data consistency across services

### 8. NavigationServiceTests - Add Advanced Scenarios
**Current Coverage: 80% → Target: 85%**
- [ ] Test deep linking from notifications
- [ ] Test state restoration after app termination
- [ ] Test accessibility navigation paths
- [ ] Test navigation history management

### 9. SimpleHabitScheduleTests - Add Complex Patterns
**Current Coverage: 70% → Target: 85%**
- [ ] Test overlapping schedules
- [ ] Test schedule migration scenarios
- [ ] Test schedule modification impact

## Implementation Timeline

### Day 1: Critical Gaps
- Implement CalculateLongestStreak test suite
- Add HabitSchedule serialization tests

### Day 2: Lifecycle & Boundaries  
- Add habit lifecycle boundary tests
- Add validation edge cases
- Add timezone-specific tests

### Day 3: Performance & System Integration
- Add performance benchmarks
- Add notification system integration tests
- Add concurrent access tests

### Day 4: Integration Tests & Verification
- Implement cross-service integration tests
- Run full test suite
- Verify coverage metrics
- Address any remaining gaps

## Expected Coverage After Implementation

| Test Group | Current | Target | Priority |
|------------|---------|--------|----------|
| ValidateHabitScheduleUseCaseTests | 85% | 95% | High |
| StreakUseCasesTests | 75% | 90% | Critical |
| StreakCalculationServiceTests | 90% | 95% | Medium |
| HabitScheduleTests | 70% | 85% | High |
| NavigationServiceTests | 80% | 85% | Low |
| NotificationUseCaseTests | 88% | 95% | Medium |
| HabitCompletionServiceTests | 92% | 95% | Low |
| **Overall Coverage** | **82%** | **91%** | - |

## Success Criteria
- All test groups achieve minimum 80% coverage
- Critical business logic has 90%+ coverage
- All edge cases and error paths are tested
- Performance benchmarks are established
- Integration tests validate cross-service behavior

## Notes
- Focus on functional coverage before performance tests
- No backward compatibility tests needed (no legacy data formats)
- Integration tests are important for validating service interactions
- Use production calendar (DateUtils.userCalendar()) in all tests
- Ensure proper test isolation and cleanup