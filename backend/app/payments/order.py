from glob import glob
import razorpay as rp
import os
from dotenv import load_dotenv

client: rp.Client = None

def init_client():
    global client
    API_KEY_ID = os.environ.get('API_KEY_ID')
    API_KEY_SECRET = os.environ.get('API_KEY_SECRET')
    client = rp.Client(auth=(API_KEY_ID, API_KEY_SECRET))
    print("INITIALISATION DONE!")


def create_order(amount: int, receipt: str, currency: str = "INR"):
    DATA = {
        "amount": amount,
        "currency": currency,
        "receipt": receipt
    }
    response = client.order.create(data=DATA)
    return response['id']

def verify_order_signature(order_id: str, payment_id: str, signature: str):
    DATA = {
        "razorpay_order_id": order_id,
        "razorpay_payment_id": payment_id,
        "razorpay_signature": signature
    }
    return client.utility.verify_payment_signature(DATA)

def get_payment_details(payment_id: str):
    payment = client.payment.fetch(payment_id)
    return payment

def get_order_details(order_id: str):
    order = client.order.fetch(order_id)
    return order

def main():
    global API_KEY_SECRET, API_KEY_ID, client
    load_dotenv()
    API_KEY_ID = os.environ.get('API_KEY_ID')
    API_KEY_SECRET = os.environ.get('API_KEY_SECRET')
    client = rp.Client(auth=(API_KEY_ID, API_KEY_SECRET))
    create_order(100, "1")

if __name__ == '__main__':
    main()