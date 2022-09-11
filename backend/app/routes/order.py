from typing import List
from urllib import response
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.auth import get_current_user
from database.database import get_db
from database.crud import order as order_crud
from database import schemas

router = APIRouter()

@router.get('/order/{id}', response_model=schemas.Order)
def order(id: int, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")

    db_order = order_crud.get_order(db, id)

    if not db_order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Cannot find order with id: {id}")
    
    return {"product": db_order}

@router.get('/orders', response_model=List[schemas.Product])
def orders(user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")
    
    db_order = order_crud.get_orders()

@router.post('/order', response_model=schemas.Order)
def create_order(order: schemas.Order, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")
    

