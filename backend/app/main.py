from datetime import date, timedelta
from random import random
from fastapi import FastAPI, Depends, status, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from log_util.log_util import get_logger
from database import models, crud, schemas
from database.database import engine, get_db
from sqlalchemy.orm import Session
from auth.auth import ACCESS_TOKEN_EXPIRE_MINUTES, authenticate_user, create_access_token, get_current_user
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm

logger = get_logger('main')

# Instantiate database

models.Base.metadata.create_all(bind=engine)


app = FastAPI()
origins = [
    "http://localhost:3000",
    "http://localhost:8000"
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

@app.get('/')
def root():
    return {"message": "Welcome to XIAOMI Hackathon backend server!"}

@app.post('/users', response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_mi_id(db, mi_id=user.mi_id)
    if db_user:
        raise HTTPException(status_code=400, detail="mi_id already registered!")
    return crud.create_user(db=db, user=user)

@app.post("/token", response_model=schemas.Token)
async def login_for_access_token(db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.mi_id}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}
