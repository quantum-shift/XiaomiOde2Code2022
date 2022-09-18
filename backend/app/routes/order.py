from base64 import decode
from datetime import timedelta
import json
import os
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from uuid import uuid4

from auth.auth import create_access_token, get_current_user, get_decoded_object
from email_util.email_util import send_email
from database.database import get_db
from database.crud import order as order_crud
from database.crud import customer as customer_crud
from database import schemas
from log_util.log_util import get_logger
import payments.order

ORDER_TOKEN_EXPIRE_MINUTES = 5


logger = get_logger('order')

router = APIRouter()
templates = Jinja2Templates(directory="templates")
# print(templates.)

@router.post('/order/token')
async def get_order_token(order_for_token: schemas.OrderForToken, user: schemas.User = Depends(get_current_user)):
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to create a new order!")
    token: str = create_access_token(order_for_token.dict(), expires_delta=timedelta(minutes=ORDER_TOKEN_EXPIRE_MINUTES))
    return token

@router.get('/order/windows/{token}', response_class=HTMLResponse)
async def read_html(request: Request, token: str, db = Depends(get_db)):
    payload = get_decoded_object(token=token)
    customer = customer_crud.get_customer_by_phone(db=db, phone=payload.get('phone'))
    payload['email'] = customer.email
    return templates.TemplateResponse("index.html", {"request": request, "payload": payload, "API_KEY_ID": os.environ.get('API_KEY_ID')})

@router.post('/order/new')
def new_order(order_new: schemas.OrderNew, user: schemas.User = Depends(get_current_user)):
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to create a new order!")
    
    receipt_id = str(uuid4())
    order_id = payments.order.create_order(amount=order_new.amount, receipt=receipt_id, currency=order_new.currency)
    return {"receipt_id": receipt_id, "order_id": order_id}

@router.post('/order/success')
async def order_success(order_success: schemas.OrderSuccess, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to update order status!")
    
    order_id = order_success.order_id
    payment_id = order_success.payment_id
    signature = order_success.signature
    payment_verified = False

    if payments.order.verify_order_signature(order_id, payment_id, signature):
        logger.info("Payment verified successfully!")
        payment_verified = True
    else:
        logger.error("Failed to verify payment!")
    
    payment_details = payments.order.get_payment_details(payment_id)
    order_details = payments.order.get_order_details(order_id)
    order: schemas.OrderCreate = schemas.OrderCreate(
        order_id=order_id, 
        payment_id=payment_id, 
        receipt_id=order_details['receipt'], 
        amount=payment_details['amount'], 
        currency=payment_details['currency'], 
        payment_verified=payment_verified
    )
    order_crud.create_order(db=db, order=order)

@router.get('/orders', response_model=List[schemas.Product])
def orders(user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access orders!")
    
    db_order = order_crud.get_orders()

@router.post('/order/paid')
async def order_paid(request: Request, db: Session = Depends(get_db)):
    print("Called order/paid.....")
    body = await request.body()
    body = body.decode('utf-8')
    signature = request.headers.get('x-razorpay-signature')
    if payments.order.verify_webhook_signature(request_signature=signature, request_body=body):
        print("Webhook verified successfully!")
    else:
        print("Could not verify webhook!")
        return
    decoded_body = await request.json()
    # print(decoded_body)
    # print(decoded_body['order_id'])
    decoded_order = decoded_body['payload']['order']['entity']
    decoded_payment = decoded_body['payload']['payment']['entity']

    print("Decoded order: ", decoded_order)
    print("Decoded payment: ", decoded_payment)
    order_id = decoded_order['id']
    receipt_id = decoded_order['receipt']

    existing_order: schemas.Order = order_crud.get_order(db=db, order_id=order_id)
    if existing_order is not None and existing_order.payment_verified:
        return

    amount = decoded_payment['amount']
    currency = decoded_payment['currency']
    payment_id = decoded_payment['id']

    payment_verified = True
    items = []

    phone = decoded_payment['contact']
    customer: schemas.Customer = customer_crud.get_customer_by_phone(db=db, phone=phone)

    if customer is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Customer not found!")

    customer_id = customer.id

    order: schemas.OrderCreate = schemas.OrderCreate(
        order_id=order_id, 
        payment_id=payment_id, 
        receipt_id=receipt_id, 
        amount=amount, 
        currency=currency, 
        payment_verified=payment_verified,
        customer_id=customer_id,
        items=items
    )

    order_crud.create_order(db=db, order=order)

    # send_email(order=order_crud.get_order(db=db, order_id=order_id))

@router.post('/order/{id}/status')
def get_order_status(id: str, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access orders!")
    
    order = order_crud.get_order(db=db, order_id=id)

    if order is not None and order.payment_verified:
        return {"status": "paid"}
    else:
        return {"status": "unknown"}

@router.post('/order/{id}/complete', response_model=schemas.OrderSend)
def update_order_to_completion(id: str, order_update: schemas.OrderUpdate, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access orders!")
    
    if order_crud.update_order_cart(db=db, order_id=id, items=order_update.items):
        order = order_crud.get_order(db=db, order_id=id)
        send_email(order=order)
        return order
    else:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Could not find order!")

@router.get('/order/{id}', response_model=schemas.OrderSend)
def order(id: str, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access orders!")

    db_order = order_crud.get_order(db=db, order_id=id)

    if not db_order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Cannot find order with id: {id}")
    
    return {"product": db_order}


