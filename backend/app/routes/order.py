from typing import List
from urllib import response
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import uuid4

from auth.auth import get_current_user
from database.database import get_db
from database.crud import order as order_crud
from database import schemas
from log_util.log_util import get_logger
import payments.order


logger = get_logger('order')

router = APIRouter()


@router.post('/order/new')
def new_order(order_new: schemas.OrderNew, user: schemas.User = Depends(get_current_user)):
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")
    
    receipt_id = str(uuid4())
    order_id = payments.order.create_order(amount=order_new.amount, receipt=receipt_id, currency=order_new.currency)
    return {"receipt_id": receipt_id, "order_id": order_id}

@router.post('/order/success')
async def order_success(order_success: schemas.OrderSuccess, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")
    
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
    order: schemas.Order = schemas.Order(
        order_id=order_id, 
        payment_id=payment_id, 
        receipt_id=order_details['receipt'], 
        amount=payment_details['amount'], 
        currency=payment_details['currency'], 
        payment_verified=payment_verified
    )
    order_crud.create_order(db=db, order=order)


@router.get('/order/{id}', response_model=schemas.Order)
def order(id: int, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")

    db_order = order_crud.get_order(db, id)

    if not db_order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Cannot find order with id: {id}")
    
    return {"product": db_order}

@router.get('/orders', response_model=List[schemas.Product])
def orders(user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")
    
    db_order = order_crud.get_orders()

