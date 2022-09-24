from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm


from auth.auth import authenticate_user
from database import schemas
from database.database import get_db
from database.crud import user as user_crud
from auth.auth import ACCESS_TOKEN_EXPIRE_DAYS, authenticate_user, create_access_token
from datetime import timedelta

router = APIRouter()

@router.post('/users', response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """Create a new user in the database"""
    db_user = user_crud.get_user_by_mi_id(db, mi_id=user.mi_id)
    if db_user:
        raise HTTPException(status_code=400, detail="mi_id already registered!")
    return user_crud.create_user(db=db, user=user)

@router.post("/token", response_model=schemas.Token)
async def login_for_access_token(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    """Verify login credentials and return access token on successful login"""
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    access_token = create_access_token(
        data={"sub": user.mi_id}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}