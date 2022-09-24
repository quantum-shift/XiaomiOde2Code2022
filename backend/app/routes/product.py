import json
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth.auth import get_current_user
from database.database import get_db
from database.crud import product as product_crud
from database import schemas

router = APIRouter()

@router.get('/products', response_model=List[schemas.Product])
def products(user: schemas.User = Depends(get_current_user)):
    
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access products!")

    with open('assets/products.json') as f:
        db_product = json.load(f)
    
    return db_product