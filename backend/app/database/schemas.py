import json
from typing import List, Optional, Union
from pydantic import BaseModel


class UserBase(BaseModel):
    mi_id: str

class UserCreate(UserBase):
    password: str

    class Config:
        orm_mode = True

class User(UserBase):
    id: int

    class Config:
        orm_mode = True



class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Union[str, None] = None

class CustomerGet(BaseModel):
    phone: str
    class Config:
        orm_mode = True

class CustomerCreate(BaseModel):
    phone: str
    email: str
    name: str

class Customer(BaseModel):
    id: int
    name: str
    email: str
    phone: str
    orders: "List[Order]" = []
    class Config:
        orm_mode = True
class Product(BaseModel):
    id: int
    category: str
    name: str
    price: int
    img_url: str
    details: object
    class Config:
        orm_mode = True

class OrderNew(BaseModel):
    amount: int
    currency: str

class OrderSuccess(BaseModel):
    order_id: str
    payment_id: str
    signature: str

class Order(OrderNew):
    id: Optional[int]
    receipt_id: str
    payment_verified: bool
    order_id: str
    payment_id: str
    # customer_id: int
    # customer: Customer
    class Config:
        orm_mode = True

Customer.update_forward_refs()