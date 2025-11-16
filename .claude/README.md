# Claude Code Configuration for ShamelaGPT

This directory contains Claude Code configuration and reference files for the ShamelaGPT dual-platform project.

## 📋 Quick Start

**New to this project? Start here:**
- 👉 **[QUICK_START.md](./QUICK_START.md)** - TL;DR guide with essential rules and quick decision trees

## 📚 Reference Documentation

### Configuration Files

#### `settings.local.json`
Claude Code settings for this project including:
- **Permissions**: Pre-approved commands for building Android (Gradle) and iOS (Xcode) apps
- **Hooks**: Automatic reminder to check cross-platform guidelines before making changes

### Best Practices & Guidelines

#### `cross-platform-instructions.md` ⭐ PRIMARY REFERENCE
**CRITICAL REFERENCE FILE** - Comprehensive guidelines for maintaining both Android and iOS apps in sync.

**Contents:**
- Cross-platform development workflow
- Platform equivalents guide (Compose ↔ SwiftUI, Kotlin ↔ Swift)
- Architecture maintenance (MVVM pattern)
- Code discovery workflow
- Reuse vs. create decision guidelines
- API integration best practices
- UI/UX consistency guidelines
- Architectural patterns & anti-patterns (with code examples)
- Code reusability checklist
- Common pitfalls to avoid
- Quick reference commands

#### `IMPLEMENTATION_GUIDE.md` ⭐ DECISION TREES
Real-world examples and decision trees for common scenarios.

**Contents:**
- "Should I create a new file?" decision tree
- "Where does this code belong?" decision tree
- Real-world implementation examples (good vs. bad)
- Common scenarios and solutions
- Implementation workflow template
- Quick reference table: when to reuse vs. create

#### `FEATURE_CHECKLIST.md`
Template checklist for implementing features across both platforms.

**Use this when:**
- Implementing new features
- Making significant changes
- Need a systematic approach

**Contents:**
- Pre-implementation checklist
- Android implementation steps
- iOS implementation steps
- Cross-platform validation
- Testing checklist
- Documentation checklist
- Code quality checks

#### `QUICK_START.md`
Quick reference guide with the most essential information.

**Contents:**
- Critical rules (TL;DR)
- Quick decision guide
- Essential search patterns
- Project structure overview
- Common tasks guide
- Pro tips

## 🎯 How to Use These Files

### For Any New Task:
1. **Start with**: [QUICK_START.md](./QUICK_START.md) - Get oriented
2. **Reference**: [cross-platform-instructions.md](./cross-platform-instructions.md) - Detailed guidelines
3. **Examples**: [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) - See real examples
4. **Track**: [FEATURE_CHECKLIST.md](./FEATURE_CHECKLIST.md) - Use as a checklist

### For Specific Scenarios:
- **"Should I create a new file?"** → [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) - Decision tree
- **"What layer does this belong in?"** → [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) - Layer decision tree
- **"How do I maintain architecture?"** → [cross-platform-instructions.md](./cross-platform-instructions.md) - Architecture section
- **"What's the equivalent iOS code?"** → [cross-platform-instructions.md](./cross-platform-instructions.md) - Platform equivalents table

## 🔧 How It Works

When you submit a prompt to Claude Code in this project, a hook automatically reminds Claude to:
1. Check if the request involves code changes
2. Read the cross-platform instructions if applicable
3. Apply changes to BOTH platforms when implementing features or fixes

## 🎨 File Organization

```
.claude/
├── README.md                          # This file - Overview
├── settings.local.json                # Claude Code configuration
├── QUICK_START.md                     # Quick reference (START HERE)
├── cross-platform-instructions.md     # Comprehensive best practices
├── IMPLEMENTATION_GUIDE.md            # Decision trees & examples
└── FEATURE_CHECKLIST.md              # Feature implementation template
```

## 💡 For Developers

### Adding New Best Practices
Edit [cross-platform-instructions.md](./cross-platform-instructions.md) to add new guidelines, equivalents, or architectural patterns.

### Adding New Examples
Edit [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) to add real-world examples or new decision trees.

### Modifying Hooks
Edit [settings.local.json](./settings.local.json) to change hook behavior or add new automation.

### Pre-approved Commands
The following commands are pre-approved and won't require confirmation:
- `xcodebuild` (iOS builds)
- `./gradlew clean`, `./gradlew build`, `./gradlew assembleDebug`, `./gradlew lintDebug` (Android builds)
- `tee` (for logging/output redirection)

## 🚨 Critical Reminders

1. **BOTH PLATFORMS**: This is ONE project with TWO platforms (Android + iOS)
2. **SEARCH FIRST**: Always search for existing code before creating new files
3. **REUSE CODE**: Extend existing classes, don't duplicate
4. **FOLLOW MVVM**: Maintain the architectural pattern
5. **TEST BOTH**: Verify changes work on both platforms

## 📖 Quick Reference Links

| What you need | Where to find it |
|---------------|------------------|
| Quick overview | [QUICK_START.md](./QUICK_START.md) |
| Detailed best practices | [cross-platform-instructions.md](./cross-platform-instructions.md) |
| Decision trees | [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) |
| Feature checklist | [FEATURE_CHECKLIST.md](./FEATURE_CHECKLIST.md) |
| Platform equivalents | [cross-platform-instructions.md](./cross-platform-instructions.md#platform-equivalents-guide) |
| Code examples | [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md#real-world-implementation-examples) |
| Anti-patterns | [cross-platform-instructions.md](./cross-platform-instructions.md#architectural-patterns--anti-patterns) |

---

**Remember**: Search → Reuse → Both Platforms → Test!
