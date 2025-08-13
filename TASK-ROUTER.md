# TASK-ROUTER.md - Context Selection Guide

Quick reference for selecting the right micro-contexts based on your task type.

## 🎯 **Task Type → Required Context**

### **New to Project**
**Read**: `MICRO-CONTEXTS/quick-start.md` (50 tokens)
**Total**: 50 tokens

### **Feature Development**
**Read**: `quick-start.md` + `architecture.md` + `testing.md`
**Total**: 100 tokens (50 + 30 + 20)

### **Bug Fixes** 
**Read**: `anti-patterns.md` + `debugging.md` + `architecture.md`
**Total**: 105 tokens (40 + 35 + 30)

### **Performance Issues**
**Read**: `quick-start.md` + `performance.md` + `architecture.md`
**Total**: 105 tokens (50 + 25 + 30)

### **Testing Tasks**
**Read**: `testing.md` + `architecture.md`
**Total**: 50 tokens (20 + 30)

### **Build/Deploy Issues**
**Read**: `build.md` + `debugging.md` + `quick-start.md`
**Total**: 110 tokens (25 + 35 + 50)

### **Code Review**
**Read**: `anti-patterns.md` + `architecture.md` + `performance.md`
**Total**: 95 tokens (40 + 30 + 25)

## 📊 **Token Efficiency Comparison**

| Task Scenario | Micro-Context Cards | Full Documentation | Savings |
|---------------|-------------------|-------------------|---------|
| Quick bug fix | 105 tokens | 800+ tokens | 87% |
| Feature development | 100 tokens | 1000+ tokens | 90% |
| Testing setup | 50 tokens | 800+ tokens | 94% |
| Build troubleshooting | 110 tokens | 800+ tokens | 86% |
| Performance optimization | 105 tokens | 800+ tokens | 87% |

## 🚀 **When to Use Full Documentation**

**Still need comprehensive docs for:**
- Complex architectural decisions requiring historical context
- Deep dives into completed initiatives and their rationale
- Understanding personality analysis algorithm details  
- Learning about build configuration system architecture
- Cross-feature integration and dependency management

**Comprehensive References:**
- `CLAUDE.md` - Master development guide (464 lines)
- `FEATURES.md` - Complete feature documentation (371 lines)
- `ARCHITECTURE-CODE-ANALYSIS.md` - Detailed architectural assessment
- `TESTING-STRATEGY.md` - Comprehensive testing methodology