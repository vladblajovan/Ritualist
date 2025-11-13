# Documentation Reorganization Proposal

**Date**: November 13, 2025
**Branch**: `chore/documentation-cleanup`
**Current Files**: 50 markdown files
**Goal**: Industry-standard documentation structure

---

## 🎯 Objectives

1. **Discoverability** - Easy to find relevant documentation
2. **Maintainability** - Clear ownership and lifecycle management
3. **Scalability** - Structure supports growth
4. **Standards Compliance** - Follow industry best practices (GitHub, Microsoft, Google)
5. **Audience Segmentation** - Separate concerns for different readers

---

## 🏗️ Proposed Structure

Based on successful patterns from Microsoft, Google, Rust, and React projects:

```
/
├── README.md                          # Project overview (keep)
├── CHANGELOG.md                       # Version history (keep)
├── CONTRIBUTING.md                    # How to contribute (NEW)
├── LICENSE                            # License file
│
├── .github/                           # GitHub-specific files
│   ├── pull_request_template.md      # PR template (keep)
│   └── PROJECT_BOARD_SETUP.md        # Keep
│
├── MICRO-CONTEXTS/                    # Quick reference cards (UNCHANGED)
│   └── ... (all 11 files)
│
├── plans/                             # Active roadmap (UNCHANGED)
│   └── testing-infrastructure/
│       └── phase-1-audits/
│
└── docs/                              # Main documentation hub
    ├── README.md                      # Documentation index (NEW)
    │
    ├── guides/                        # How-to tutorials
    │   ├── setup/
    │   ├── development/
    │   └── features/
    │
    ├── architecture/                  # Architecture decisions
    │   ├── decisions/                 # ADRs
    │   └── analysis/
    │
    ├── reference/                     # Technical reference
    │   ├── performance/
    │   ├── versioning/
    │   └── features/
    │
    ├── planning/                      # Future proposals
    │   ├── features/
    │   ├── ux/
    │   └── infrastructure/
    │
    ├── troubleshooting/               # Problem-solving
    ├── migration-guides/              # Version migrations
    ├── ai-collaboration/              # Claude-specific
    └── maintenance/                   # Cleanup reports
```

---

## 📋 Key Principles

1. **Separation by Purpose**: guides (how-to), reference (what is), planning (future), architecture (why)
2. **Consistent Naming**: lowercase-with-hyphens (no UPPERCASE)
3. **Index Files**: README.md in each folder
4. **Architecture Decision Records**: Documented decisions in `architecture/decisions/`
5. **Clean Root**: Maximum 5 files in repository root

---

## 🚀 Implementation

### Phase 1: Create directory structure
### Phase 2: Create index files (README.md)
### Phase 3: Move files with `git mv` (preserve history)
### Phase 4: Rename to consistent format
### Phase 5: Update internal links
### Phase 6: Create Architecture Decision Records

**Estimated Time**: ~1 hour

---

## ✅ Success Criteria

- [ ] Root directory has ≤5 files
- [ ] All docs in single `docs/` tree
- [ ] Consistent lowercase-hyphen naming
- [ ] README.md in each docs/ subfolder
- [ ] All links updated
- [ ] No duplicate content

---

**Status**: Approved ✅
**Next**: Execute reorganization
