# Build Settings for Subscription Control Plan

## Overview
Add build-time configuration to control whether the app uses subscription features or grants all users premium access. This allows launching with all features enabled and introducing subscriptions later, while providing debug configurations for both modes.

## Build Configurations Strategy
Create four distinct build configurations:
1. **Debug-AllFeatures**: Development with all features unlocked
2. **Debug-Subscription**: Development with subscription gating (for testing paywalls)
3. **Release-AllFeatures**: Production launch with all features enabled
4. **Release-Subscription**: Production with subscription gating enabled

## Architecture Approach
- **Build-time feature flags** using compiler directives
- **Conditional service registration** in DI container
- **Clean abstraction** preserving existing subscription infrastructure
- **Zero runtime overhead** (compile-time decisions)

## Implementation Tasks

### Phase 1: Core Infrastructure
- [x] Create `BuildConfigurationService.swift` with feature flag detection
- [x] Create `BuildConfigFeatureGatingService.swift` for all-features mode
- [x] Add compiler flag detection and configuration enums
- [x] Update `FeatureGatingService.swift` with build config awareness
- [ ] **VERIFY**: Test that all Phase 1 files compile together without errors

### Phase 2: DI Container Updates
- [x] Update `AppDI.swift` bootstrap method with conditional service registration
- [x] Update `AppDI.swift` createMinimal method with build config support
- [x] Add build configuration detection logic
- [x] Test service registration works correctly for both modes

### Phase 3: Xcode Project Configuration
- [x] Create "Debug-AllFeatures" build configuration
- [x] Create "Debug-Subscription" build configuration  
- [x] Create "Release-AllFeatures" build configuration
- [x] Create "Release-Subscription" build configuration
- [x] Add `ALL_FEATURES_ENABLED=1` compiler flag to AllFeatures configs
- [x] Add `SUBSCRIPTION_ENABLED=1` compiler flag to Subscription configs (explicit dual flag system)
- [x] Configure build schemes for each configuration

### Phase 4: Service Layer Updates
- [x] Update `UserService.swift` implementations with build config awareness
- [x] Update `MockUserService.swift` to respect build flags
- [x] Update `PaywallService.swift` to conditionally disable when all features enabled
- [ ] Test service behavior in both configurations

### Phase 5: UI Integration Points
- [x] ~~Update paywall prompts to hide when all features enabled~~ (Architecture already handles this via FeatureGatingService)
- [x] ~~Update habit creation limit checks~~ (Architecture already handles this via FeatureGatingService)
- [x] ~~Update analytics availability in `OverviewViewModel.swift`~~ (Architecture already handles this via FeatureGatingService)
- [ ] Verify settings view premium indicators work with build config
- [ ] Verify habit assistant premium features work with build config

### Phase 6: Testing & Validation
- [ ] Test Debug-AllFeatures configuration works correctly
- [ ] Test Debug-Subscription configuration shows paywalls
- [ ] Test Release-AllFeatures hides all premium gates
- [ ] Test Release-Subscription enforces subscription limits
- [ ] Verify no runtime performance impact

### Phase 7: Documentation & Cleanup
- [ ] Update CLAUDE.md with build configuration instructions
- [ ] Add build configuration switching guide
- [ ] Document testing procedures for each configuration
- [ ] Clean up any unused code or temporary flags

## Implementation Benefits
- ✅ Clean separation of build-time vs runtime configuration
- ✅ Preserves existing subscription infrastructure for future use
- ✅ Enables thorough testing of both free and premium user experiences
- ✅ Zero runtime performance overhead
- ✅ Easy switching between configurations for different release phases
- ✅ Maintains code maintainability and clean architecture

## Status
**Status**: Ready to implement
**Created**: 2025-08-03
**Last Updated**: 2025-08-03