// Background service worker to manage clipboard history
const MAX_HISTORY_SIZE = 100;

// Listen for messages from content scripts and popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'textCopied') {
    saveToHistory(message.text, message.url, message.timestamp);
    return false; // No async response needed
  }
  
  if (message.action === 'getHistory') {
    chrome.storage.local.get(['clipboardHistory'], (result) => {
      sendResponse({ history: result.clipboardHistory || [] });
    });
    return true; // Keep the message channel open for async response
  }
  
  if (message.action === 'clearHistory') {
    chrome.storage.local.set({ clipboardHistory: [] }, () => {
      sendResponse({ success: true });
    });
    return true; // Keep the message channel open for async response
  }
  
  if (message.action === 'deleteEntry') {
    chrome.storage.local.get(['clipboardHistory'], (result) => {
      let history = result.clipboardHistory || [];
      history = history.filter(entry => entry.id !== message.id);
      chrome.storage.local.set({ clipboardHistory: history }, () => {
        sendResponse({ success: true });
      });
    });
    return true; // Keep the message channel open for async response
  }
});

// Save copied text to history
async function saveToHistory(text, url, timestamp) {
  try {
    // Get existing history
    const result = await chrome.storage.local.get(['clipboardHistory']);
    let history = result.clipboardHistory || [];
    
    // Create new history entry with unique ID
    const entry = {
      text: text,
      url: url,
      timestamp: timestamp,
      id: crypto.randomUUID() // Unique ID
    };
    
    // Add to the beginning of the array
    history.unshift(entry);
    
    // Keep only the last 100 items
    if (history.length > MAX_HISTORY_SIZE) {
      history = history.slice(0, MAX_HISTORY_SIZE);
    }
    
    // Save back to storage
    await chrome.storage.local.set({ clipboardHistory: history });
  } catch (error) {
    console.error('Error saving to clipboard history:', error);
  }
}
