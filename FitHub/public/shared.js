// Shared utilities for FitHub landing pages

const APP_STORE_ID = '6749919587';

// Initialize when DOM is ready
(function() {
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    function init() {
        // Trigger custom event when shared.js is ready
        document.dispatchEvent(new CustomEvent('sharedJsReady'));
    }
})();

// Cookie helpers
function setCookie(name, value, days) {
    const expires = new Date();
    expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000));
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax`;
}

function getCookie(name) {
    const nameEQ = name + "=";
    const ca = document.cookie.split(';');
    for (let i = 0; i < ca.length; i++) {
        let c = ca[i];
        while (c.charAt(0) === ' ') c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
    }
    return null;
}

// Generate or retrieve device fingerprint
function getOrCreateDeviceFingerprint() {
    let fingerprint = getCookie('deviceFingerprint');
    if (!fingerprint) {
        // Generate a unique fingerprint based on browser characteristics
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        ctx.textBaseline = 'top';
        ctx.font = '14px Arial';
        ctx.fillText('Device fingerprint', 2, 2);
        const canvasFingerprint = canvas.toDataURL();

        fingerprint = btoa(
            navigator.userAgent +
            navigator.language +
            screen.width +
            screen.height +
            new Date().getTimezoneOffset() +
            canvasFingerprint
        ).substring(0, 64); // Limit to 64 chars

        setCookie('deviceFingerprint', fingerprint, 365); // Store for 1 year
    }
    return fingerprint;
}

// Redirect to App Store
function redirectToAppStore() {
    window.location.href = `https://apps.apple.com/app/id${APP_STORE_ID}`;
}

// Make sure it's available globally
window.redirectToAppStore = redirectToAppStore;

// Store token server-side
function storeTokenServerSide(token, deviceFingerprint, endpoint, storageKey, requestKey) {
    console.log(`📝 ${storageKey} detected:`, token);
    console.log('📝 Device fingerprint:', deviceFingerprint);

    // Store in localStorage and cookie as backup
    localStorage.setItem(storageKey, token);
    setCookie(storageKey, token, 30);
    console.log(`✅ ${storageKey} stored in localStorage and cookie`);

    // Store server-side so app can retrieve it
    console.log(`🔄 Attempting to store ${storageKey} server-side...`);
    const requestBody = {};
    requestBody[requestKey] = token;
    requestBody.deviceFingerprint = deviceFingerprint;

    fetch(endpoint, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody)
    }).then(response => {
        console.log('📡 Server response status:', response.status);
        if (!response.ok) {
            return response.text().then(text => {
                throw new Error(`HTTP ${response.status}: ${text}`);
            });
        }
        return response.json();
    })
    .then(data => {
        console.log('📦 Server response data:', data);
        if (data.success) {
            console.log(`✅ ${storageKey} stored server-side successfully:`, token);
            console.log('📋 Device ID:', data.deviceId);
            // Store device ID in cookie so we can pass it to app if needed
            if (data.deviceId) {
                setCookie('deviceId', data.deviceId, 365);
            }
        } else {
            console.error(`❌ Failed to store ${storageKey} server-side:`, data);
        }
    }).catch(error => {
        console.error(`❌ Error storing ${storageKey} server-side:`, error);
        console.error('Error details:', error.message);
    });
}
