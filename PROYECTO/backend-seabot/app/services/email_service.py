import os
import smtplib
from dotenv import load_dotenv
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

load_dotenv()

def send_reset_email(to_email: str, codigo: str):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    mail_from = os.getenv("MAIL_FROM")

    if not smtp_host or not smtp_user or not smtp_password or not mail_from:
        raise ValueError("Faltan variables SMTP en el .env")

    subject = "Recuperación de contraseña - SeaBot"

    body = f"""
Hola,

Recibimos una solicitud para restablecer tu contraseña en SeaBot.

Tu código de recuperación es: {codigo}

Este código vencerá en 15 minutos.

Si no solicitaste este cambio, ignora este mensaje.
"""

    msg = MIMEMultipart()
    msg["From"] = mail_from
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    server = smtplib.SMTP(smtp_host, smtp_port)
    server.connect(smtp_host, smtp_port)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
    server.quit()
    
    
def send_support_otp_email(to_email: str, codigo: str):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    mail_from = os.getenv("MAIL_FROM")

    if not smtp_host or not smtp_user or not smtp_password or not mail_from:
        raise ValueError("Faltan variables SMTP en el .env")

    subject = "Verificación de correo - Soporte SeaBot"

    body = f"""
Hola,

Para poder enviar tu reporte al área de soporte de SeaBot, necesitamos verificar tu correo electrónico.

Tu código de verificación es: {codigo}

Este código vencerá en 10 minutos.

Si no solicitaste esta verificación, puedes ignorar este mensaje.
"""

    msg = MIMEMultipart()
    msg["From"] = mail_from
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    server = smtplib.SMTP(smtp_host, smtp_port)
    server.connect(smtp_host, smtp_port)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
    server.quit()


def send_support_report_confirmation_to_user(
    to_email: str,
    report_type: str,
    description: str
):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    mail_from = os.getenv("MAIL_FROM")

    if not smtp_host or not smtp_user or not smtp_password or not mail_from:
        raise ValueError("Faltan variables SMTP en el .env")

    subject = "Reporte recibido - Soporte SeaBot"

    body = f"""
Hola,

Hemos recibido correctamente tu reporte en SeaBot.

Tipo de reporte: {report_type}
Estado actual: Recibido

Descripción enviada:
{description}

Nuestro equipo revisará la información y realizará el seguimiento correspondiente.

Gracias por ayudarnos a mejorar SeaBot.
"""

    msg = MIMEMultipart()
    msg["From"] = mail_from
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    server = smtplib.SMTP(smtp_host, smtp_port)
    server.connect(smtp_host, smtp_port)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
    server.quit()


def send_support_report_notification_to_admin(
    admin_email: str,
    student_email: str,
    student_id: int,
    report_type: str,
    description: str,
    ruta_foto: str | None = None
):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    mail_from = os.getenv("MAIL_FROM")

    if not smtp_host or not smtp_user or not smtp_password or not mail_from:
        raise ValueError("Faltan variables SMTP en el .env")

    subject = "Nuevo reporte de soporte recibido - SeaBot"

    imagen_texto = ruta_foto if ruta_foto else "No se adjuntó imagen."

    body = f"""
Hola equipo de soporte,

Se ha registrado un nuevo reporte en SeaBot.

ID del estudiante: {student_id}
Correo del estudiante: {student_email}
Tipo de reporte: {report_type}
Estado inicial: Recibido

Descripción:
{description}

Imagen adjunta:
{imagen_texto}

Por favor, revisar el reporte desde el módulo administrativo correspondiente.
"""

    msg = MIMEMultipart()
    msg["From"] = mail_from
    msg["To"] = admin_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain"))

    server = smtplib.SMTP(smtp_host, smtp_port)
    server.connect(smtp_host, smtp_port)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
    server.quit()    
    
    
    
def send_support_admin_response_to_user(
    to_email: str,
    report_id: int,
    report_type: str,
    status: str,
    subject: str,
    message: str
):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")
    mail_from = os.getenv("MAIL_FROM")

    if not smtp_host or not smtp_user or not smtp_password or not mail_from:
        raise ValueError("Faltan variables SMTP en el .env")

    email_subject = subject

    body = f"""
Hola,

El equipo de soporte de SeaBot ha actualizado tu reporte.

ID del reporte: {report_id}
Tipo de reporte: {report_type}
Estado actual: {status}

Mensaje del equipo de soporte:
{message}

Gracias por comunicarte con nosotros.

Atentamente,
Equipo de Soporte SeaBot
"""

    msg = MIMEMultipart()
    msg["From"] = mail_from
    msg["To"] = to_email
    msg["Subject"] = email_subject
    msg.attach(MIMEText(body, "plain"))

    server = smtplib.SMTP(smtp_host, smtp_port)
    server.connect(smtp_host, smtp_port)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(smtp_user, smtp_password)
    server.send_message(msg)
    server.quit()
