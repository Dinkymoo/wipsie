# Clipboard History Manager - Browser Extension

A Microsoft Edge browser extension that keeps track of the last 100 text items you copy while working.

## Features

- 📋 Automatically captures text when you copy (Ctrl+C or right-click copy)
- 💾 Stores up to 100 most recent copied text items
- 🔍 Search through your clipboard history
- ⏰ Shows when each item was copied
- 🌐 Displays the URL where text was copied from
- 🗑️ Delete individual items or clear all history
- 🎯 One-click to copy items back to clipboard

## Installation

### Install in Microsoft Edge (Developer Mode)

1. Open Microsoft Edge browser
2. Navigate to `edge://extensions/`
3. Enable "Developer mode" (toggle switch in the left sidebar)
4. Click "Load unpacked"
5. Select the `browser-extension` folder from this repository
6. The extension icon should appear in your toolbar

### Using the Extension

1. **Copy text** anywhere on any webpage using Ctrl+C or right-click → Copy
2. Click the extension icon in your toolbar to open the clipboard history
3. **Click any item** to copy it back to your clipboard
4. Use the **search box** to filter your history
5. Use **Delete** button to remove individual items
6. Use **Clear All** to remove all history

## Privacy

- All clipboard data is stored locally in your browser
- No data is sent to external servers
- Your clipboard history is private to your browser profile

## Files Structure

```
browser-extension/
├── manifest.json       # Extension configuration
├── content.js         # Script that detects copy events on web pages
├── background.js      # Service worker that manages clipboard storage
├── popup.html         # Popup interface HTML
├── popup.js          # Popup interface logic
├── popup.css         # Popup styling
└── icons/            # Extension icons
    ├── icon16.png
    ├── icon48.png
    └── icon128.png
```

## How It Works

1. **Content Script** (`content.js`) runs on all web pages and listens for copy events
2. When text is copied, it sends the text to the **Background Script**
3. **Background Script** (`background.js`) stores the text in Chrome's local storage
4. The storage maintains a maximum of 100 items (oldest are removed when limit is reached)
5. **Popup Interface** (`popup.html`, `popup.js`, `popup.css`) displays the history when you click the extension icon

## Limitations

- Only captures text that is copied through standard browser copy operations
- Does not capture images, files, or formatted content
- Maximum of 100 items in history
- History is cleared if you clear browser data

## Development

To modify the extension:

1. Make your changes to the files
2. Go to `edge://extensions/`
3. Click the "Reload" button on the extension card
4. Test your changes

## Permissions

The extension requires the following permissions:

- `storage`: To save clipboard history locally
- `clipboardRead`: To read copied text (future feature)
- `<all_urls>`: To run the content script on all websites

## Browser Compatibility

This extension is designed for:
- ✅ Microsoft Edge (Chromium-based)
- ✅ Google Chrome
- ✅ Other Chromium-based browsers

## License

This extension is part of the wipsie project.
