from typing import Union
from passlib.context import CryptContext
from fastapi.security import OAuth2PasswordBearer

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")



def verify_password(plain_password, hashed_password):
    """Use passlib function to verify equality of plain and hashed passwords"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    """Return the hash of the password"""
    return pwd_context.hash(password)