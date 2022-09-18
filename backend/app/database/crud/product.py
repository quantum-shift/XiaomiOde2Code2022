import json
import os
def get_product(product_id: str):
    print(os.getcwd())
    file_dir = os.path.dirname(os.path.abspath(__file__))
    filename = os.path.join(file_dir, '../../assets/products.json')
    with open(filename) as f:
        db_product = json.load(f)
    
    for product in db_product:
        if product['id'] == product_id:
            return product
    
    return None