from typing import Optional
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime
class SensorTelemetry(BaseModel):
    device_id: str = Field(..., description="Unique identifier for the sensor device.")
    timestamp: datetime = Field(..., description="Timestamp of the reading, in ISO format.")
    temperature: float = Field(..., description="Temperature reading.")
    humidity: float = Field(..., ge=0, le=100, description="Humidity reading in percentage.")
    operator_name: str = Field(..., description="Name of the operator on duty.")
    operator_email: EmailStr = Field(..., description="Email of the operator for contact.")
    status_code: Optional[int] = Field(None, description="Optional status code from the device.")
    class Config:
        from_attributes = True
