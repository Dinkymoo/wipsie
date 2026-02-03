# Installation Guide - Clipboard History Manager Extension

## Prerequisites

- Microsoft Edge (Chromium-based) or Google Chrome browser
- The extension files from this repository

## Step-by-Step Installation

### 1. Download/Clone the Repository

If you haven't already, download or clone this repository to your local machine.

### 2. Open Browser Extensions Page

**For Microsoft Edge:**
1. Open Microsoft Edge browser
2. Type `edge://extensions/` in the address bar and press Enter
3. Alternatively, click the three dots menu (⋯) → Extensions → Manage Extensions

**For Google Chrome:**
1. Open Google Chrome browser
2. Type `chrome://extensions/` in the address bar and press Enter
3. Alternatively, click the three dots menu (⋮) → More tools → Extensions

### 3. Enable Developer Mode

1. Look for the "Developer mode" toggle switch (usually in the bottom-left or top-right)
2. Click the toggle to enable Developer mode
3. New buttons should appear: "Load unpacked", "Pack extension", "Update"

### 4. Load the Extension

1. Click the "Load unpacked" button
2. Navigate to the repository folder
3. Select the `browser-extension` folder (the folder containing manifest.json)
4. Click "Select Folder" or "Open"

### 5. Verify Installation

You should see the Clipboard History Manager extension appear in your extensions list with:
- Extension name: "Clipboard History Manager"
- Version: 1.0.0
- Status: Enabled
- The extension icon should appear in your browser toolbar

### 6. Pin the Extension (Optional but Recommended)

1. Click the puzzle piece icon in your toolbar (Extensions menu)
2. Find "Clipboard History Manager"
3. Click the pin icon to keep it visible in your toolbar

## Testing the Extension

### Quick Test

1. Open the included `test-page.html` file in your browser
   - Navigate to the `browser-extension` folder
   - Open `test-page.html` in your browser
2. Select and copy (Ctrl+C or Cmd+C) any text from the test page
3. Click the extension icon in your toolbar
4. Verify that the copied text appears in the popup

### Real-World Test

1. Browse to any website
2. Select and copy some text (Ctrl+C or right-click → Copy)
3. Click the extension icon
4. Your copied text should appear in the history list
5. Click any item to copy it back to your clipboard
6. Try the search function to filter items
7. Test the delete and clear all buttons

## Troubleshooting

### Extension doesn't appear after loading

- Make sure you selected the `browser-extension` folder (not the root repository folder)
- Check that all required files are present (manifest.json, background.js, etc.)
- Check the browser console for error messages

### Copy events are not captured

- Make sure the extension is enabled
- Reload the webpage you're testing on
- Check that content.js is loading by opening Developer Tools → Console

### Extension icon not showing

- Check if Developer mode is still enabled
- Try reloading the extension (click the refresh/reload button on the extension card)
- Try pinning the extension to the toolbar

### Popup doesn't open

- Right-click the extension icon and select "Inspect popup" to see console errors
- Make sure popup.html, popup.js, and popup.css are in the correct location

### No items appearing in history

- Check browser console for errors
- Verify that the content script is running on the page
- Make sure you're actually copying text (Ctrl+C or right-click → Copy)

## Updating the Extension

After making changes to the extension files:

1. Go to `edge://extensions/` or `chrome://extensions/`
2. Find the Clipboard History Manager extension
3. Click the "Reload" or refresh button (circular arrow icon)
4. Test your changes

## Uninstalling

1. Go to `edge://extensions/` or `chrome://extensions/`
2. Find the Clipboard History Manager extension
3. Click "Remove"
4. Confirm the removal

## Data Privacy

- All clipboard data is stored locally in your browser using Chrome's storage API
- No data is sent to external servers
- Your clipboard history is private to your browser profile
- Clearing browser data will also clear the clipboard history

## Browser Compatibility

This extension works with:
- ✅ Microsoft Edge (Chromium-based, version 88+)
- ✅ Google Chrome (version 88+)
- ✅ Brave Browser
- ✅ Opera
- ✅ Other Chromium-based browsers

## Next Steps

Once installed, the extension will automatically start tracking your clipboard history. For usage instructions, see the main [README.md](README.md) file.
