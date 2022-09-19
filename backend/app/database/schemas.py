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
    orders: "Optional[List[Order]]" = []
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
    class Config:
        orm_mode = True
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

class SoldProduct(BaseModel):
    product_id: str
    serial: str

class OrderNew(BaseModel):
    amount: int
    currency: str

class OrderSuccess(BaseModel):
    order_id: str
    payment_id: str
    signature: str

class OrderUpdate(BaseModel):
    user_id: str
    items: List[SoldProduct]

class OrderOffline(OrderNew):
    user_id: str
    phone: str
    items: Optional[List[SoldProduct]]
    class Config:
        orm_mode = True

class OrderCreate(OrderNew):
    id: Optional[int]
    receipt_id: str
    payment_verified: bool
    order_id: str
    payment_id: str
    customer_id: int
    user_id: Optional[str]
    items: Optional[List[SoldProduct]]
    class Config:
        orm_mode = True

class OrderSend(OrderCreate):
    class Config:
        orm_mode = True

class Order(OrderCreate):
    customer: Customer
    class Config:
        orm_mode = True

class OrderForToken(BaseModel):
    amount: int
    name: str
    phone: str
    order_id: str

Customer.update_forward_refs()
User.update_forward_refs()