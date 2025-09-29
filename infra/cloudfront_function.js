function handler(event) {
    var response = event.response;
    var headers = response.headers;

    // Add security headers
    headers['strict-transport-security'] = { value: 'max-age=31536000; includeSubDomains; preload' };
    headers['x-content-type-options'] = { value: 'nosniff' };
    headers['x-frame-options'] = { value: 'DENY' };
    headers['referrer-policy'] = { value: 'no-referrer-when-downgrade' };
    headers['permissions-policy'] = { value: 'geolocation=(), microphone=(), camera=()' };
    headers['content-security-policy'] = { 
        value: "default-src 'self'; img-src 'self' data:; script-src 'self' https://www.google.com https://www.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com" 
    };

    return response;
}
