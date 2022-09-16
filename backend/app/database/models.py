from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .database import Base


class User(Base):
    __tablename__ = "user"

    id = Column(Integer, primary_key=True, index=True)
    mi_id = Column(String, unique=True, index=True)
    hashed_password = Column(String)

class Customer(Base):
    __tablename__ = "customer"
    id = Column(Integer, primary_key=True, index=True)
    phone = Column(String, unique=True, index=True)
    name = Column(String)
    email = Column(String, unique=True)
    orders = relationship("Order", back_populates="customer")

# class Product(Base):
#     __tablename__ = "product"
#     id = Column(Integer, primary_key=True, index=True)
#     category = Column(String)

class Order(Base):
    __tablename__ = "order"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(String, unique=True)
    payment_id = Column(String, unique=True)
    receipt_id = Column(String, unique=True)
    amount = Column(Integer)
    currency = Column(String)
    payment_verified = Column(Boolean)
    customer_id = Column(Integer, ForeignKey('customer.id'))
    customer = relationship("Customer", back_populates="orders") 

