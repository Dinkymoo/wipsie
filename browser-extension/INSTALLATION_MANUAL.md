# Step-by-Step Installation Manual
## Clipboard History Manager Browser Extension

---

## 📋 What You'll Need

Before starting, make sure you have:
- ✅ Microsoft Edge (Chromium) or Google Chrome browser installed
- ✅ The extension files downloaded (this repository)
- ✅ 5 minutes of your time

---

## 🚀 Installation Steps

### Step 1: Download the Extension Files

1. **Download this repository** to your computer
   - Click the green "Code" button on GitHub
   - Select "Download ZIP"
   - Extract the ZIP file to a location you'll remember (e.g., your Desktop or Downloads folder)

   > 📝 **Note**: Remember where you saved the `browser-extension` folder - you'll need it in Step 4!

---

### Step 2: Open Your Browser's Extensions Page

Choose your browser:

#### Option A: Microsoft Edge

1. **Open Microsoft Edge** browser
2. **Type** `edge://extensions/` in the address bar
3. **Press Enter**

   > 💡 **Alternative**: Click the three dots menu (⋯) → Extensions → Manage Extensions

#### Option B: Google Chrome

1. **Open Google Chrome** browser
2. **Type** `chrome://extensions/` in the address bar
3. **Press Enter**

   > 💡 **Alternative**: Click the three dots menu (⋮) → More tools → Extensions

---

### Step 3: Enable Developer Mode

1. **Look for** the "Developer mode" toggle switch
   - In Edge: It's in the **left sidebar**
   - In Chrome: It's in the **top-right corner**

2. **Click the toggle** to turn Developer mode ON
   - The toggle should turn blue/green when enabled

3. **New buttons appear**: You should now see "Load unpacked", "Pack extension", and "Update" buttons

   > ⚠️ **Important**: Developer mode MUST be enabled to install unpacked extensions!

---

### Step 4: Load the Extension

1. **Click** the "Load unpacked" button
   - This button appeared after enabling Developer mode

2. **Navigate** to the folder where you extracted the repository

3. **Select** the `browser-extension` folder
   - ⚠️ Make sure to select the `browser-extension` folder, NOT the parent folder
   - The `browser-extension` folder should contain `manifest.json`

4. **Click** "Select Folder" (or "Open" depending on your OS)

   > 📁 **Folder Structure Check**:
   > ```
   > browser-extension/
   > ├── manifest.json  ← This file should be in the folder you select
   > ├── background.js
   > ├── content.js
   > ├── popup.html
   > └── ...
   > ```

---

### Step 5: Verify Installation

After loading, you should see:

✅ **In the Extensions Page**:
- Extension name: "Clipboard History Manager"
- Version: 1.0.0
- Status: Enabled (toggle is ON)
- Description: "Keep track of the last 100 copied text items"

✅ **In Your Toolbar**:
- A new extension icon appears (clipboard icon)

   > 🔍 **Can't see the icon?** It might be hidden in the extensions menu (puzzle piece icon)

---

### Step 6: Pin the Extension to Toolbar (Recommended)

To keep the extension easily accessible:

1. **Click** the puzzle piece icon 🧩 in your browser toolbar
2. **Find** "Clipboard History Manager" in the list
3. **Click** the pin icon 📌 next to it
4. The extension icon now stays visible in your toolbar

---

## ✅ Test the Installation

### Quick 30-Second Test

1. **Open** any website or text document
2. **Select** some text
3. **Copy** it (Ctrl+C on Windows/Linux or Cmd+C on Mac)
4. **Click** the extension icon in your toolbar
5. **Verify** the text appears in the popup window

   > 🎉 **Success!** If you see your copied text, the extension is working!

### Using the Test Page

1. **Navigate** to the `browser-extension` folder
2. **Open** `test-page.html` in your browser
3. **Copy** different text samples from the page
4. **Click** the extension icon
5. **See** all copied items in the history

---

## 🎯 Using the Extension

Once installed, the extension automatically works:

### How It Works

1. **Copy any text** on any webpage (Ctrl+C or right-click → Copy)
2. **Click the extension icon** to view your clipboard history
3. **Click any item** to copy it back to your clipboard
4. **Use search** to find specific copied text
5. **Delete items** individually or clear all at once

### Key Features

| Feature | How to Use |
|---------|-----------|
| 📋 **View History** | Click the extension icon |
| 🔍 **Search** | Type in the search box at the top |
| 📝 **Copy Item** | Click on any history item |
| 🗑️ **Delete Item** | Hover over item, click "Delete" button |
| 🧹 **Clear All** | Click "Clear All" button at the top |

---

## 🔧 Troubleshooting

### Problem: Extension doesn't load

**Solution**:
- ✅ Make sure you selected the `browser-extension` folder, not the parent folder
- ✅ Check that `manifest.json` exists in the selected folder
- ✅ Enable Developer mode if it got disabled

### Problem: Copy events not captured

**Solution**:
- ✅ Refresh the webpage you're testing on (F5)
- ✅ Check that the extension is enabled
- ✅ Make sure you're using Ctrl+C or right-click → Copy (not cut/paste)

### Problem: Extension icon doesn't appear

**Solution**:
- ✅ Look for the puzzle piece icon 🧩 and pin the extension
- ✅ Try reloading the extension (click reload button on extension card)

### Problem: Popup window is empty

**Solution**:
- ✅ Copy some text first - the extension starts with empty history
- ✅ Right-click the extension icon → "Inspect popup" to check for errors

---

## 🔄 Updating the Extension

If you download a newer version:

1. Go to `edge://extensions/` or `chrome://extensions/`
2. Find "Clipboard History Manager"
3. Click the refresh/reload button (🔄)
4. The extension updates automatically

---

## 🗑️ Uninstalling

To remove the extension:

1. Go to `edge://extensions/` or `chrome://extensions/`
2. Find "Clipboard History Manager"
3. Click "Remove"
4. Confirm when prompted

   > 📝 **Note**: This will delete all your clipboard history

---

## 🔒 Privacy & Security

- ✅ All data stored **locally** in your browser
- ✅ **No external servers** - no data leaves your computer
- ✅ **No tracking** or analytics
- ✅ **No permissions** to access passwords or sensitive data
- ✅ Works **offline** - no internet required

---

## ❓ Frequently Asked Questions

### Q: Does this extension work on all websites?
**A**: Yes! It works on all websites where you can copy text.

### Q: What happens when I reach 100 items?
**A**: The oldest item is automatically removed when you copy the 101st item.

### Q: Can I export my clipboard history?
**A**: Not in the current version, but this could be added as a feature.

### Q: Does it work with images or files?
**A**: No, only text is currently supported.

### Q: Will this slow down my browser?
**A**: No, the extension is very lightweight (~100KB) and uses minimal resources.

---

## 📞 Need More Help?

If you encounter issues not covered here:

1. Check the [README.md](README.md) for usage documentation
2. See [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
3. Review the browser console for error messages
4. Make sure you're using a Chromium-based browser (Edge, Chrome, Brave, Opera)

---

## ✨ You're All Set!

The extension is now installed and working. Every time you copy text, it's automatically saved to your clipboard history. Click the extension icon anytime to view, search, and manage your copied items.

**Happy copying! 📋✨**

---

*Last updated: February 2026*
*Version: 1.0.0*
