# MICRO-CONTEXTS - Ultra-Efficient Context System

## 🎯 **Purpose**
Ultra-focused context cards (20-50 tokens each) for common development scenarios. Use these for 80-95% token savings vs full documentation.

## 📋 **Usage Guide**

### **Start Here for Any Task:**
1. **Read**: `quick-start.md` (50 tokens) - Essential project context
2. **Route**: Use `task-router.md` (120 tokens) to identify required cards for your specific work
3. **Select**: Task-specific cards based on routing guidance
4. **Expand**: Reference full CLAUDE.md/FEATURES.md only if needed

### **Card Selection Guide:**

| Your Task | Required Cards | Total Tokens |
|-----------|----------------|--------------|
| **New to project** | quick-start.md | 50 |
| **Adding features** | quick-start.md + usecase-service-distinction.md + violation-detection.md | 235 |
| **Performance issues** | quick-start.md + performance.md | 75 |
| **Bug fixes** | anti-patterns.md + debugging.md | 95 |
| **Testing** | testing.md + testing-strategy.md | 110 |
| **Build problems** | build.md + debugging.md | 60 |

### **Card Descriptions:**

- **quick-start.md** (50 tokens) - Project essentials, tech stack, critical rules
- **task-router.md** (120 tokens) - MANDATORY routing guide for context selection
- **architecture.md** (40 tokens) - Clean Architecture flow, DI patterns, layer rules
- **usecase-service-distinction.md** (90 tokens) - Critical UseCase vs Service boundaries (project-analysis.md fix)
- **performance.md** (25 tokens) - N+1 fixes, threading, batch operations
- **testing.md** (35 tokens) - Testing framework, structure, patterns, NO MOCKS
- **testing-strategy.md** (75 tokens) - Detailed approach avoiding mocks (project-analysis.md fix)
- **build.md** (25 tokens) - Build commands, simulator requirements, configs
- **anti-patterns.md** (60 tokens) - Critical violations to avoid, user rejections, mock testing
- **debugging.md** (35 tokens) - Common issues, troubleshooting steps
- **violation-detection.md** (95 tokens) - Grep commands to detect architecture violations

## 🚀 **Benefits**

### **Token Efficiency:**
- **Before**: 800-1000 tokens to regain full context
- **After**: 50-150 tokens for most tasks
- **Savings**: 80-95% token reduction

### **Context Quality:**  
- **Laser-focused**: Only relevant information for current task
- **No noise**: Eliminates irrelevant details
- **Progressive**: Start minimal, expand as needed

## 📚 **When to Use Full Documentation**

**Use comprehensive docs when:**
- Deep architectural understanding needed
- Complex cross-feature integration required  
- Historical context of decisions matters
- Learning about completed initiatives in detail

**Comprehensive References:**
- **CLAUDE.md** - Complete development guide with all learnings (MUST read micro-contexts first!)
- **CLAUDE-COLLABORATION-GUIDE.md** - Interaction protocol with micro-context enforcement
- **task-router.md** - Task type to context mappings (START HERE for task routing)
- **project-analysis.md** - Architecture issues that micro-contexts address

## ⚡ **Quick Reference**

```
New task? → quick-start.md (50 tokens)
Adding feature? → + usecase-service-distinction.md + violation-detection.md (235 tokens)  
Performance issue? → + performance.md (25 tokens)
Bug fixing? → anti-patterns.md + debugging.md (95 tokens)
Testing? → testing.md + testing-strategy.md (110 tokens)
Build issue? → build.md + debugging.md (60 tokens)
```

**Total context for most tasks: 50-235 tokens vs 800-1000 tokens**