from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm


from auth.auth import authenticate_user
from database import schemas
from database.database import get_db
from database.crud import user as user_crud
from auth.auth import ACCESS_TOKEN_EXPIRE_MINUTES, authenticate_user, create_access_token
from datetime import timedelta

router = APIRouter()