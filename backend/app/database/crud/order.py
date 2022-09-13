from sqlalchemy.orm import Session

from auth.util import get_password_hash

from .. import schemas, models


def get_order(db: Session, order_id: int):
    return db.query(models.Order).filter(models.Order.id == order_id).first()

def get_orders(db: Session, offset: int = 0, limit: int = 100):
    return db.query(models.Order).offset(offset).limit(limit).all()

def create_order(db: Session, order: schemas.Order):
    db_order = models.Order(
        order_id=order.order_id, 
        payment_id=order.payment_id, 
        receipt_id=order.receipt_id, 
        amount=order.amount, 
        currency=order.currency, 
        payment_verified=order.payment_verified
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order
