from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Appointment, DoctorAvailability, Doctor, User, FamilyMember
from app.schemas import AppointmentCreate, AppointmentReschedule, AppointmentResponse
from app.auth import get_current_user
from app.services.notification_service import send_booking_confirmation, send_cancellation_notification, send_reschedule_notification

router = APIRouter(prefix="/appointments", tags=["Appointments"])

@router.get("", response_model=list[AppointmentResponse])
def get_my_appointments(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Appointment).filter(Appointment.patient_id == current_user.id).order_by(Appointment.appointment_date.desc()).all()

@router.post("", response_model=AppointmentResponse, status_code=201)
def book_appointment(data: AppointmentCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    slot = db.query(DoctorAvailability).filter(DoctorAvailability.id == data.slot_id, DoctorAvailability.status == "available").first()
    if not slot:
        raise HTTPException(status_code=400, detail="Selected slot is not available.")
    doctor = db.query(Doctor).filter(Doctor.id == data.doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found.")

    family_member_id = data.family_member_id
    if not family_member_id:
        fam = db.query(FamilyMember).filter(FamilyMember.patient_id == current_user.id).first()
        if fam:
            family_member_id = fam.id
        else:
            new_fam = FamilyMember(patient_id=current_user.id, name=current_user.full_name, age=30, gender="Other", relationship="Self")
            db.add(new_fam); db.commit(); db.refresh(new_fam)
            family_member_id = new_fam.id

    slot.status = "booked"
    appointment = Appointment(
        patient_id=current_user.id, family_member_id=family_member_id, doctor_id=data.doctor_id,
        slot_id=slot.id, appointment_date=slot.available_date, appointment_time=slot.start_time,
        symptoms=data.symptoms or doctor.specialty, booking_notes=data.booking_notes,
    )
    db.add(appointment); db.commit(); db.refresh(appointment)
    send_booking_confirmation(db, current_user.id, doctor.full_name, slot.available_date, slot.start_time)
    return appointment

@router.put("/{appointment_id}/reschedule", response_model=AppointmentResponse)
def reschedule_appointment(appointment_id: int, data: AppointmentReschedule, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id, Appointment.patient_id == current_user.id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")
    if appointment.status == "cancelled":
        raise HTTPException(status_code=400, detail="Cancelled appointments cannot be rescheduled.")
    new_slot = db.query(DoctorAvailability).filter(DoctorAvailability.id == data.new_slot_id, DoctorAvailability.status == "available").first()
    if not new_slot:
        raise HTTPException(status_code=400, detail="New slot is not available.")
    old_slot = db.query(DoctorAvailability).filter(DoctorAvailability.id == appointment.slot_id).first()
    if old_slot:
        old_slot.status = "available"
    new_slot.status = "booked"
    appointment.slot_id = new_slot.id
    appointment.appointment_date = new_slot.available_date
    appointment.appointment_time = new_slot.start_time
    appointment.status = "booked"
    db.commit(); db.refresh(appointment)
    doctor = db.query(Doctor).filter(Doctor.id == appointment.doctor_id).first()
    send_reschedule_notification(db, current_user.id, doctor.full_name, new_slot.available_date, new_slot.start_time)
    return appointment

@router.put("/{appointment_id}/cancel", response_model=AppointmentResponse)
def cancel_appointment(appointment_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id, Appointment.patient_id == current_user.id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")
    if appointment.status == "cancelled":
        raise HTTPException(status_code=400, detail="Appointment is already cancelled.")
    slot = db.query(DoctorAvailability).filter(DoctorAvailability.id == appointment.slot_id).first()
    if slot:
        slot.status = "available"
    appointment.status = "cancelled"
    db.commit(); db.refresh(appointment)
    doctor = db.query(Doctor).filter(Doctor.id == appointment.doctor_id).first()
    send_cancellation_notification(db, current_user.id, doctor.full_name, appointment.appointment_date, appointment.appointment_time)
    return appointment
