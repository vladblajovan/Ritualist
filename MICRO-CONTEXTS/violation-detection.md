# Violation Detection (95 tokens)

**Run BEFORE implementing features to detect architecture violations:**

**Direct Service Injection in ViewModels (❌ CRITICAL):**
```bash
grep -r "@Injected.*Service" Ritualist/Features/*/Presentation/ --include="*ViewModel.swift"
```

**Direct Repository Access (❌):**
```bash
grep -r "\.habitRepository\|\.logRepository" Ritualist/Features/ --include="*.swift"
```

**Cross-Feature Dependencies (❌):**
```bash
grep -r "Factory\(" Ritualist/Features/ --include="*.swift" --exclude-dir=*/Shared/*
```

**UseCase Bypass (❌):**
```bash
# ViewModels should only call UseCases, not Services/Repositories
grep -r "\.execute\|\.create\|\.update\|\.delete" Ritualist/Features/*/Presentation/ --include="*ViewModel.swift" | grep -v "UseCase"
```

**✅ CORRECT:** Views → ViewModels → UseCases → [Services + Repositories]

## ✅ **CURRENT STATUS - ZERO CRITICAL VIOLATIONS (27.08.2025)**

**Service Injections in ViewModels:** 4 remaining (all legitimate utilities)
- `userService` (2x) - User profile access utility ✅
- `widgetRefreshService` - Widget refresh utility ✅  
- `debugService` - Debug operations utility ✅

**Direct Repository Access:** 0 critical violations ✅
- Only Services and Repository implementations access Repositories ✅

**Cross-Feature Dependencies:** 0 violations ✅

**UseCase Bypass:** 0 violations ✅
- All ViewModel execute() calls are on UseCase instances ✅