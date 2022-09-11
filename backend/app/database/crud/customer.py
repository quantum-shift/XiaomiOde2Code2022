from sqlalchemy.orm import Session

from auth.util import get_password_hash

from .. import schemas, models


def get_customer(db: Session, customer_id: int):
    return db.query(models.Customer).filter(models.Customer.id == customer_id).first()

def get_customers(db: Session, offset: int = 0, limit: int = 100):
    return db.query(models.Customer).offset(offset).limit(limit).all()

def create_customer(db: Session, customer: schemas.Customer):
    db_customer = models.Customer(email = customer.email, name = customer.name)
    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    return db_customer
