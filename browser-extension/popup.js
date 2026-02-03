// Popup script to display and manage clipboard history
let allHistory = [];
let filteredHistory = [];

// Load history when popup opens
document.addEventListener('DOMContentLoaded', () => {
  loadHistory();
  
  // Set up event listeners
  document.getElementById('clearBtn').addEventListener('click', clearHistory);
  document.getElementById('searchInput').addEventListener('input', handleSearch);
});

// Load clipboard history from storage
async function loadHistory() {
  chrome.runtime.sendMessage({ action: 'getHistory' }, (response) => {
    allHistory = response.history || [];
    filteredHistory = allHistory;
    renderHistory();
  });
}

// Render history items
function renderHistory() {
  const historyList = document.getElementById('historyList');
  const historyCount = document.getElementById('historyCount');
  
  // Update count
  historyCount.textContent = `${filteredHistory.length} item${filteredHistory.length !== 1 ? 's' : ''}`;
  
  // Clear existing items
  historyList.innerHTML = '';
  
  if (filteredHistory.length === 0) {
    historyList.innerHTML = `
      <div class="empty-state">
        <p>No clipboard history yet.</p>
        <p class="empty-hint">Copy some text to get started!</p>
      </div>
    `;
    return;
  }
  
  // Render each history item
  filteredHistory.forEach((entry, index) => {
    const item = createHistoryItem(entry, index);
    historyList.appendChild(item);
  });
}

// Create a history item element
function createHistoryItem(entry, index) {
  const item = document.createElement('div');
  item.className = 'history-item';
  
  const formattedTime = formatTime(entry.timestamp);
  const previewText = entry.text.length > 200 ? entry.text.substring(0, 200) + '...' : entry.text;
  
  item.innerHTML = `
    <div class="history-item-header">
      <span class="history-item-time">${formattedTime}</span>
      <div class="history-item-actions">
        <button class="action-btn action-btn-copy" data-id="${entry.id}">Copy</button>
        <button class="action-btn action-btn-delete" data-id="${entry.id}">Delete</button>
      </div>
    </div>
    <div class="history-item-text">${escapeHtml(previewText)}</div>
    ${entry.url ? `<div class="history-item-url">${escapeHtml(entry.url)}</div>` : ''}
  `;
  
  // Add click handlers
  item.querySelector('.action-btn-copy').addEventListener('click', (e) => {
    e.stopPropagation();
    copyToClipboard(entry.text);
  });
  
  item.querySelector('.action-btn-delete').addEventListener('click', (e) => {
    e.stopPropagation();
    deleteEntry(entry.id);
  });
  
  // Click on item to copy
  item.addEventListener('click', () => {
    copyToClipboard(entry.text);
  });
  
  return item;
}

// Format timestamp to readable format
function formatTime(timestamp) {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  
  if (diffMins < 1) {
    return 'Just now';
  } else if (diffMins < 60) {
    return `${diffMins} min${diffMins !== 1 ? 's' : ''} ago`;
  } else if (diffHours < 24) {
    return `${diffHours} hour${diffHours !== 1 ? 's' : ''} ago`;
  } else if (diffDays < 7) {
    return `${diffDays} day${diffDays !== 1 ? 's' : ''} ago`;
  } else {
    return date.toLocaleDateString();
  }
}

// Copy text to clipboard
async function copyToClipboard(text) {
  try {
    await navigator.clipboard.writeText(text);
    showNotification('Copied to clipboard!');
  } catch (error) {
    console.error('Failed to copy text:', error);
    showNotification('Failed to copy', true);
  }
}

// Show notification
function showNotification(message, isError = false) {
  const notification = document.createElement('div');
  notification.className = 'copy-notification';
  notification.textContent = message;
  
  if (isError) {
    notification.style.background = '#f44336';
  }
  
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.remove();
  }, 2000);
}

// Clear all history
function clearHistory() {
  if (confirm('Are you sure you want to clear all clipboard history?')) {
    chrome.runtime.sendMessage({ action: 'clearHistory' }, (response) => {
      if (response.success) {
        allHistory = [];
        filteredHistory = [];
        renderHistory();
        showNotification('History cleared');
      }
    });
  }
}

// Delete a single entry
function deleteEntry(id) {
  chrome.runtime.sendMessage({ action: 'deleteEntry', id: id }, (response) => {
    if (response.success) {
      loadHistory();
      showNotification('Entry deleted');
    }
  });
}

// Handle search
function handleSearch(event) {
  const searchTerm = event.target.value.toLowerCase().trim();
  
  if (searchTerm === '') {
    filteredHistory = allHistory;
  } else {
    filteredHistory = allHistory.filter(entry => 
      entry.text.toLowerCase().includes(searchTerm) ||
      (entry.url && entry.url.toLowerCase().includes(searchTerm))
    );
  }
  
  renderHistory();
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
