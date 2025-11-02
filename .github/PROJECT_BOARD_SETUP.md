# GitHub Project Board Setup Guide

This guide explains how to set up a GitHub Project board for tracking features, bugs, and tasks.

## Creating the Project

### Quick Setup (Recommended)

1. Go to your repository: **Projects** tab
2. Click **New project**
3. Choose **Board** template
4. Name: `Ritualist Development`
5. Click **Create project**

### Advanced Setup (Custom Workflow)

1. Go to your repository: **Projects** tab
2. Click **New project** → **Start from scratch**
3. Name: `Ritualist Development`
4. Choose **Board** view
5. Click **Create project**

## Configuring the Board

### Default Columns

Set up these columns for a standard Kanban workflow:

1. **📋 Backlog** - Ideas and future work
2. **📝 To Do** - Ready to be worked on
3. **🚧 In Progress** - Currently being developed
4. **👀 In Review** - Pull request created, awaiting review
5. **✅ Done** - Completed and merged

### Custom Fields (Optional but Recommended)

Add these fields to track more context:

**Priority Field:**
- Field name: `Priority`
- Type: Single select
- Options: `🔴 Critical`, `🟠 High`, `🟡 Medium`, `🟢 Low`

**Size/Effort Field:**
- Field name: `Size`
- Type: Single select
- Options: `XS` (< 1 hour), `S` (1-4 hours), `M` (1-2 days), `L` (3-5 days), `XL` (> 1 week)

**Type Field:**
- Field name: `Type`
- Type: Single select
- Options: `🐛 Bug`, `✨ Feature`, `🔧 Refactor`, `📚 Docs`, `⚡ Performance`

**Sprint Field** (if using sprints):
- Field name: `Sprint`
- Type: Iteration
- Duration: 2 weeks

## Automation Rules

GitHub Projects supports automation to reduce manual work:

### Auto-move to In Progress
**Trigger:** Pull request linked to issue
**Action:** Move to "In Progress"

### Auto-move to In Review
**Trigger:** Pull request created
**Action:** Move to "In Review"

### Auto-move to Done
**Trigger:** Pull request merged
**Action:** Move to "Done"

### Auto-add Issues
**Trigger:** Issue created in repository
**Action:** Add to "Backlog" column

## Setting Up Automation

1. In your project, click **⋯** (three dots) → **Workflows**
2. Enable **Item added to project** workflow:
   - When: Issue or pull request added
   - Then: Set status to "Backlog"

3. Enable **Pull request merged** workflow:
   - When: Pull request merged
   - Then: Set status to "Done"

4. Create custom workflow for "In Progress":
   - When: Pull request opened or issue has PR linked
   - Then: Set status to "In Progress"

## Issue Templates for Easy Creation

Create issue templates that automatically populate project fields:

### Bug Report Template (`.github/ISSUE_TEMPLATE/bug_report.yml`)

```yaml
name: Bug Report
description: File a bug report
title: "[Bug]: "
labels: ["bug"]
projects: ["vladblajovan/1"]  # Your project number
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to fill out this bug report!

  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: Describe the bug
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
      description: What did you expect to happen?
    validations:
      required: true
```

### Feature Request Template (`.github/ISSUE_TEMPLATE/feature_request.yml`)

```yaml
name: Feature Request
description: Suggest a new feature
title: "[Feature]: "
labels: ["enhancement"]
projects: ["vladblajovan/1"]  # Your project number
body:
  - type: markdown
    attributes:
      value: |
        Thanks for suggesting a new feature!

  - type: textarea
    id: problem
    attributes:
      label: Problem to solve
      description: What problem does this feature solve?
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Proposed solution
      description: How would this feature work?
    validations:
      required: true
```

## Using the Project Board

### Creating Tasks

**From Issues:**
1. Click **New issue** in your repository
2. Fill out the issue template
3. Issue automatically appears in Backlog

**From Project:**
1. Click **+** in any column
2. Create a draft issue
3. Convert to issue when ready

### Linking Pull Requests

In your PR description, add:
```markdown
Closes #123
Fixes #456
Resolves #789
```

PRs will automatically link to issues and move through the board.

### Filtering and Views

Create custom views for different perspectives:

**My Work View:**
- Filter: `assignee:@me`
- Group by: Status

**Current Sprint View:**
- Filter: `sprint:"Sprint 1"`
- Group by: Status

**Priority View:**
- Filter: `priority:"High" or priority:"Critical"`
- Sort by: Priority

## Best Practices

1. **Keep it updated** - Move cards as work progresses
2. **Add details** - Use descriptions, labels, and custom fields
3. **Link PRs** - Always link PRs to issues
4. **Review regularly** - Weekly grooming of backlog
5. **Archive done items** - Keep the board clean

## Quick Start Checklist

- [ ] Create project board with Board template
- [ ] Set up 5 standard columns (Backlog, To Do, In Progress, In Review, Done)
- [ ] Add custom fields (Priority, Size, Type)
- [ ] Enable automation workflows
- [ ] Create issue templates (optional)
- [ ] Add existing issues to board
- [ ] Start using it!

## References

- [GitHub Projects Documentation](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
- [Project Automation](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project)
- [Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests)
