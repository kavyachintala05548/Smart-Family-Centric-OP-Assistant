from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict

class UserRegister(BaseModel):
    full_name: str
    email: str
    phone_number: str
    password: str
    role: Optional[str] = "patient"

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    full_name: str
    email: str
    phone_number: Optional[str]
    role: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class FamilyMemberCreate(BaseModel):
    name: str
    age: int
    gender: str
    relationship: str
    medical_notes: Optional[str] = ""

class FamilyMemberResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    age: Optional[int]
    gender: Optional[str]
    relationship: Optional[str]
    medical_notes: Optional[str]

class DoctorResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    full_name: str
    specialty: str
    hospital_name: Optional[str]
    hospital_address: Optional[str]
    city: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    consultation_fee: float
    average_rating: float
    total_reviews: Optional[int]
    expected_waiting_time_minutes: Optional[int]
    profile_description: Optional[str]

class AvailabilityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    doctor_id: int
    available_date: str
    start_time: str
    end_time: Optional[str]
    status: str

class RecommendationPreferences(BaseModel):
    max_consultation_fee: Optional[float] = 2000.0
    preferred_gender: Optional[str] = "Any"
    preferred_hospital: Optional[str] = None

class RecommendationRequest(BaseModel):
    symptoms: List[str] = []
    custom_symptom_text: Optional[str] = None
    city: Optional[str] = "Hyderabad"
    latitude: Optional[float] = 17.3850
    longitude: Optional[float] = 78.4867
    preferences: Optional[RecommendationPreferences] = None
    filter_specialty: Optional[str] = None
    filter_max_fee: Optional[float] = None
    filter_min_rating: Optional[float] = None
    filter_max_distance_km: Optional[float] = None
    filter_hospital: Optional[str] = None
    sort_by: str = "best_match"

class FactorScores(BaseModel):
    specialty_match: float
    distance_score: float
    availability_score: float
    fee_score: float
    waiting_time_score: float
    rating_score: float

class DoctorRecommendationResponse(BaseModel):
    doctor: DoctorResponse
    distance_km: float
    next_available_slot: Optional[str]
    overall_match_score: float
    factor_scores: FactorScores
    explanation: str

class RecommendationResponse(BaseModel):
    matched_specialties: List[str]
    recommendations: List[DoctorRecommendationResponse]

class AppointmentCreate(BaseModel):
    doctor_id: int
    family_member_id: Optional[int] = None
    slot_id: int
    symptoms: Optional[str] = ""
    booking_notes: Optional[str] = ""

class AppointmentReschedule(BaseModel):
    new_slot_id: int

class AppointmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    patient_id: int
    family_member_id: Optional[int]
    doctor_id: int
    appointment_date: str
    appointment_time: str
    symptoms: Optional[str]
    booking_notes: Optional[str]
    status: str

class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    message: str
    type: str
    is_read: bool
    created_at: datetime
