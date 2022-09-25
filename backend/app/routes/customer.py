from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session


from auth.auth import get_current_user
import database.crud.customer as customer_crud
from database import schemas
from database.database import get_db
from log_util.log_util import get_logger
router = APIRouter()

logger = get_logger('customer.py')

@router.get('/customer/{phone}', response_model=schemas.CustomerCreate)
def customer(phone: str, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get customer by phone"""
    if not user:
        logger.warning(f"Attempt to access /customer/{phone} by unauthorized user")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access customer details!")
    
    customer = customer_crud.get_customer_by_phone(db=db, phone=phone)

    if not customer:
        logger.info(f"Attempt to access /customer/{phone} with non-existent phone")
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Cannot find customer with phone: {customer}")
    
    return customer

@router.post('/customer', response_model=schemas.CustomerCreate)
def create_customer(customer_create: schemas.CustomerCreate, user: schemas.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Create a new customer"""
    if not user:
        logger.warning(f"Attempt to create a customer by unauthorized user")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Not authorised to access or modify customer details!")
    
    return customer_crud.create_customer(db = db, customer = customer_create)
