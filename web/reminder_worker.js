// Web Service Worker for Reminders

console.log('Service Worker script started');

self.addEventListener('install', function(event) {
  console.log('Service Worker installing.');
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', function(event) {
  console.log('Service Worker activating.');
  event.waitUntil(self.clients.claim());
});

self.addEventListener('message', function(event) {
  try {
    console.log('Service Worker received message:', event.data);
    
    // Handle incoming messages for scheduling reminders
    if (event.data.type === 'schedule_reminder') {
      const { title, body, timestamp } = event.data;
      
      // Schedule a notification
      self.registration.showNotification(title, {
        body: body,
        icon: '/favicon.png', // Optional: add an icon
        timestamp: timestamp
      });
    }
  } catch (error) {
    console.error('Error in message event:', error);
  }
});

self.addEventListener('push', function(event) {
  try {
    const data = event.data.json();
    
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/favicon.png'
    });
  } catch (error) {
    console.error('Error in push event:', error);
  }
});

// Error handling
self.addEventListener('error', function(event) {
  console.error('Service Worker error:', event.error);
});