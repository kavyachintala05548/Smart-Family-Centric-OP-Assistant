from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Doctor, Appointment
from app.schemas import DoctorResponse
from app.auth import get_current_user

router = APIRouter(prefix="/admin", tags=["Admin"])

def require_admin(current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required.")
    return current_user

@router.get("/doctors", response_model=list[DoctorResponse])
def get_all_doctors(db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    return db.query(Doctor).all()

@router.get("/appointments")
def get_all_appointments(db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    return db.query(Appointment).all()
