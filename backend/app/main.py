from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from payments.order import init_client
from log_util.log_util import get_logger
from database import models
from database.database import engine
from fastapi.security import OAuth2PasswordBearer
from routes import customer, order, product, user
from dotenv import load_dotenv

load_dotenv()
init_client()

logger = get_logger('main')

# Instantiate database

models.Base.metadata.create_all(bind=engine)


app = FastAPI()
app.include_router(customer.router)
app.include_router(order.router)
app.include_router(product.router)
app.include_router(user.router)
origins = [
    # "http://localhost:3000",
    # "http://localhost:8000",
    "*"
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount('/static', StaticFiles(directory="static"), name="static")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

@app.get('/')
def root():
    return {"message": "Welcome to XIAOMI Hackathon backend server!"}
