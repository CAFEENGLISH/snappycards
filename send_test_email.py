#!/usr/bin/env python3
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

def send_test_email():
    # SMTP konfiguráció
    smtp_server = "smtp.zoho.com"
    smtp_port = 587
    smtp_user = "info@snappycards.io"
    smtp_pass = "QrfRsj9yPzaB"  # Az App Password amit generáltunk
    
    # Email adatok
    from_email = "info@snappycards.io"
    from_name = "SnappyCards Team"
    to_email = "vidamkos@gmail.com"
    subject = "Hello World - SnappyCards Test"
    
    # Email tartalom
    message = """
    Hello World!
    
    Ez egy teszt email a SnappyCards rendszerből.
    
    A SMTP működik! 🎉
    
    Üdvözlettel,
    SnappyCards Team
    info@snappycards.io
    """
    
    try:
        # Email objektum létrehozása
        msg = MIMEMultipart()
        msg['From'] = f"{from_name} <{from_email}>"
        msg['To'] = to_email
        msg['Subject'] = subject
        
        # Email tartalom hozzáadása
        msg.attach(MIMEText(message, 'plain', 'utf-8'))
        
        # SMTP kapcsolat létrehozása
        print(f"Kapcsolódás: {smtp_server}:{smtp_port}")
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()  # TLS engedélyezése
        
        # Bejelentkezés
        print(f"Bejelentkezés: {smtp_user}")
        server.login(smtp_user, smtp_pass)
        
        # Email küldése
        print(f"Email küldése: {to_email}")
        text = msg.as_string()
        server.sendmail(from_email, to_email, text)
        
        # Kapcsolat lezárása
        server.quit()
        
        print("✅ Email sikeresen elküldve!")
        print(f"   Feladó: {from_email}")
        print(f"   Címzett: {to_email}")
        print(f"   Tárgy: {subject}")
        
    except Exception as e:
        print(f"❌ Email küldési hiba: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("=== SnappyCards Email Test ===")
    send_test_email() 