from glob import glob
import razorpay as rp
import os
from dotenv import load_dotenv

client: rp.Client = None

def init_client():
    """Initialise Razorpay client object"""
    global client
    API_KEY_ID = os.environ.get('API_KEY_ID')
    API_KEY_SECRET = os.environ.get('API_KEY_SECRET')
    client = rp.Client(auth=(API_KEY_ID, API_KEY_SECRET))


def create_order(amount: int, receipt: str, currency: str = "INR"):
    """Create an order using orders API to get order id used in transaction"""
    DATA = {
        "amount": amount,
        "currency": currency,
        "receipt": receipt
    }
    response = client.order.create(data=DATA)
    return response['id']

def verify_order_signature(order_id: str, payment_id: str, signature: str):
    """Verify validity of order id and payment id sent from frontend"""
    DATA = {
        "razorpay_order_id": order_id,
        "razorpay_payment_id": payment_id,
        "razorpay_signature": signature
    }
    return client.utility.verify_payment_signature(DATA)

def verify_webhook_signature(request_body: str, request_signature: str):
    """Verify that an API call is from Razorpay by matching request signature"""
    WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET')
    return client.utility.verify_webhook_signature(request_body, request_signature, WEBHOOK_SECRET)

def get_payment_details(payment_id: str):
    """Fetch the payment details of a payment from Razorpay"""
    payment = client.payment.fetch(payment_id)
    return payment

def get_order_details(order_id: str):
    """Fetch the order details of an order from Razorpay"""
    order = client.order.fetch(order_id)
    return order