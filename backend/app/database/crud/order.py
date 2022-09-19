from typing import List
from sqlalchemy.orm import Session

from .. import schemas, models


def get_order(db: Session, order_id: int):
    return db.query(models.Order).filter(models.Order.order_id == order_id).first()

def get_orders(db: Session, offset: int = 0, limit: int = 100):
    return db.query(models.Order).offset(offset).limit(limit).all()

def create_order(db: Session, order: schemas.OrderCreate):
    db_order = models.Order(
        order_id=order.order_id, 
        payment_id=order.payment_id, 
        receipt_id=order.receipt_id, 
        amount=order.amount, 
        currency=order.currency, 
        payment_verified=order.payment_verified,
        customer_id=order.customer_id,
        items=order.items,
        user_id=order.user_id
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order

def update_order_cart(db: Session, order_id: str, items: List[schemas.SoldProduct], user_id: str):
    existing_order: schemas.Order = get_order(db = db, order_id = order_id)

    if existing_order is None:
        return False
    
    existing_order.items = items
    existing_order.user_id = user_id

    db.add(existing_order)
    db.commit()
    db.refresh(existing_order)
    
    return True

