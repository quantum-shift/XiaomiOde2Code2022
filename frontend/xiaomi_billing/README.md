# Xiaomi Billing App

This is the submission of Team BForBrute for Xiaomi Ode2Code 2.0 (2022).

## Installation

### Android
Download and install the APK file found in the releases of the repository.

### Windows
Download and unzip the zip file found in the releases of the reposotory. The extracted folder contains the .exe application file.

### iOS

Todo

## Build Instructions (on Linux)

- Install [Flutter](https://docs.flutter.dev/get-started/install/linux).
- If python is not pre-installed, install [python](https://docs.python-guide.org/starting/install3/linux/).
- Clone the repostory or download the source code from the releases page.
    ### Backend
    - Navigate to the FastAPI project root `$ cd backend/app`
    - Create a virtual environment `$ python3 -m venv .venv`
    - Activate virtual environment `$ source .venv/bin/activate`
    - Update pip `$ pip install --upgrade pip`
    - Install dependencies `$ pip install -r ../requirements.txt`
    - Create a copy of `.env.sample` file in the same directory and name it `.env`
    - Follow [Razorpay instructions](https://razorpay.com/docs/x/get-started/api-keys/#test-mode) to create `API_KEY_ID` and `API_KEY_SECRET` and write the in the `.env` file
    - Create a [webhook](https://razorpay.com/docs/webhooks/) in Razorpay for order.paid events. Run the command `$ openssl rand -hex 32`. Put the output in the Secret field in the configuration of the webhook. Also, put the output as the value for `WEBHOOK_SECRET` in `.env` file.
    - To configure emailing (through a gmail account), enable two factor authentication in your gmail account and generate an [app password](https://support.google.com/accounts/answer/185833?hl=en). Put your email id as value for `EMAIL_ID` and the generated app password for `EMAIL_PASSWORD`.
    - You're all set! Run `$ uvicorn main:app --reload` to start the backend server. Host in cloud service of your choice.
    ### Frontend

    - Navigate to the Flutter project root `$ cd frontend/xiaomi_billing`
    - Install plugins `$ flutter pub get`
    - Create a copy of `.env.sample` file in the same directory and name it `.env`
    - Put the Razorpay `API_KEY_ID` and the URL of the backend server `BASE_URL` in the `.env` file.
    - Create and open an Android device with Google play from Android Studio virtual device manager.
    - Run `flutter run` and the app should start in the emulator!

## Implementation:
- Frontend
  - Written in Dart using Flutter framework.
  - Only uses libraries that are compatible with Android, iOS and Windows desktop (and additionally, Linux and macOS desktop) and therefore can be built for and used in all of these platforms.
  - Integrates **Razorpay** gateway through their plugin which supports Android and iOS and uses native widgets and native Dart API. For Windows, the payment gateway opens in a server-side rendered webpage in the default browser.
  - Supports offline payments when the app is offline (or online).
  - Periodically syncs all offline orders with the backend to ensure no loss of data. Runs periodic retries for failed updation cart, customer and user details of online orders. This sync only runs when the app is online and connected to the backend.
  - Caches all images and products locally to allow instant loading of store page and consequently, a faster order flow.
  - Uses **Hive** key value database for storing cart and order data.
  - Follows Flutter recommended directory structure and file naming conventions.
  - Uses **Dio** library for making API calls over HTTP. It has features that allow easy addition of interceptors (which add authorization headers) and setting base URL of backend for all API calls.
  - Uses **shared_preferences** plugin provided by Flutter for storing sensitive information such as access token. Shared preferences stores the data in secure storage with encryption ensuring safety of stored data.
  
- Backend
  - Written in Python using FastAPI framework.
  - Uses SQLite database to store order, user and customer data. Other relational databases such as PostgreSQL and mySQL can be used instead by simply changing the database URL.
  - Communicates with Razorpay Orders API and Payments API through their Python library and also acts as an intermediary between the frontend and backend.
  - Supports OAuth2 protocol for authorization. It is implemented using the popular passlib library using the bcrypt encryption scheme. Allows login persistence through a JWT (access token).
  - Receives signature verified payment success events through a webhook configured with Razorpay.
  - Uses Python standard libraries `email`, `smtplib` and `ssl` for reliably sending emails on payment success.
  - Uses fast `borb` library for generating PDF receipts.
  - Renders Windows payment page using `jinja2` template library.
  - Follows FastAPI recommended documentation and directory structure guidelines.
  - Uses `pydantic` library for validation of database model objects received in API calls or sent as responses.