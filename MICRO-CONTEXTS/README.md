# MICRO-CONTEXTS - Ultra-Efficient Context System

## 🎯 **Purpose**
Ultra-focused context cards (20-50 tokens each) for common development scenarios. Use these for 80-95% token savings vs full documentation.

## 📋 **Usage Guide**

### **Start Here for Any Task:**
1. **Read**: `quick-start.md` (50 tokens) - Essential project context
2. **Select**: Task-specific card based on what you're doing
3. **Expand**: Reference full CLAUDE.md/FEATURES.md only if needed

### **Card Selection Guide:**

| Your Task | Required Cards | Total Tokens |
|-----------|----------------|--------------|
| **New to project** | quick-start.md | 50 |
| **Adding features** | quick-start.md + architecture.md | 80 |
| **Performance issues** | quick-start.md + performance.md | 75 |
| **Bug fixes** | anti-patterns.md + debugging.md | 75 |
| **Testing** | testing.md + architecture.md | 50 |
| **Build problems** | build.md + debugging.md | 60 |

### **Card Descriptions:**

- **quick-start.md** (50 tokens) - Project essentials, tech stack, critical rules
- **architecture.md** (30 tokens) - Clean Architecture flow, DI patterns, layer rules
- **performance.md** (25 tokens) - N+1 fixes, threading, batch operations
- **testing.md** (20 tokens) - Testing framework, structure, patterns
- **build.md** (25 tokens) - Build commands, simulator requirements, configs
- **anti-patterns.md** (40 tokens) - Critical violations to avoid, user rejections
- **debugging.md** (35 tokens) - Common issues, troubleshooting steps

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
- **CLAUDE.md** - Complete development guide with all learnings
- **FEATURES.md** - Full feature documentation and roadmap
- **TASK-ROUTER.md** - Task type to context mappings

## ⚡ **Quick Reference**

```
New task? → quick-start.md (50 tokens)
Adding feature? → + architecture.md (30 tokens)  
Performance issue? → + performance.md (25 tokens)
Bug fixing? → anti-patterns.md + debugging.md (75 tokens)
Testing? → testing.md (20 tokens)
Build issue? → build.md + debugging.md (60 tokens)
```

**Total context for most tasks: 50-150 tokens vs 800-1000 tokens**