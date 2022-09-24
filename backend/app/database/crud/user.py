from sqlalchemy.orm import Session

from auth.util import get_password_hash

from .. import models, schemas


def get_user(db: Session, user_id: int):
    """Read user from user id"""
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_orders(db: Session, user_id: int):
    """Read all the orders made by user_id"""
    return db.query(models.User).filter(models.User.id == user_id).first().orders

def get_user_by_mi_id(db: Session, mi_id: str):
    """Get user by MI ID"""
    return db.query(models.User).filter(models.User.mi_id == mi_id).first()

def get_users(db: Session, offset: int = 0, limit: int = 100):
    """Get users in [offset, offset + limit)"""
    return db.query(models.User).offset(offset).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate):
    """Create (register) a new user"""
    hashed_password = get_password_hash(user.password)
    db_user = models.User(mi_id=user.mi_id, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user
