from datetime import datetime, timedelta
from typing import Union

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from database.crud.user import get_user_by_mi_id
from database.schemas import TokenData
from database.database import get_db
from sqlalchemy.orm import Session
from auth.util import verify_password

# to get a string like this run:
# openssl rand -hex 32
SECRET_KEY = "3ab87e463a2b76bc410b28e84c2a2467e727d4bd8d83c497818fc898854d2e22"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


def get_user(db, mi_id: str):
    return get_user_by_mi_id(db=db, mi_id=mi_id)


def authenticate_user(db, mi_id: str, password: str):
    user = get_user(db=db, mi_id=mi_id)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user


def create_access_token(data: dict, expires_delta: Union[timedelta, None] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_current_user(db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)):
    print("GET CURRENT USER CALLED WITH TOKEN: ", token)
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
    user = get_user(db, mi_id=token_data.username)
    if user is None:
        raise credentials_exception
    print("RETURNING")
    return user
