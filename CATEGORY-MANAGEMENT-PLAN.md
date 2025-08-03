# Category Management & Habits Filtering Implementation Plan

## Overview
This plan implements comprehensive category management and category-based filtering for habits. Users can manage their custom categories while viewing predefined ones as read-only, and filter habits by category in the main habits list.

---

## Phase 1: Category Management Screen

### 1.1 Create Category Management UI Components
- [x] Create `CategoryManagementView` - main screen with list of all categories
- [x] Create `CategoryRowView` - individual category row component  
- [x] Create `EditCategorySheet` - modal for editing custom categories (AddCategorySheet)
- [x] Handle different states: predefined (disabled) vs custom (editable)
- [x] Implement swipe actions for custom categories (edit, delete) - using native iOS edit mode
- [x] Add visual indicators for predefined vs custom categories

### 1.2 Category Management ViewModel
- [x] Create `CategoryManagementViewModel` with state management
- [x] Implement category loading (predefined + custom)
- [x] Add edit category functionality (name, emoji, order)
- [x] Add delete category functionality (custom only)
- [x] Add reorder categories functionality (native drag & drop)
- [x] Handle validation and error states

### 1.3 Additional UseCases
- [x] Create `UpdateCategoryUseCase` for editing existing categories
- [x] Create `DeleteCategoryUseCase` for removing custom categories
- [x] Create `GetPredefinedCategoriesUseCase` for predefined categories only
- [x] Create `GetCustomCategoriesUseCase` for custom categories only
- [ ] Create `ReorderCategoriesUseCase` for changing category order (handled in UpdateCategory)
- [x] Update existing UseCases to handle category modifications

### 1.4 Data Layer Updates
- [x] Add update/delete methods to `CategoryRepository`
- [x] Add update/delete methods to `CategoryLocalDataSourceProtocol`
- [x] Implement update/delete in `SwiftDataCategoryLocalDataSource`
- [x] Add `isPredefined` flag to Category entity and SDCategory model
- [x] Update CategoryMapper to handle isPredefined property
- [x] Add getCustomCategories method to all data sources
- [x] Handle cascading effects when deleting categories with associated habits

---

## Phase 2: Category Management Navigation

### 2.1 Entry Point from Add/Edit Habit
- [x] Add "Manage Categories" button to `CategorySelectionView`
- [x] Navigate to Category Management Screen
- [x] Handle return flow and category refresh

### 2.2 Entry Point from Habits List
- [x] Add settings/gear icon to habits list toolbar
- [x] Navigate to Category Management Screen from habits list
- [x] Handle return flow and category refresh

### 2.3 Navigation Setup
- [x] Add Category Management to navigation flow
- [x] Create `CategoryManagementDI` factory (added to SettingsFactory)
- [x] Update main app navigation structure

---

## Phase 3: Habits List Category Filtering

### 3.1 Category Carousel Component
- [x] Create `CategoryFilterCarousel` component
- [x] Implement horizontal scrolling category selector
- [x] Add "All" as first option (initially selected)
- [x] Display all categories (predefined + custom) as filter options
- [x] Handle category selection and visual feedback

### 3.2 Update HabitsViewModel
- [x] Add category filtering state to `HabitsViewModel`
- [x] Implement `selectedFilterCategory` property
- [x] Add `filteredHabits` computed property
- [x] Update habits loading to support filtering
- [x] Handle "All" selection (show all habits)

### 3.3 Update HabitsView
- [x] Add `CategoryFilterCarousel` to top of habits list
- [x] Wire up category selection to ViewModel
- [x] Update habits display to show filtered results
- [x] Ensure proper layout and spacing

### 3.4 Filtering Logic
- [x] Implement filtering logic in HabitsViewModel using existing UseCases
- [x] Use `GetAllCategoriesUseCase` for filter options
- [x] Handle edge cases (habits without categories, deleted categories)
- [x] Optimize performance for large habit lists
- [x] Note: No separate FilterUseCase needed - filtering done in ViewModel

---

## Phase 4: Category Deletion Handling

### 4.1 Cascading Effects
- [ ] Identify habits associated with deleted categories
- [ ] Implement strategy for orphaned habits (set categoryId to nil)
- [ ] Update UI to handle habits without categories
- [ ] Add confirmation dialogs for category deletion

### 4.2 Data Integrity
- [ ] Add validation before category deletion
- [ ] Show warning if category has associated habits
- [ ] Provide options: "Delete anyway" or "Cancel"
- [ ] Update habit filtering to handle null categories

---

## Phase 5: UI/UX Enhancements

### 5.1 Visual Design
- [x] Add distinct styling for predefined vs custom categories (secondary color + "Predefined" label)
- [x] Implement disabled state styling for predefined categories (no edit button, disabled delete)
- [x] Add appropriate icons and visual indicators (emoji display, edit buttons)
- [x] Ensure consistent design language across components (using native iOS patterns)

### 5.2 User Experience
- [x] Add empty states for category management (handled in List)
- [x] Implement loading states for category operations (ProgressView in VM)
- [x] Add success/error feedback for category actions (error handling in VM)
- [x] Implement proper keyboard handling and accessibility (@FocusState, proper labels)

### 5.3 Performance Optimization
- [x] Optimize category loading and filtering (Clean Architecture with specific UseCases)
- [x] Implement proper state management for real-time updates (@Observable ViewModel)
- [x] Add caching where appropriate (SwiftData handles persistence)
- [x] Ensure smooth animations and transitions (native iOS edit mode animations)

---

## Phase 6: Testing & Validation

### 6.1 Unit Tests
- [ ] Test category management ViewModels
- [ ] Test new UseCases (update, delete, getPredefined, getCustom)
- [ ] Test filtering logic and edge cases
- [ ] Test data integrity and cascading effects
- [ ] Test isPredefined flag handling across data layer

### 6.2 Integration Tests
- [ ] Test full category management flow
- [ ] Test navigation between screens
- [ ] Test category filtering in habits list
- [ ] Test data persistence and SwiftData integration

### 6.3 UI Tests
- [ ] Test category management screen interactions
- [ ] Test category carousel filtering
- [ ] Test navigation flows
- [ ] Test error states and edge cases

---

## Key Components Overview

### New Components:
- `CategoryManagementView` - Main category management screen
- `CategoryRowView` - Individual category row with edit/delete actions
- `EditCategorySheet` - Modal for editing category details
- `CategoryFilterCarousel` - Horizontal category filter for habits list
- `CategoryManagementViewModel` - State management for category operations

### New UseCases:
- `UpdateCategoryUseCase` - Edit existing categories ✅
- `DeleteCategoryUseCase` - Remove custom categories ✅
- `GetPredefinedCategoriesUseCase` - Get predefined categories only ✅
- `GetCustomCategoriesUseCase` - Get custom categories only ✅
- Note: Reordering handled via UpdateCategoryUseCase, filtering done in ViewModels

### Updated Components:
- `HabitsView` - Add category filtering carousel
- `HabitsViewModel` - Add filtering state and logic
- `CategorySelectionView` - Add navigation to management screen

### Implementation Notes:
- **Native iOS Edit Mode**: Used EditButton() with .onDelete() and .onMove() for better UX
- **isPredefined Flag**: Added to Category entity to distinguish predefined vs custom categories
- **Clean Architecture**: Complete separation with specific UseCases for different category types
- **DI Integration**: CategoryManagement wired into existing SettingsFactory

---

## Current Implementation Status

### ✅ COMPLETED - Phase 1: Category Management Screen (100%)
- **Architecture**: Complete Clean Architecture implementation with UseCases, Repositories, Data Sources
- **Data Layer**: Added `isPredefined` flag to distinguish predefined vs custom categories  
- **UI**: Native iOS edit mode with drag & drop reordering, swipe-to-delete, inline editing
- **ViewModels**: Complete state management with error handling and loading states
- **DI**: Integrated into existing SettingsFactory
- **Cascading Deletion**: Added `GetHabitsByCategoryUseCase` and `OrphanHabitsFromCategoryUseCase` to handle habits when categories are deleted

### ✅ COMPLETED - Phase 2: Category Management Navigation (100%)
- **Add/Edit Habit Entry**: Added "Manage Categories" button with gear icon to CategorySelectionView
- **Habits List Entry**: Added gear icon to toolbar in HabitsView for category management access
- **Navigation Flow**: Complete sheet presentation with proper DI factory integration and dismissal handling
- **State Management**: Added showingCategoryManagement to HabitsViewModel with proper handlers

### ✅ COMPLETED - Phase 3: Habits List Category Filtering (100%)
- **CategoryFilterCarousel Component**: Complete horizontal scrolling component with "All" option and category chips
- **ViewModel Integration**: Added category filtering state, filteredHabits computed property, and filter selection logic
- **UI Integration**: Integrated carousel at top of habits list with proper spacing and empty state handling
- **Smart Features**: Disabled reordering during filtering, category-aware empty states, manage categories access

### 📋 PENDING - Phases 4-6
- Category deletion handling with user confirmation
- Enhanced UX and testing

---

## Success Criteria

✅ **Category Management**: Users can view all categories, edit/delete custom ones, see predefined as read-only  
✅ **Navigation**: Easy access from both habit creation and habits list contexts  
✅ **Filtering**: Smooth category-based filtering in habits list with "All" default  
✅ **Data Integrity**: Proper handling of category deletion and associated habits  
✅ **Performance**: Fast loading and filtering even with many categories/habits  
✅ **UX**: Intuitive interface with clear visual distinctions and feedback

---

## Estimated Implementation

**Total estimated tasks: ~35 individual items**
**Complexity: Medium-High** (involves UI, state management, data operations, navigation)

This plan provides comprehensive category management while maintaining the existing architecture patterns and user experience consistency.