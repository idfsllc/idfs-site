import json
import os
import re
import boto3
import urllib.request
import urllib.parse
from datetime import datetime
import base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from typing import Dict, Any, Optional

# Initialize SES client
ses_client = boto3.client('ses', region_name='us-east-1')

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for contact form submissions.
    
    Validates form data, optionally verifies reCAPTCHA, and sends email via SES.
    Returns JSON response with CORS headers.
    """
    
    # Handle OPTIONS preflight request
    if event.get('httpMethod') == 'OPTIONS':
        return create_cors_response(200, {'ok': True})
    
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Validate required fields
        validation_error = validate_form_data(body)
        if validation_error:
            return create_cors_response(400, {'ok': False, 'error': validation_error})
        
        # Extract form data
        name = body.get('name', '').strip()
        email = body.get('email', '').strip()
        message = body.get('message', '').strip()
        company = body.get('company', '').strip()
        phone = body.get('phone', '').strip()
        recaptcha_token = body.get('token', '')
        
        # Verify reCAPTCHA if enabled
        if os.environ.get('ENABLE_RECAPTCHA', 'false').lower() == 'true':
            if not recaptcha_token:
                return create_cors_response(400, {'ok': False, 'error': 'reCAPTCHA token required'})
            
            if not verify_recaptcha(recaptcha_token):
                return create_cors_response(400, {'ok': False, 'error': 'reCAPTCHA verification failed'})
        
        # Optional attachments
        attachments = body.get('attachments', [])

        # Send email via SES (with optional attachments)
        success = send_contact_email(name, email, message, company, phone, attachments, event)
        
        if success:
            return create_cors_response(200, {'ok': True})
        else:
            return create_cors_response(500, {'ok': False, 'error': 'Failed to send email'})
            
    except json.JSONDecodeError:
        return create_cors_response(400, {'ok': False, 'error': 'Invalid JSON'})
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return create_cors_response(500, {'ok': False, 'error': 'Internal server error'})


def validate_form_data(body: Dict[str, Any]) -> Optional[str]:
    """
    Validate form data and return error message if invalid.
    """
    name = body.get('name', '').strip()
    email = body.get('email', '').strip()
    message = body.get('message', '').strip()
    
    # Validate name
    if not name:
        return 'Name is required'
    if len(name) > 100:
        return 'Name must be less than 100 characters'
    
    # Validate email
    if not email:
        return 'Email is required'
    if not is_valid_email(email):
        return 'Invalid email format'
    
    # Validate message
    if not message:
        return 'Message is required'
    if len(message) > 5000:
        return 'Message must be less than 5000 characters'
    
    return None


def is_valid_email(email: str) -> bool:
    """
    Simple email validation using regex.
    """
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def verify_recaptcha(token: str) -> bool:
    """
    Verify reCAPTCHA token with Google's siteverify API.
    """
    try:
        secret_key = os.environ.get('RECAPTCHA_SECRET', '')
        if not secret_key:
            print("Warning: reCAPTCHA secret key not configured")
            return False
        
        data = urllib.parse.urlencode({
            'secret': secret_key,
            'response': token
        }).encode('utf-8')
        
        request = urllib.request.Request(
            'https://www.google.com/recaptcha/api/siteverify',
            data=data,
            method='POST'
        )
        
        with urllib.request.urlopen(request, timeout=10) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result.get('success', False)
            
    except Exception as e:
        print(f"reCAPTCHA verification error: {str(e)}")
        return False


def send_contact_email(name: str, email: str, message: str, company: str, phone: str, attachments: Any, event: Dict[str, Any]) -> bool:
    """
    Send contact form email via SES.
    """
    try:
        to_email = os.environ.get('TO_EMAIL', '')
        from_email = os.environ.get('FROM_EMAIL', '')
        
        if not to_email or not from_email:
            print("Error: TO_EMAIL or FROM_EMAIL not configured")
            return False
        
        # Get client IP and user agent from event
        client_ip = get_client_ip(event)
        user_agent = event.get('headers', {}).get('User-Agent', 'Unknown')
        
        # Create email content
        timestamp = datetime.utcnow().isoformat() + 'Z'
        
        subject = f"RFQ: {name}"

        body_text = f"""
New contact form submission:

Name: {name}
Email: {email}
Company: {company if company else 'Not provided'}
Phone: {phone if phone else 'Not provided'}
Service Type: {event.get('body', '') and (json.loads(event['body']).get('serviceType', 'Not provided'))}
Message: {message}

---
Submission Details:
Timestamp: {timestamp}
Client IP: {client_ip}
User Agent: {user_agent}
        """.strip()

        # Build MIME message for optional attachments
        msg = MIMEMultipart()
        msg['Subject'] = subject
        msg['From'] = from_email
        msg['To'] = to_email

        msg.attach(MIMEText(body_text, 'plain', 'utf-8'))

        total_attachment_bytes = 0
        try:
            for att in attachments or []:
                filename = att.get('filename')
                content_type = att.get('contentType', 'application/octet-stream')
                content_b64 = att.get('contentBase64', '')
                size = int(att.get('size', 0))
                if not filename or not content_b64:
                    continue
                total_attachment_bytes += size
                if total_attachment_bytes > 7 * 1024 * 1024:
                    print("Skipping attachments: total size exceeds limit ~7MB")
                    break
                part = MIMEBase(*content_type.split('/', 1)) if '/' in content_type else MIMEBase('application', 'octet-stream')
                part.set_payload(base64.b64decode(content_b64))
                encoders.encode_base64(part)
                part.add_header('Content-Disposition', f'attachment; filename="{filename}"')
                msg.attach(part)
        except Exception as e:
            print(f"Attachment processing error: {str(e)}")

        # Send raw email via SES
        response = ses_client.send_raw_email(
            Source=from_email,
            Destinations=[to_email],
            RawMessage={'Data': msg.as_string()}
        )
        
        print(f"Email sent successfully: {response['MessageId']}")
        return True
        
    except Exception as e:
        print(f"Failed to send email: {str(e)}")
        return False


def get_client_ip(event: Dict[str, Any]) -> str:
    """
    Extract client IP from event headers.
    """
    headers = event.get('headers', {})
    
    # Check for X-Forwarded-For header (from CloudFront/API Gateway)
    x_forwarded_for = headers.get('X-Forwarded-For', '')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    
    # Check for X-Real-IP header
    x_real_ip = headers.get('X-Real-IP', '')
    if x_real_ip:
        return x_real_ip
    
    # Fallback to source IP
    return event.get('requestContext', {}).get('identity', {}).get('sourceIp', 'Unknown')


def create_cors_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create HTTP response with CORS headers.
    """
    allowed_origin = os.environ.get('ALLOWED_ORIGIN', '*')
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': allowed_origin,
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '86400'
        },
        'body': json.dumps(body)
    }
