function handler(event) {
    var request = event.request;
    var host = request.headers.host.value;
    
    // Check if this is a request to the apex domain (without www)
    if (host === '${apex_domain}') {
        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                'location': { value: 'https://${www_domain}' + request.uri }
            }
        };
    }
    
    // For all other requests, continue normally
    return request;
}
