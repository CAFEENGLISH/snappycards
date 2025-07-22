# SnappyCards Email API Backend

Node.js API backend emailek küldéséhez Zoho SMTP-n keresztül.

## 🚀 Features

- **Express.js** szerver CORS támogatással
- **Nodemailer** + Zoho SMTP integráció  
- **Professional HTML email templates**
- **Input validation** és error handling
- **Ready for production** deployment

## 📋 Environment Variables

```bash
PORT=3000
SMTP_HOST=smtp.zoho.com
SMTP_PORT=587
SMTP_USER=info@snappycards.io
SMTP_PASS=QrfRsj9yPzaB
NODE_ENV=production
```

## 🔧 Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Start production server  
npm start
```

## 📧 API Endpoints

### POST /send-confirmation

Confirmation email küldése waitlist regisztrációhoz.

**Request:**
```json
{
  "email": "user@example.com",
  "confirmationToken": "abc123xyz"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Confirmation email sent successfully",
  "messageId": "zoho_message_id",
  "from": "info@snappycards.io",
  "to": "user@example.com",
  "provider": "zoho_smtp"
}
```

### GET /

Health check endpoint.

## 🚀 Deploy to Render

1. **GitHub repo létrehozása** a backend-nek
2. **Render.com** → New Web Service → Connect GitHub
3. **Environment Variables** beállítása Render dashboard-on
4. **Auto-deploy** minden git push-ra

### Render Environment Variables:
```
SMTP_HOST = smtp.zoho.com
SMTP_PORT = 587  
SMTP_USER = info@snappycards.io
SMTP_PASS = QrfRsj9yPzaB
NODE_ENV = production
```

## 🔒 Security

- **CORS** enabled for frontend domain
- **Input validation** minden endpoint-on
- **Environment variables** sensitive data-hoz
- **Error handling** without sensitive info exposure

## 📊 Logs

A szerver részletes logokat ír minden email küldésről:
- Email címzett
- Confirmation URL
- SMTP status
- Success/error messages

## 🎯 Frontend Integration

A frontend így hívja az API-t:

```javascript
const response = await fetch('https://snappycards-api.onrender.com/send-confirmation', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        email: 'user@example.com',
        confirmationToken: 'token123'
    })
});
``` 