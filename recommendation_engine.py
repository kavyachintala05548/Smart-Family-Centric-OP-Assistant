import math
from datetime import date, timedelta
from typing import List
from sqlalchemy.orm import Session
from app.models import Doctor, DoctorAvailability, Symptom
from app.schemas import RecommendationRequest, DoctorRecommendationResponse, FactorScores, DoctorResponse

DEFAULT_SYMPTOM_SPECIALTY_MAP = {
    "fever": ["General Physician", "Pediatrician"],
    "cough": ["General Physician", "ENT"],
    "cold": ["General Physician", "ENT"],
    "body pain": ["General Physician"],
    "child fever": ["Pediatrician"],
    "vaccination": ["Pediatrician"],
    "child growth": ["Pediatrician"],
    "chest pain": ["Cardiologist"],
    "bp": ["Cardiologist", "General Physician"],
    "heart": ["Cardiologist"],
    "skin rash": ["Dermatologist"],
    "acne": ["Dermatologist"],
    "allergy": ["Dermatologist", "ENT"],
    "joint pain": ["Orthopedic"],
    "fracture": ["Orthopedic"],
    "back pain": ["Orthopedic"],
    "pregnancy": ["Gynecologist"],
    "menstrual issues": ["Gynecologist"],
    "ear pain": ["ENT"],
    "throat pain": ["ENT"],
    "sinus": ["ENT"],
    "headache": ["Neurologist", "General Physician"],
    "migraine": ["Neurologist"],
    "numbness": ["Neurologist"],
}

def calculate_haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)

def get_mapped_specialties(db: Session, symptoms, custom_text=None):
    matched = set()
    symptom_rows = db.query(Symptom).all()
    symptom_db_map = {s.name.lower(): s.related_specialty for s in symptom_rows}
    tokens = [s.strip().lower() for s in symptoms if s and s.strip()]
    if custom_text:
        tokens.extend([t.strip().lower() for t in custom_text.split() if len(t.strip()) > 2])

    for token in tokens:
        for symptom_name, specialty in symptom_db_map.items():
            if token in symptom_name or symptom_name in token:
                matched.add(specialty)
        for symptom_key, specialties in DEFAULT_SYMPTOM_SPECIALTY_MAP.items():
            if token in symptom_key or symptom_key in token:
                matched.update(specialties)

    if not matched:
        matched.add("General Physician")
    return list(matched)

def evaluate_doctor_recommendation(doctor, mapped_specialties, user_lat, user_lon, req, availabilities):
    if doctor.specialty in mapped_specialties:
        specialty_score = 100.0
    elif "General Physician" in mapped_specialties or doctor.specialty == "General Physician":
        specialty_score = 80.0
    else:
        specialty_score = 30.0

    distance_km = calculate_haversine_distance(user_lat, user_lon, doctor.latitude or 17.3850, doctor.longitude or 78.4867)

    if distance_km <= 2: distance_score = 100.0
    elif distance_km <= 5: distance_score = 90.0
    elif distance_km <= 10: distance_score = 75.0
    elif distance_km <= 20: distance_score = 55.0
    elif distance_km <= 50: distance_score = 35.0
    else: distance_score = max(10.0, 100.0 - distance_km * 1.5)

    today = date.today().isoformat()
    tomorrow = (date.today() + timedelta(days=1)).isoformat()
    active_slots = [a for a in availabilities if a.status == "available"]
    active_slots.sort(key=lambda x: (x.available_date, x.start_time))

    if active_slots:
        first_slot = active_slots[0]
        if first_slot.available_date == today:
            availability_score, next_slot = 100.0, f"Today at {first_slot.start_time}"
        elif first_slot.available_date == tomorrow:
            availability_score, next_slot = 85.0, f"Tomorrow at {first_slot.start_time}"
        else:
            availability_score, next_slot = 65.0, f"{first_slot.available_date} at {first_slot.start_time}"
    else:
        availability_score, next_slot = 20.0, None

    max_budget = 2000.0
    if req.preferences and req.preferences.max_consultation_fee:
        max_budget = req.preferences.max_consultation_fee

    fee = doctor.consultation_fee
    if fee <= max_budget:
        fee_score = max(70.0, 100.0 - (fee / max_budget * 25.0))
    else:
        fee_score = max(10.0, 70.0 - ((fee - max_budget) / max_budget * 100.0))

    wait_time = doctor.expected_waiting_time_minutes or 30
    if wait_time <= 15: waiting_time_score = 100.0
    elif wait_time <= 30: waiting_time_score = 80.0
    elif wait_time <= 45: waiting_time_score = 60.0
    else: waiting_time_score = 40.0

    rating_score = min(100.0, (doctor.average_rating / 5.0) * 100.0)

    final_score = (
        specialty_score * 0.30 + distance_score * 0.20 + availability_score * 0.20 +
        fee_score * 0.15 + waiting_time_score * 0.10 + rating_score * 0.05
    )
    final_score = round(min(100.0, max(0.0, final_score)), 1)

    factor_scores = FactorScores(
        specialty_match=round(specialty_score, 1),
        distance_score=round(distance_score, 1),
        availability_score=round(availability_score, 1),
        fee_score=round(fee_score, 1),
        waiting_time_score=round(waiting_time_score, 1),
        rating_score=round(rating_score, 1),
    )

    symptom_text = ", ".join(req.symptoms) if req.symptoms else "your symptoms"
    if doctor.specialty in mapped_specialties:
        explanation = f"{doctor.full_name} is recommended with a match score of {final_score}/100 because they are a {doctor.specialty} matching {symptom_text}, are {distance_km} km away at {doctor.hospital_name}, "
    else:
        explanation = f"{doctor.full_name} is recommended with a match score of {final_score}/100 because they are a {doctor.specialty}, are {distance_km} km away at {doctor.hospital_name}, "

    if next_slot:
        explanation += f"have an available slot {next_slot.lower()}, "

    explanation += f"charge Rs.{int(doctor.consultation_fee)}, have an expected waiting time of {doctor.expected_waiting_time_minutes} minutes, and hold a {doctor.average_rating}/5 rating."

    return DoctorRecommendationResponse(
        doctor=DoctorResponse.model_validate(doctor),
        distance_km=distance_km,
        next_available_slot=next_slot,
        overall_match_score=final_score,
        factor_scores=factor_scores,
        explanation=explanation,
    )

def rank_and_recommend_doctors(db: Session, req: RecommendationRequest):
    mapped_specialties = get_mapped_specialties(db, req.symptoms, req.custom_symptom_text)
    query = db.query(Doctor)

    if req.filter_specialty:
        query = query.filter(Doctor.specialty == req.filter_specialty)
    if req.filter_max_fee:
        query = query.filter(Doctor.consultation_fee <= req.filter_max_fee)
    if req.filter_min_rating:
        query = query.filter(Doctor.average_rating >= req.filter_min_rating)
    if req.filter_hospital:
        query = query.filter(Doctor.hospital_name.ilike(f"%{req.filter_hospital}%"))

    doctors = query.all()
    user_lat = req.latitude or 17.3850
    user_lon = req.longitude or 78.4867
    results = []

    for doctor in doctors:
        availability = db.query(DoctorAvailability).filter(DoctorAvailability.doctor_id == doctor.id).all()
        recommendation = evaluate_doctor_recommendation(doctor, mapped_specialties, user_lat, user_lon, req, availability)
        if req.filter_max_distance_km and recommendation.distance_km > req.filter_max_distance_km:
            continue
        results.append(recommendation)

    if req.sort_by == "nearest":
        results.sort(key=lambda x: x.distance_km)
    elif req.sort_by == "lowest_fee":
        results.sort(key=lambda x: x.doctor.consultation_fee)
    elif req.sort_by == "highest_rating":
        results.sort(key=lambda x: x.doctor.average_rating, reverse=True)
    elif req.sort_by == "earliest_slot":
        results.sort(key=lambda x: x.factor_scores.availability_score, reverse=True)
    else:
        results.sort(key=lambda x: x.overall_match_score, reverse=True)

    return mapped_specialties, results
