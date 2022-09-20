import email, smtplib, ssl

from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from database import schemas
from receipt import receipt
import os

def send_email(order: schemas.Order):
    customer = order.customer
    print("ORDER SENT TO SEND_EMAIL: ", order.__str__())
    subject = f"Your order {order.order_id} at Xiaomi Store"
    body = f"Dear {customer.name},\n\nCongratulations on your purchase at Xiaomi. Please find attached the receipt.\n"
    
    sender_email = os.environ.get('EMAIL_ID')
    password = os.environ.get('EMAIL_PASSWORD')
    print("Creds: ", sender_email, password)

    receiver_email = customer.email

    message = MIMEMultipart()
    message['From'] = sender_email
    message['To'] = receiver_email
    message['Subject'] = subject

    message.attach(MIMEText(body, 'plain'))

    receipt.generate_receipt(order=order)

    filename = f'receipt_{order.order_id}.pdf'
    with open(filename, 'rb') as attachment:
        part = MIMEBase('application', 'octet-stream')
        part.set_payload(attachment.read())
    
    encoders.encode_base64(part)
    part.add_header(
        "Content-Disposition",
        f"attachment; filename= {filename}",
    )

    # Add attachment to message and convert message to string
    message.attach(part)
    text = message.as_string()

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
        server.login(sender_email, password)
        server.sendmail(sender_email, receiver_email, text)
        print(f"Email sent successfully to {receiver_email}!")
    
    receipt.delete_receipt(order_id=order.order_id)