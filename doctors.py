from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Doctor, DoctorAvailability
from app.schemas import DoctorResponse, AvailabilityResponse
from app.auth import get_current_user

router = APIRouter(prefix="/doctors", tags=["Doctors"])

@router.get("", response_model=list[DoctorResponse])
def get_doctors(db: Session = Depends(get_db)):
    return db.query(Doctor).all()

@router.get("/{doctor_id}", response_model=DoctorResponse)
def get_doctor(doctor_id: int, db: Session = Depends(get_db)):
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return doctor

@router.get("/{doctor_id}/availability", response_model=list[AvailabilityResponse])
def get_doctor_availability(doctor_id: int, db: Session = Depends(get_db), current_user: object = Depends(get_current_user)):
    return (
        db.query(DoctorAvailability)
        .filter(DoctorAvailability.doctor_id == doctor_id, DoctorAvailability.status == "available")
        .order_by(DoctorAvailability.available_date, DoctorAvailability.start_time)
        .all()
    )
