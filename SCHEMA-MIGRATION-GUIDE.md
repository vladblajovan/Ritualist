# 🔄 **RITUALIST SCHEMA MIGRATION GUIDE**

## 🚀 **NEW: Build-Time Detection & Runtime Progress**

### **Build-Time Detection**
When you run your app in DEBUG mode, you'll now see console output like this:

```
🔍 [Schema Detection] Checking for model changes requiring new migration...
✅ [Schema Detection] Models match latest schema - no migration needed
📋 [Schema Detection] Current schema version: V1
🔍 [Schema Detection] Complete
```

Or if you've made changes:

```
🔍 [Schema Detection] Checking for model changes requiring new migration...
🚨 [Schema Detection] NEW MODELS DETECTED:
   ➕ SDHabitStreak
🎯 ACTION REQUIRED: Add to new schema version
📋 [Schema Detection] Current schema version: V1
📖 [Schema Detection] Need help? See SCHEMA-MIGRATION-GUIDE.md
🔍 [Schema Detection] Complete
```

### **Runtime Migration Progress**
Users will see a beautiful migration UI with progress updates handled by the dedicated `DatabaseMigrationCoordinator`:

![Migration UI showing progress bar and status updates]

**Architecture:**
```swift
// DatabaseMigrationCoordinator (singleton service)
@StateObject private var migrationCoordinator = Container.shared.databaseMigrationCoordinator()

// Automatic migration check and UI
.task {
    await migrationCoordinator.checkAndPerformMigration()
}

// Clean separation: migration logic is separate from navigation/UI logic
if migrationCoordinator.migrationState.isMigrating {
    MigrationProgressView(state: migrationCoordinator.migrationState)
}
```

**Benefits of Extracted Architecture:**
- ✅ **Separation of Concerns**: Migration logic separate from UI navigation
- ✅ **Reusability**: Migration coordinator can be used in tests, other views
- ✅ **Clean Architecture**: Single responsibility for each component
- ✅ **Dependency Injection**: Fully integrated with DI container
- ✅ **Testability**: Easy to mock and test migration flows

> **Purpose**: Safe database schema evolution without data loss  
> **Status**: V1.0 Production Ready  
> **Next Review**: When adding new model properties or relationships

---

## 📊 **CURRENT SCHEMA VERSION**

**Version**: `PersistenceSchemaV1` (1.0.0)  
**Models**: 6 core models with proper @Relationship attributes  
**Status**: ✅ Production ready with versioned migration support

### **Schema V1.0 Models:**
1. **SDHabit** - Core habit tracking with relationships
2. **SDHabitLog** - Daily completion records  
3. **SDCategory** - Habit categorization
4. **SDUserProfile** - User settings and subscription
5. **SDOnboardingState** - App onboarding flow state
6. **SDPersonalityProfile** - AI personality analysis data

---

## 🔧 **MIGRATION ARCHITECTURE**

### **Current Implementation:**
```swift
// PersistenceContainer.swift
container = try ModelContainer(
    for: PersistenceSchemaV1.self,
    migrationPlan: PersistenceMigrationPlan.self
)
```

### **Migration Plan Structure:**
- **Versioned Schemas**: Each schema version is explicitly defined
- **Migration Stages**: Stepwise transformations between versions  
- **Rollback Safety**: Each migration can be tested and validated
- **Data Preservation**: No data loss during schema changes

---

## 📋 **ADDING NEW SCHEMA VERSIONS**

### **When You Need a New Schema Version:**
- ✅ Adding new model properties
- ✅ Adding new models
- ✅ Changing property types
- ✅ Modifying relationships
- ✅ Removing deprecated properties

### **Step-by-Step Migration Process:**

#### **1. Create New Schema Version**
```swift
// Add to PersistenceSchema.swift
public enum PersistenceSchemaV2: VersionedSchema {
    public static var versionIdentifier = Schema.Version(2, 0, 0)
    
    public static var models: [any PersistentModel.Type] {
        [
            SDHabit.self,        // Modified model
            SDHabitLog.self,     // Unchanged model
            SDNewModel.self,     // New model
            // ... other models
        ]
    }
    
    @Model
    public final class SDHabit: @unchecked Sendable {
        // Existing properties...
        public var newProperty: String = "defaultValue"  // New property with default
        
        // Modified relationships...
    }
}
```

#### **2. Update Migration Plan**
```swift
public enum PersistenceMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            PersistenceSchemaV1.self,
            PersistenceSchemaV2.self  // Add new version
        ]
    }
    
    public static var stages: [MigrationStage] {
        [migrateV1toV2]  // Add migration stage
    }
}
```

#### **3. Define Migration Logic**
```swift
public static let migrateV1toV2 = MigrationStage.custom(
    fromVersion: PersistenceSchemaV1.self,
    toVersion: PersistenceSchemaV2.self,
    willMigrate: { context in
        print("🔄 Starting migration V1 → V2")
        // Pre-migration validation
    },
    didMigrate: { context in
        print("✅ Completed migration V1 → V2")
        
        // Set default values for new properties
        let habits = try context.fetch(FetchDescriptor<PersistenceSchemaV2.SDHabit>())
        for habit in habits {
            if habit.newProperty.isEmpty {
                habit.newProperty = "migrated_default"
            }
        }
        try context.save()
    }
)
```

#### **4. Test Migration Thoroughly**
- ✅ Test with empty database
- ✅ Test with populated database  
- ✅ Test migration rollback scenarios
- ✅ Verify all relationships work correctly
- ✅ Test app functionality after migration

---

## 🧪 **MIGRATION TESTING STRATEGY**

### **Before Release:**
```swift
// Create test databases with V1 data
// Run migration to V2
// Verify data integrity
// Test app functionality
```

### **Migration Validation Checklist:**
- [ ] All existing data preserved
- [ ] New properties have correct default values
- [ ] Relationships function correctly
- [ ] No orphaned data created
- [ ] App launches successfully
- [ ] Core functionality works
- [ ] Performance impact acceptable

---

## ⚠️ **MIGRATION BEST PRACTICES**

### **✅ DO:**
- Always add default values for new properties
- Test migrations with real data
- Use descriptive migration stage names
- Log migration progress
- Handle edge cases gracefully
- Keep migration stages small and focused

### **❌ DON'T:**
- Remove properties without migration logic
- Change property types without data conversion
- Create breaking relationship changes
- Skip migration testing
- Create circular migration dependencies

---

## 🔮 **FUTURE CONSIDERATIONS**

### **CloudKit Compatibility (P2):**
When implementing CloudKit sync:
- Remove `@Attribute(.unique)` from ID properties
- Add default values to all properties
- Make all relationships optional
- Test sync behavior with migrations

### **Schema V2 Candidates:**
- Habit streak calculation improvements
- Enhanced personality analysis data
- New notification preferences
- Advanced habit scheduling options

---

## 🚨 **EMERGENCY MIGRATION ROLLBACK**

### **If Migration Fails in Production:**
1. **Immediate**: Revert to previous app version
2. **Diagnose**: Identify migration failure cause
3. **Fix**: Update migration logic
4. **Test**: Thoroughly test corrected migration
5. **Deploy**: Release fixed version

### **Rollback Prevention:**
- Extensive testing before release
- Gradual rollout to catch issues early  
- Database backups before major migrations
- Monitoring migration success rates

---

## 📝 **SCHEMA CHANGE LOG**

### **V1.0.0** (Current)
- **Date**: August 2025
- **Changes**: Initial versioned schema implementation
- **Models**: All 6 core models with @Relationship attributes
- **Migration**: None (initial version)
- **Status**: ✅ Production ready

### **Future Versions:**
- **V2.0.0**: TBD - Next major model changes
- **V1.1.0**: TBD - Minor property additions

---

**💡 Remember**: Schema migrations are permanent. Once released, they become part of your app's migration chain forever. Plan carefully and test thoroughly!