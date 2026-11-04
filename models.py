from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship as db_relationship
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    phone_number = Column(String)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="patient")
    created_at = Column(DateTime, default=datetime.utcnow)

    family_members = db_relationship("FamilyMember", back_populates="patient")
    appointments = db_relationship("Appointment", back_populates="patient")
    notifications = db_relationship("Notification", back_populates="user")


class FamilyMember(Base):
    __tablename__ = "family_members"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    age = Column(Integer)
    gender = Column(String)
    relationship = Column(String)
    medical_notes = Column(String)

    patient = db_relationship("User", back_populates="family_members")


class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    specialty = Column(String, nullable=False)
    hospital_name = Column(String)
    hospital_address = Column(String)
    city = Column(String)
    latitude = Column(Float, default=17.3850)
    longitude = Column(Float, default=78.4867)
    consultation_fee = Column(Float, default=500.0)
    average_rating = Column(Float, default=4.0)
    total_reviews = Column(Integer, default=0)
    expected_waiting_time_minutes = Column(Integer, default=30)
    gender = Column(String, default="Any")
    profile_description = Column(String)

    availability = db_relationship("DoctorAvailability", back_populates="doctor")


class DoctorAvailability(Base):
    __tablename__ = "doctor_availability"

    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    available_date = Column(String, nullable=False)
    start_time = Column(String, nullable=False)
    end_time = Column(String)
    slot_duration_minutes = Column(Integer, default=30)
    status = Column(String, default="available")

    doctor = db_relationship("Doctor", back_populates="availability")


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    family_member_id = Column(Integer, ForeignKey("family_members.id"))
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    slot_id = Column(Integer, ForeignKey("doctor_availability.id"))
    appointment_date = Column(String, nullable=False)
    appointment_time = Column(String, nullable=False)
    symptoms = Column(String)
    booking_notes = Column(String)
    status = Column(String, default="booked")
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = db_relationship("User", back_populates="appointments")
    family_member = db_relationship("FamilyMember")
    doctor = db_relationship("Doctor")


class Symptom(Base):
    __tablename__ = "symptoms"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    related_specialty = Column(String, nullable=False)


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    type = Column(String, default="info")
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = db_relationship("User", back_populates="notifications")