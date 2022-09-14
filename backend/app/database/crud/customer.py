from sqlalchemy.orm import Session
from fastapi import Depends
from database.database import get_db

from .. import schemas, models


def get_customer(db: Session, customer_id: int):
    return db.query(models.Customer).filter(models.Customer.id == customer_id).first()

def get_customers(db: Session, offset: int = 0, limit: int = 100):
    return db.query(models.Customer).offset(offset).limit(limit).all()

def get_customer_by_phone(db: Session, phone: str):
    return db.query(models.Customer).filter(models.Customer.phone == phone).first()

def create_customer(db: Session, customer: schemas.CustomerCreate):
    existing_customer: schemas.Customer = get_customer_by_phone(db = db, phone = customer.phone)
    if not existing_customer:
        db_customer = models.Customer(email = customer.email, name = customer.name, phone=customer.phone)
    else:
        db_customer = existing_customer
        db_customer.name = customer.name
        db_customer.email = customer.email

    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    return db_customer