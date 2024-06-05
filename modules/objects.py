from dataclasses import dataclass

@dataclass
class VehicleResult():
    id: str
    make: str
    model: str
    badge: str
    transmission_type: str
    fuel_type: str
    drive_type: str
    matching_score: int

@dataclass
class Listing():
    id: str
    vehicle_id: str
    url: str
    price: int
    kms: int


