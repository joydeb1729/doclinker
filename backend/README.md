# DocLinker FastAPI Backend

A FastAPI backend for the DocLinker Flutter application with Firebase authentication and MongoDB integration.

## Features

- 🔐 Firebase JWT token verification
- 🗄️ MongoDB integration with Motor (async)
- 🌐 CORS enabled for Flutter frontend
- 📝 Pydantic models with MongoDB compatibility
- 🔄 Async context manager for database connections
- 📊 Health check endpoint
- 📚 Auto-generated API documentation

## Setup

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Environment Configuration

Copy the example environment file and configure it:

```bash
cp env.example .env
```

Edit `.env` with your configuration:

```env
# MongoDB Configuration
MONGO_URI=mongodb://localhost:27017/doclinker

# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_PATH=path/to/serviceAccountKey.json

# Server Configuration
HOST=0.0.0.0
PORT=8000
```

### 3. Firebase Setup

1. Go to your Firebase Console
2. Navigate to Project Settings > Service Accounts
3. Generate a new private key
4. Save the JSON file securely
5. Update `FIREBASE_SERVICE_ACCOUNT_PATH` in `.env`

### 4. MongoDB Setup

Ensure MongoDB is running locally or update `MONGO_URI` to point to your MongoDB instance.

## Running the Application

### Development Mode

```bash
python main.py
```

Or using uvicorn directly:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Production Mode

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

## API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## API Endpoints

### Health Check
- `GET /ping` - Health check endpoint

### Authentication
- `POST /auth/verify-token` - Verify Firebase JWT token
- `GET /auth/me` - Get current user information

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── models.py          # Pydantic models
│   ├── database.py        # MongoDB connection
│   ├── firebase_service.py # Firebase token verification
│   └── api/
│       ├── __init__.py
│       └── auth.py        # Authentication routes
├── main.py                # FastAPI application
├── requirements.txt       # Python dependencies
├── env.example           # Environment variables template
└── README.md            # This file
```

## Models

### User Models
- `UserBase`: Base user model with name, email, phone, uid
- `UserCreate`: For creating new users
- `UserInDB`: Database user model with id and created_at
- `TokenData`: For token verification data

## Database

The application uses MongoDB with Motor (async driver). The database connection is managed through an async context manager that automatically connects on startup and disconnects on shutdown.

## Authentication

Authentication is handled through Firebase JWT tokens. The `verify_firebase_token` function validates tokens and extracts user information (uid, email).

## CORS Configuration

CORS is configured to allow requests from:
- `http://localhost:3000`
- `http://localhost:8080`
- `http://127.0.0.1:3000`
- `http://127.0.0.1:8080`

## Error Handling

The API includes comprehensive error handling for:
- Invalid or expired Firebase tokens
- Missing authorization headers
- Database connection issues
- User not found scenarios

## Development

### Adding New Routes

1. Create a new router in `app/api/`
2. Import and include it in `main.py`
3. Follow the existing pattern for dependencies and error handling

### Adding New Models

1. Define models in `app/models.py`
2. Use `PyObjectId` for MongoDB ObjectId compatibility
3. Include proper Pydantic configurations

### Testing

The API includes comprehensive error handling and validation. Test endpoints using the Swagger UI at `/docs`. 