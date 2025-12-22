# Ritualist Legal Documents - GitHub Pages Setup

This folder contains the legal documents for the Ritualist iOS app, ready to be hosted on GitHub Pages.

## Files

| File | Purpose |
|------|---------|
| `index.html` | Landing page |
| `privacy.html` | Privacy Policy |
| `terms.html` | Terms of Service |

---

## Setup Instructions

### Step 1: Create the Repository

1. Go to [GitHub](https://github.com/new)
2. Create a new **public** repository named: `ritualist-legal`
3. Do NOT initialize with README, .gitignore, or license

### Step 2: Upload the Files

After creating the repository, run these commands in terminal:

```bash
# Navigate to the docs-site folder
cd /Users/vladblajovan/Developer/GitHub/Ritualist/docs-site

# Initialize git and push to your new repo
git init
git add .
git commit -m "Initial commit: Privacy Policy and Terms of Service"
git branch -M main
git remote add origin https://github.com/vladblajovan/ritualist-legal.git
git push -u origin main
```

### Step 3: Enable GitHub Pages

1. Go to your repository: `https://github.com/vladblajovan/ritualist-legal`
2. Click **Settings** (gear icon)
3. In the left sidebar, click **Pages**
4. Under "Build and deployment":
   - Source: `Deploy from a branch`
   - Branch: `main`
   - Folder: `/ (root)`
5. Click **Save**

### Step 4: Verify

After a few minutes, your pages will be live at:

- **Landing Page:** https://vladblajovan.github.io/ritualist-legal/
- **Privacy Policy:** https://vladblajovan.github.io/ritualist-legal/privacy.html
- **Terms of Service:** https://vladblajovan.github.io/ritualist-legal/terms.html

---

## App Integration

The Ritualist app's Settings view links to these URLs:

```swift
// Privacy Policy
"https://vladblajovan.github.io/ritualist-legal/privacy.html"

// Terms of Service
"https://vladblajovan.github.io/ritualist-legal/terms.html"
```

---

## Updating Documents

To update the legal documents:

1. Edit the HTML files in this folder
2. Commit and push changes:
   ```bash
   git add .
   git commit -m "Update privacy policy"
   git push
   ```
3. GitHub Pages will automatically redeploy (usually within 1-2 minutes)

---

## Notes

- These documents support **dark mode** automatically via `prefers-color-scheme`
- Mobile-responsive design for in-app viewing
- Last updated dates should be changed when making significant updates
- Contact emails referenced: `privacy@ritualist.app` and `support@ritualist.app`
