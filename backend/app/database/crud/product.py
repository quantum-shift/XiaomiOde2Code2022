from sqlalchemy.orm import Session

from .. import schemas, models


def get_product(db: Session, product_id: int):
    return db.query(models.Product).filter(models.Product.id == product_id).first()

def get_products(db: Session, offset: int = 0, limit: int = 100):
    return db.query(models.Product).offset(offset).limit(limit).all()

def create_product(db: Session, product: schemas.Product):
    db_product = models.Product(category=product.category)
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product
