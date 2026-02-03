# Quick Guide: Creating New Repository

## Step-by-Step Instructions for Moving the Extension to a New Repo

### Prerequisites

- GitHub account
- Git installed on your computer
- The archive file (`clipboard-history-extension.zip` or `.tar.gz`)

### Step 1: Extract the Archive

**On Windows:**
```powershell
# Navigate to where you want to create the repository
cd C:\Users\YourName\Projects

# Extract the archive
Expand-Archive -Path clipboard-history-extension.zip -DestinationPath .
```

**On Mac/Linux:**
```bash
# Navigate to where you want to create the repository
cd ~/Projects

# Extract the archive (choose one)
unzip clipboard-history-extension.zip
# OR
tar -xzf clipboard-history-extension.tar.gz
```

### Step 2: Create GitHub Repository

1. Go to https://github.com/new
2. **Repository name**: `clipboard-history-extension` (or your preferred name)
3. **Description**: "Browser extension for Edge/Chrome that saves the last 100 copied text items"
4. **Visibility**: Public or Private (your choice)
5. **Do NOT check**:
   - ❌ Add a README file (we already have one)
   - ❌ Add .gitignore (we already have one)
   - ❌ Choose a license (add later if needed)
6. Click **Create repository**

### Step 3: Initialize and Push

GitHub will show you instructions. Use these commands:

```bash
# Navigate to the extracted folder
cd clipboard-history-extension

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Clipboard History Manager extension"

# Rename branch to main (if needed)
git branch -M main

# Add remote repository (replace with your URL)
git remote add origin https://github.com/YOUR_USERNAME/clipboard-history-extension.git

# Push to GitHub
git push -u origin main
```

### Step 4: Configure Repository Settings (Optional)

On GitHub, go to your repository settings:

1. **Topics**: Add tags like `browser-extension`, `clipboard-manager`, `chrome-extension`, `edge-extension`
2. **About**: Add description and website
3. **README**: Should display automatically
4. **License**: Consider adding MIT or Apache 2.0 license

### Step 5: Verify Everything Works

1. Check that all files are visible on GitHub
2. Verify the README displays correctly
3. Test cloning the repository:
   ```bash
   cd /tmp
   git clone https://github.com/YOUR_USERNAME/clipboard-history-extension.git test-clone
   cd test-clone
   ```

### Step 6: Test the Extension

1. Load the extension in your browser (see INSTALLATION_MANUAL.md)
2. Copy some text
3. Click the extension icon
4. Verify it works!

## Common Issues

### Git not recognizing the folder

```bash
# Make sure you're in the right directory
cd clipboard-history-extension
pwd  # Should show the path to your extracted folder

# Try again
git init
```

### Permission denied when pushing

```bash
# Configure your git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# You may need to authenticate with GitHub
# Use a personal access token instead of password
```

### Files not being added

```bash
# Check git status
git status

# If files are ignored, check .gitignore
cat .gitignore

# Force add if necessary (be careful)
git add -f filename
```

## Alternative: Use GitHub Desktop

If you prefer a GUI:

1. Download GitHub Desktop: https://desktop.github.com/
2. Open GitHub Desktop
3. Click "Create a New Repository on your hard drive"
4. Choose the extracted folder location
5. Click "Publish repository" to push to GitHub

## Next Steps After Creating Repository

1. **Update README**: Customize README_STANDALONE.md as your main README
2. **Add License**: Choose an appropriate license
3. **Add Topics**: Help others discover your extension
4. **Create Releases**: Use GitHub Releases for versioning
5. **Add Issues Template**: Help users report bugs
6. **Set up CI/CD**: Optional - automate testing

## Useful Git Commands

```bash
# Check status
git status

# View commit history
git log --oneline

# Create a new branch
git checkout -b feature-name

# Push changes
git add .
git commit -m "Your message"
git push

# Create a tag/release
git tag v1.0.0
git push --tags
```

## Documentation Files

Once in the new repo, you can:
- Rename `README_STANDALONE.md` to `README.md` (replace the existing)
- Delete `README_ARCHIVE.md` (no longer needed)
- Keep all other documentation

## Publishing to Chrome Web Store (Future)

If you want to publish officially:
1. Create a Chrome Web Store developer account ($5 one-time fee)
2. Package the extension
3. Upload to the store
4. Submit for review

See: https://developer.chrome.com/docs/webstore/publish/

---

**You're all set! Your extension is now in its own repository! 🎉**
