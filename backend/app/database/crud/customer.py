from sqlalchemy.orm import Session
from fastapi import Depends
from database.database import get_db

from .. import schemas, models


def get_customer(db: Session, customer_id: int):
    """Read customer by customer id"""
    return db.query(models.Customer).filter(models.Customer.id == customer_id).first()

def get_customers(db: Session, offset: int = 0, limit: int = 100):
    """Read customers in [offset, offset + limit)"""
    return db.query(models.Customer).offset(offset).limit(limit).all()

def get_customer_by_phone(db: Session, phone: str):
    """Read customer by phone"""
    # Try by whole phone number
    customer = db.query(models.Customer).filter(models.Customer.phone == phone).first()
    if customer is not None:
        return customer
    
    # Try with last 10 digits (in case of added country code)
    phone_without_country_code = phone[len(phone) - 10: ]
    return db.query(models.Customer).filter(models.Customer.phone == phone_without_country_code).first()

def create_customer(db: Session, customer: schemas.CustomerCreate):
    """Create a customer"""
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