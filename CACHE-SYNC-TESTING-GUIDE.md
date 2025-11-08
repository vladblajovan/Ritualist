# Cache Sync Testing Guide (No Migration)

**Date**: 2025-11-08
**Goal**: Verify cache sync works correctly without involving migrations

---

## Debug Logging Added

I've added comprehensive logging to track cache behavior:

- `🔄 FULL RELOAD:` - Database reload happening
- `✅ CACHE SYNC:` - Cache update successful (no database reload)
- `⚡ CACHE HIT:` - Date navigation using cached data
- `🔄 RELOAD NEEDED:` - Date outside cache range, reloading
- `⚠️ CACHE MISS:` - No cache available

---

## Test 1: Basic Habit Completion (Cache Sync)

**Objective**: Verify completing habits uses cache sync instead of database reload

**Steps**:
1. Launch app and wait for initial load
   - **Expected**: `🔄 FULL RELOAD: Loading data from database`
   - **Expected**: `✅ FULL RELOAD: Loaded X habits, Y logs`

2. Complete a habit (tap checkmark)
   - **Expected**: `✅ CACHE SYNC: Added new log for habit [UUID]`
   - **NOT Expected**: `🔄 FULL RELOAD` (should NOT see this!)

3. Complete 5 more habits
   - **Expected**: 5x `✅ CACHE SYNC` messages
   - **NOT Expected**: Any `🔄 FULL RELOAD` messages

**Success Criteria**:
- ✅ UI updates instantly (no visible delay)
- ✅ Only see `CACHE SYNC` messages, no `FULL RELOAD`
- ✅ Habit completion counts update correctly

---

## Test 2: Numeric Habit Updates (Cache Sync)

**Objective**: Verify numeric habit value changes use cache sync

**Steps**:
1. Find a numeric habit (e.g., "Water intake")
2. Tap to open numeric input sheet
3. Enter a value (e.g., 5 cups)
4. Save

**Expected Console Output**:
```
✅ CACHE SYNC: Updated existing log for habit [UUID]
```
OR (if first log of the day):
```
✅ CACHE SYNC: Added new log for habit [UUID]
```

5. Change the value again (e.g., to 8 cups)
6. Save

**Expected**:
```
✅ CACHE SYNC: Updated existing log for habit [UUID]
```

**Success Criteria**:
- ✅ Value updates instantly
- ✅ No `FULL RELOAD` messages
- ✅ Progress bar updates correctly

---

## Test 3: Delete Habit Log (Cache Sync)

**Objective**: Verify deleting logs uses cache sync

**Steps**:
1. Complete a habit
2. Long-press or swipe to delete the completion
3. Confirm deletion

**Expected Console Output**:
```
✅ CACHE SYNC: Removed 1 log(s) for habit [UUID]
```

**Success Criteria**:
- ✅ Habit moves back to incomplete instantly
- ✅ No `FULL RELOAD` messages
- ✅ Progress updates correctly

---

## Test 4: Date Navigation Within Cache (Cache Hit)

**Objective**: Verify navigating within 30-day cache doesn't reload

**Steps - Method 1: Top Selector Arrows**:
1. On Overview tab, use date navigation arrows (< >)
2. Go back 1 day

**Expected Console Output**:
```
⚡ CACHE HIT: Date [date] within cached range
```

3. Go back another 5 days (total -6 days)

**Expected**:
```
⚡ CACHE HIT: Date [date] within cached range
```
(5 times)

4. Go forward 3 days

**Expected**:
```
⚡ CACHE HIT: Date [date] within cached range
```
(3 times)

**Steps - Method 2: Monthly Calendar Card**:
1. Scroll to Monthly Calendar Card
2. Tap on a date within the current month (should be in cache)

**Expected Console Output**:
```
⚡ CACHE HIT: Date [date] within cached range
```

3. Tap on another date in the same month

**Expected**:
```
⚡ CACHE HIT: Date [date] within cached range
```

**Success Criteria**:
- ✅ Navigation is instant (no loading) for both methods
- ✅ All navigations show `CACHE HIT`
- ✅ Data displays correctly for each date
- ✅ Monthly calendar taps don't trigger full reload (fixed issue)

---

## Test 5: Date Navigation Outside Cache (Selective Reload)

**Objective**: Verify navigating outside 30-day range triggers reload

**Setup**: App caches last 30 days from today

**Steps - Method 1: Top Selector Arrows**:
1. Navigate back 25 days (should be cache hits)
2. Navigate back 10 MORE days (total -35 days, outside cache)

**Expected Console Output**:
```
🔄 RELOAD NEEDED: Date [date] outside cached range
🔄 FULL RELOAD: Loading data from database
✅ FULL RELOAD: Loaded X habits, Y logs
```

**Steps - Method 2: Monthly Calendar Card**:
1. Scroll to Monthly Calendar Card
2. Navigate to previous month (if current month, go back 2 months)
3. Tap on a date from 2+ months ago (outside 30-day cache)

**Expected Console Output**:
```
🔄 RELOAD NEEDED: Date [date] outside cached range
🔄 FULL RELOAD: Loading data from database
✅ FULL RELOAD: Loaded X habits, Y logs
```

**Success Criteria**:
- ✅ First 25 days show `CACHE HIT` (arrow navigation)
- ✅ Day -35 triggers `RELOAD NEEDED` and `FULL RELOAD` (both methods)
- ✅ Data displays correctly after reload
- ✅ Monthly calendar handles out-of-range dates correctly (fixed issue)

---

## Test 6: Multiple Rapid Actions (Stress Test)

**Objective**: Verify cache handles rapid successive actions

**Steps**:
1. Quickly complete 10 different habits in succession
2. Watch console output

**Expected Pattern**:
```
✅ CACHE SYNC: Added new log for habit [UUID-1]
✅ CACHE SYNC: Added new log for habit [UUID-2]
✅ CACHE SYNC: Added new log for habit [UUID-3]
...
✅ CACHE SYNC: Added new log for habit [UUID-10]
```

**Success Criteria**:
- ✅ All 10 completions show `CACHE SYNC`
- ✅ No `FULL RELOAD` messages
- ✅ UI remains responsive
- ✅ All habits show as completed correctly

---

## Test 7: App Backgrounding and Resuming

**Objective**: Verify cache survives app backgrounding

**Steps**:
1. Complete 2 habits
2. Background the app (swipe up to home screen)
3. Wait 10 seconds
4. Resume the app
5. Complete 2 more habits

**Expected**:
- Initial completions: `✅ CACHE SYNC` (2x)
- After resume: `✅ CACHE SYNC` (2x)
- No `FULL RELOAD` unless app was fully terminated

**Success Criteria**:
- ✅ Cache persists across backgrounding
- ✅ No unnecessary reloads

---

## Test 8: Pull to Refresh (Intentional Reload)

**Objective**: Verify manual refresh still works

**Steps**:
1. Pull down on Overview screen to refresh
2. Watch console

**Expected Console Output**:
```
🔄 FULL RELOAD: Loading data from database
✅ FULL RELOAD: Loaded X habits, Y logs
```

**Success Criteria**:
- ✅ Manual refresh triggers full reload (expected behavior)
- ✅ Fresh data loads correctly

---

## Performance Validation

### Before Cache Sync (Expected Old Behavior)
- Completing 10 habits = 10 full database reloads
- Console shows: 10x `🔄 FULL RELOAD`

### After Cache Sync (Expected New Behavior)
- Completing 10 habits = 0 full database reloads
- Console shows: 10x `✅ CACHE SYNC`

**Reduction**: 100% elimination of unnecessary reloads

---

## Success Criteria Summary

✅ **All Tests Pass**:
1. Habit completions use cache sync
2. Numeric updates use cache sync
3. Deletions use cache sync
4. Date navigation within 30 days uses cache
5. Date navigation outside 30 days triggers selective reload
6. Rapid actions remain stable
7. Cache survives app backgrounding
8. Manual refresh still works

✅ **Console Logging Shows**:
- Initial app launch: 1x `FULL RELOAD`
- Habit actions: Only `CACHE SYNC` messages
- Date navigation (within range): Only `CACHE HIT` messages
- Date navigation (outside range): `RELOAD NEEDED` → `FULL RELOAD`

✅ **UI Behavior**:
- Instant updates for all actions
- No visible loading indicators for cached operations
- Correct data display across all scenarios

---

## What to Report

When testing, please report:

1. **✅ Pass** or **❌ Fail** for each test
2. Any unexpected console messages
3. Any UI glitches or incorrect data
4. Approximate timing (e.g., "instant" vs "noticeable delay")

---

## Phase 2: Migration-Aware Cache Testing

After confirming basic cache sync works, test migration handling:

### Test 9: Normal Migration Flow (Migration Start → Complete)

**Objective**: Verify cache invalidation when app witnesses full migration

**Setup**: Trigger a schema migration (V7 → V8)

**Steps**:
1. Keep app open during migration
2. Watch console for migration messages
3. After migration completes, complete a habit

**Expected Console Output**:
```
⏳ MIGRATION IN PROGRESS: Deferring data load until migration completes
🔄 Migration completed - invalidating cache
🔄 MIGRATION COMPLETED: Cache invalidated, proceeding with fresh load
🔄 FULL RELOAD: Loading data from database
✅ FULL RELOAD: Loaded X habits, Y logs
```

**Success Criteria**:
- ✅ No data loads during active migration
- ✅ Cache invalidated after migration completes
- ✅ Fresh data loaded after migration
- ✅ Habit actions work correctly with new schema

---

### Test 10: App Restart During Migration (Critical Edge Case)

**Objective**: Verify cache invalidation when ViewModel created after migration

**Scenario**: This tests the fix for the "initial state problem"

**Steps**:
1. Trigger migration
2. FORCE QUIT app during the 3-second completion delay
3. Reopen app immediately
4. Check Overview page

**Expected Console Output**:
```
🔄 FULL RELOAD: Loading data from database
✅ FULL RELOAD: Loaded X habits, Y logs
```

**Then complete a habit**:
```
✅ CACHE SYNC: Added new log for habit [UUID]
```

**Success Criteria**:
- ✅ App loads successfully after restart
- ✅ No stale cache issues
- ✅ Fresh data from database
- ✅ Cache sync works normally after restart

---

### Test 11: User Interaction During Completion Delay

**Objective**: Verify migration detection during 3-second completion window

**Steps**:
1. Trigger migration
2. Wait for migration modal to appear
3. Wait 1 second after migration completes (during 3-second delay)
4. Try to complete a habit

**Expected Console Output (First Action)**:
```
⏳ MIGRATION IN PROGRESS: Deferring data load until migration completes
```

**Expected After Delay Completes (Second Action)**:
```
🔄 MIGRATION COMPLETED: Cache invalidated, proceeding with fresh load
🔄 FULL RELOAD: Loading data from database
✅ CACHE SYNC: Added new log for habit [UUID]
```

**Success Criteria**:
- ✅ First action during delay is deferred
- ✅ Second action triggers cache invalidation
- ✅ No data corruption or crashes

---

### Test 12: Migration with Existing Cache

**Objective**: Verify stale cache is invalidated during migration

**Steps**:
1. Use app normally (build up cache with 30 days data)
2. Complete several habits (verify cache sync works)
3. Trigger migration
4. After migration completes, navigate dates

**Expected**:
```
🔄 Migration completed - invalidating cache
🔄 MIGRATION COMPLETED: Cache invalidated, proceeding with fresh load
🔄 FULL RELOAD: Loading data from database
✅ FULL RELOAD: Loaded X habits, Y logs (with new schema)
```

**Success Criteria**:
- ✅ Old cache discarded
- ✅ New cache built with migrated schema
- ✅ No schema mismatch errors

---

### Test 13: Multiple Migrations (Edge Case)

**Objective**: Verify cache handles rapid migration detection

**Setup**: If testing V6 → V7 → V8 migrations

**Expected**:
- Each migration triggers cache invalidation
- No race conditions between migrations
- Cache rebuilds correctly after final migration

---

## Migration Testing Summary

**Critical Scenarios Covered**:
1. ✅ Normal migration flow (app stays open)
2. ✅ App restart during migration (ViewModel created after)
3. ✅ User interaction during completion delay
4. ✅ Stale cache invalidation
5. ✅ Multiple sequential migrations

**Console Messages to Watch**:
- `⏳ MIGRATION IN PROGRESS` - Data load deferred
- `🔄 Migration completed - invalidating cache` - Detection triggered
- `🔄 MIGRATION COMPLETED` - Cache invalidated, ready for fresh load
- `🔄 FULL RELOAD` - Loading with new schema

---

**Status**: Migration detection fix implemented
**Build Required**: Yes (recompile with migration guard)
**Next**: Test Phase 2 migration scenarios
