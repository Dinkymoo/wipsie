// Content script to detect copy events
document.addEventListener('copy', (event) => {
  // Get the selected text
  const selectedText = window.getSelection().toString().trim();
  
  if (selectedText) {
    // Send the copied text to the background script
    chrome.runtime.sendMessage({
      action: 'textCopied',
      text: selectedText,
      timestamp: Date.now(),
      url: window.location.href
    });
  }
});
