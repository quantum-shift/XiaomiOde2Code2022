from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session


from auth.auth import get_current_user
import database.crud.customer as customer_crud
from database import schemas
from database.database import get_db

router = APIRouter()

@router.get('/customer/{phone}', response_model=schemas.Customer)
def customer(phone: str, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")
    
    customer = customer_crud.get_customer_by_phone(db=db, phone=phone)

    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Cannot find customer with phone: {customer}")
    
    return customer

@router.post('/customer', response_model=schemas.Customer)
def create_customer(customer_create: schemas.CustomerCreate, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")
    
    return customer_crud.create_customer(db = db, customer = customer_create)
