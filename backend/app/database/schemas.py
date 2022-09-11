import json
from typing import List, Union
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


class Customer(BaseModel):
    id: int
    name: str
    email: str
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

class Order(BaseModel):
    id: int
    customer_id: int
    customer: Customer
    class Config:
        orm_mode = True

Customer.update_forward_refs()