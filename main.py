from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, family, doctors, recommendations, appointments, notifications, admin
from app.seed_data import seed_database

app = FastAPI(title="Smart Family-Centric OP Assistant API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(family.router)
app.include_router(doctors.router)
app.include_router(recommendations.router)
app.include_router(appointments.router)
app.include_router(notifications.router)
app.include_router(admin.router)

@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "service": "Smart Family-Centric OP Assistant API"}

@app.on_event("startup")
def startup_event():
    seed_database()
