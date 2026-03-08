import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import random

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
EMAIL_USER = "travelspeekt@gmail.com"
EMAIL_PASSWORD = "ytvl pcmt syax jpqb"
FROM_EMAIL = "travelspeekt@gmail.com"
FROM_NAME = "TravelSpeak"

def generate_verification_code():
    return str(random.randint(100000, 999999))

def send_verification_email(to_email: str, code: str, username: str = "Utilisateur"):  # ✅ AJOUTÉ username
    try:
        msg = MIMEMultipart()
        msg['From'] = f"{FROM_NAME} <{FROM_EMAIL}>"
        msg['To'] = to_email
        msg['Subject'] = f"Vérifiez votre compte TravelSpeak, {username}!"
        
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }}
                .container {{ max-width: 600px; margin: 50px auto; background-color: #ffffff; border-radius: 10px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center; padding: 30px 20px; }}
                .content {{ padding: 40px 30px; text-align: center; }}
                .code-box {{ background-color: #f8f9fa; border: 2px dashed #667eea; border-radius: 10px; padding: 20px; margin: 30px 0; }}
                .code {{ font-size: 36px; font-weight: bold; color: #667eea; letter-spacing: 8px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1> TravelSpeak</h1>
                    <p>Bienvenue {username} !</p>
                </div>
                <div class="content">
                    <h2>Vérifiez votre compte</h2>
                    <p>Merci de vous être inscrit ! 🎉</p>
                    <p>Voici votre code de vérification :</p>
                    <div class="code-box">
                        <div class="code">{code}</div>
                    </div>
                    <p style="color: #666;">Ce code expire dans <strong>10 minutes</strong></p>
                </div>
            </div>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(html_body, 'html'))
        
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_USER, EMAIL_PASSWORD)
            server.send_message(msg)
        
        print(f"Verification email sent to {to_email}")
        return True
        
    except Exception as e:
        print(f"Error sending email: {e}")
        return False

def send_welcome_email(to_email: str, username: str):
    try:
        msg = MIMEMultipart()
        msg['From'] = f"{FROM_NAME} <{FROM_EMAIL}>"
        msg['To'] = to_email
        msg['Subject'] = f"Bienvenue {username} !"
        
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <body style="font-family: Arial; background: #f4f4f4; margin: 0; padding: 40px;">
            <div style="max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px;">
                <h1 style="color: #10B981;">Compte Vérifié !</h1>
                <p>Félicitations <strong>{username}</strong> !</p>
                <p>Vous êtes maintenant prêt à explorer le Maroc avec TravelSpeak ! 🇲🇦</p>
                <p style="color: #666; margin-top: 30px;">Made with ❤️ in Morocco</p>
            </div>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(html_body, 'html'))
        
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_USER, EMAIL_PASSWORD)
            server.send_message(msg)
        
        print(f"✅ Welcome email sent to {to_email}")
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        return False

def send_password_reset_email(to_email: str, reset_code: str):
    # ... (votre code existant)
    pass