from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, PickleType
from sqlalchemy.orm import relationship

from .database import Base


class User(Base):
    __tablename__ = "user"

    id = Column(Integer, primary_key=True, index=True)
    mi_id = Column(String, unique=True, index=True)
    orders = relationship("Order", back_populates="user")
    hashed_password = Column(String)

class Customer(Base):
    __tablename__ = "customer"
    id = Column(Integer, primary_key=True, index=True)
    phone = Column(String, unique=True, index=True)
    name = Column(String)
    email = Column(String)
    # uncomment if orders of a customer is used later for some functionality
    # orders = relationship("Order", back_populates="customer")

class Order(Base):
    __tablename__ = "order"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(String, unique=True)
    payment_id = Column(String, unique=True)
    receipt_id = Column(String, unique=True)
    amount = Column(Integer)
    currency = Column(String)
    payment_verified = Column(Boolean)
    items = Column(PickleType)
    customer_id = Column(Integer, ForeignKey('customer.id'))
    customer = relationship("Customer") 
    user_id = Column(Integer, ForeignKey('user.id'))
    user = relationship("User", back_populates="orders")

