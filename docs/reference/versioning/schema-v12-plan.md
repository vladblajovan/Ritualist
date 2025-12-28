# Schema V12 Implementation Plan

## Overview

This document outlines the implementation plan for Schema V12, which adds database indexes to optimize query performance.

**GitHub Issue**: #126
**Migration Type**: Lightweight (adding indexes only)
**Current Schema Version**: V11 → V12

## Changes Summary

### 1. HabitLogModel - Index on `habitID`
**Purpose**: Optimize habit log queries by habitID
**Query Pattern**: `#Predicate { $0.habitID == targetHabitID }`
**Impact**: Faster streak calculation, progress tracking, log history

### 2. HabitCategoryModel - Indexes on `isActive` and `isPredefined`
**Purpose**: Optimize category filtering
**Query Pattern**: `#Predicate { $0.isActive == true }` or `#Predicate { $0.isPredefined == true }`
**Impact**: Faster category list loading, predefined category filtering

### 3. PersonalityAnalysisModel - Indexes on `userId` and `analysisDate`
**Purpose**: Optimize personality analysis lookups
**Query Pattern**: `#Predicate { $0.userId == targetUserId }` with sort by `analysisDate`
**Impact**: Faster user analysis retrieval, historical analysis queries

## Implementation Steps

Following the schema-migrations.md checklist:

### Step 1: Create SchemaV12.swift ☐
- Copy all models from SchemaV11
- Add `@Index` annotations to specified properties
- Update version identifier to (12, 0, 0)
- Add type aliases (HabitLogModelV12, etc.)

### Step 2: Update MigrationPlan.swift ☐
- Add SchemaV12.self to schemas array
- Add migrateV11toV12 migration stage (lightweight)
- Update documentation comments

### Step 3: Update ActiveSchema.swift ☐
- Change `ActiveSchemaVersion = SchemaV11` to `SchemaV12`
- Update migration history comment

### Step 4: Update Documentation ☐
- Update schema-migrations.md with V12 info
- Update current schema version references

### Step 5: Add Unit Tests ☐
- Test schema version identifier
- Test model types array
- Test lightweight migration compiles

### Step 6: Build & Verify ☐
- Build project
- Verify no compiler errors
- Test fresh install
- Test migration from V11

## Index Syntax

```swift
@Model
public final class HabitLogModel {
    @Index
    public var habitID: UUID = UUID()
    // ... other properties
}

@Model
public final class HabitCategoryModel {
    @Index
    public var isActive: Bool = true
    @Index
    public var isPredefined: Bool = false
    // ... other properties
}

@Model
public final class PersonalityAnalysisModel {
    @Index
    public var userId: String = ""
    @Index
    public var analysisDate: Date = Date()
    // ... other properties
}
```

## Migration Notes

- **Type**: Lightweight migration
- **Data Transformation**: None required
- **Index Creation**: Handled automatically by SwiftData
- **Performance**: Index creation happens during first app launch after update
- **Risk**: Very low - adding indexes is non-destructive

## Verification Checklist

- [ ] SchemaV12.swift created with @Index annotations
- [ ] Schema version set to (12, 0, 0)
- [ ] All models copied from V11 (no other changes)
- [ ] Type aliases added for all models
- [ ] MigrationPlan updated with SchemaV12
- [ ] Lightweight migration stage added
- [ ] ActiveSchema updated to V12
- [ ] Documentation updated
- [ ] Unit tests added
- [ ] Build succeeds
- [ ] Fresh install works
- [ ] Migration from V11 works

---

**Created**: 2025-12-26
**Issue**: GitHub #126
