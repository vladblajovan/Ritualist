# Habit Categories & Suggestions Implementation Plan

## Overview
This plan implements the `addedFromSuggestion: Bool` field for habits and comprehensive category management system to simplify habit-suggestion mapping and enable custom categories.

---

## Phase 1: Core Data Model Changes

### 1.1 Update Habit Entity
- [x] Add `addedFromSuggestion: Bool` field to Habit entity
- [x] Add `categoryId: String?` field to Habit entity
- [x] Update Habit initializers and methods

### 1.2 Update SwiftData Model (SDHabit)
- [x] Add `addedFromSuggestion: Bool` to SDHabit model
- [x] Add `categoryId: String?` to SDHabit model
- [x] Handle SwiftData migration if needed

### 1.3 Update Habit Repository & Mappers
- [x] Update HabitMapper to handle new fields
- [x] Update HabitRepository create/update methods
- [x] Update all habit creation flows to include new fields

---

## Phase 2: Category Management System

### 2.1 Enhance Category Repository
- [x] Add `createCustomCategory` method to CategoryRepository
- [x] Add `categoryExists` method to CategoryRepository
- [x] Update repository to handle both predefined and custom categories
- [x] Add persistence for custom categories

### 2.2 Create Category UseCases
- [x] Create `CreateCustomCategoryUseCase`
- [x] Create `GetAllCategoriesUseCase` (predefined + custom)
- [x] Create `ValidateCategoryNameUseCase`
- [x] Update existing category UseCases as needed

---

## Phase 3: Habits Assistant Improvements

### 3.1 Simplify HabitsAssistantViewModel
- [x] Remove complex `GetExistingHabitSuggestionMappingsUseCase`
- [x] Implement simple query: `habits.filter { $0.addedFromSuggestion && suggestionIds.contains($0.categoryId) }`
- [x] Update ViewModel to use new simplified logic
- [x] Remove old mapping methods

### 3.2 Update Habit Creation from Suggestions
- [x] Set `addedFromSuggestion = true` when creating from suggestions
- [x] Set `categoryId` from suggestion when creating habits
- [x] Update tracking and analytics for suggestion-based habits

---

## Phase 4: Habit Creation/Edit UI

### 4.1 Create Category Selection Component
- [x] Create reusable CategorySelectionView component
- [x] Implement HorizontalCarousel for existing categories
- [x] Add "Add Custom Category" option
- [x] Create custom category input modal/sheet

### 4.2 Update Habit Creation Flow
- [x] Add category selection step to habit creation
- [x] Handle both predefined and custom categories
- [x] Update habit creation validation
- [x] Update UI/UX for category selection

### 4.3 Update Habit Edit Flow
- [x] Show category in habit edit (read-only if `addedFromSuggestion = true`)
- [x] Allow category change if `addedFromSuggestion = false`)
- [x] Update habit edit validation
- [x] Handle category updates properly

---

## Phase 5: Cleanup Old Logic

### 5.1 Remove Old Mapping Logic
- [x] Delete `GetExistingHabitSuggestionMappingsUseCase` file
- [x] Clean up HabitsAssistantViewModel old methods
- [x] Remove unused mapping-related code
- [x] Update tests to reflect new logic

---

## Phase 6: Testing & Validation

### 6.1 Unit Tests
- [ ] Test new Habit entity fields
- [ ] Test category creation and validation
- [ ] Test simplified habits assistant logic
- [ ] Test data migration logic

### 6.2 Integration Tests
- [ ] Test habit creation from suggestions
- [ ] Test custom category creation flow
- [ ] Test habit editing with categories
- [ ] Test category persistence

### 6.3 UI Tests
- [ ] Test category selection in habit creation
- [ ] Test custom category creation flow
- [ ] Test habit edit category restrictions
- [ ] Test habits assistant simplified flow

---

## Benefits of This Implementation

✅ **Much simpler logic** - no complex name matching  
✅ **Scalable** - works with any number of suggestions  
✅ **User-friendly** - clear category management  
✅ **Flexible** - supports custom categories  
✅ **Data integrity** - explicit relationship between habits and suggestions  
✅ **Better UX** - clear distinction between suggested and custom habits  
✅ **Maintainable** - explicit fields instead of inference logic

---

## Implementation Notes

- Start with Phase 1 to establish the data foundation
- Phase 2 builds the category management infrastructure
- Phase 3 simplifies existing complex logic
- Phase 4 implements user-facing features
- Phase 5 handles migration and cleanup
- Phase 6 ensures quality and stability

**Total estimated tasks: ~30 individual items**

## Note: Pre-Release Implementation
Since the app hasn't been released yet, we can skip data migration concerns and focus on implementing the features directly with the new data model.