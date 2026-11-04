from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import RecommendationRequest, RecommendationResponse
from app.services.recommendation_engine import rank_and_recommend_doctors
from app.auth import get_current_user

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])

@router.post("", response_model=RecommendationResponse)
def get_recommendations(request: RecommendationRequest, db: Session = Depends(get_db), current_user: object = Depends(get_current_user)):
    mapped_specialties, recommendations = rank_and_recommend_doctors(db, request)
    return RecommendationResponse(matched_specialties=mapped_specialties, recommendations=recommendations)
