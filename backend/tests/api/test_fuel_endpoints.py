"""
FuelIQ — API Integration Tests: Fuel Endpoints
Tests against a real (test) PostgreSQL database.
"""
import pytest
import uuid
from decimal import Decimal
from datetime import datetime, UTC

from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.main import app
from app.models.models import User, Vehicle, FuelLog
from tests.factories import UserFactory, VehicleFactory


@pytest.mark.asyncio
class TestFuelLogEndpoints:
    """
    Integration tests for /api/v1/vehicles/{id}/fuel-logs
    Tests the complete request→service→DB→response flow.
    """

    async def test_create_fuel_log_success(
        self, client: AsyncClient, auth_headers: dict, vehicle: Vehicle
    ):
        """
        Happy path: create a fuel log and verify response.
        """
        payload = {
            "odometer_reading": 15500.0,
            "volume_liters": 35.5,
            "price_per_liter": 96.72,
            "is_full_tank": True,
            "station_name": "HPCL Station, MG Road",
        }

        response = await client.post(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            json=payload,
            headers=auth_headers,
        )

        assert response.status_code == 201
        data = response.json()
        
        assert data["success"] is True
        assert data["data"]["volume_liters"] == "35.500"
        assert data["data"]["price_per_liter"] == "96.7200"
        assert data["data"]["is_full_tank"] is True
        assert data["data"]["station_name"] == "HPCL Station, MG Road"
        
        # total_cost is generated column: 35.5 * 96.72 = 3433.56
        assert float(data["data"]["total_cost"]) == pytest.approx(3433.56, abs=0.01)

    async def test_create_fuel_log_calculates_efficiency(
        self,
        client: AsyncClient,
        auth_headers: dict,
        vehicle: Vehicle,
        db_session: AsyncSession,
    ):
        """
        Verify fuel efficiency is calculated when second full-tank log is added.
        """
        # First fill: 30L at odometer 15000
        first_payload = {
            "odometer_reading": 15000.0,
            "volume_liters": 30.0,
            "price_per_liter": 96.72,
            "is_full_tank": True,
        }
        r1 = await client.post(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            json=first_payload,
            headers=auth_headers,
        )
        assert r1.status_code == 201
        assert r1.json()["data"]["efficiency_lper100km"] is None  # No prev data

        # Second fill: 35L at odometer 15400 (400km driven)
        second_payload = {
            "odometer_reading": 15400.0,
            "volume_liters": 35.0,
            "price_per_liter": 96.72,
            "is_full_tank": True,
        }
        r2 = await client.post(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            json=second_payload,
            headers=auth_headers,
        )
        assert r2.status_code == 201
        data = r2.json()["data"]

        # 35L / 400km * 100 = 8.75 L/100km
        assert data["efficiency_lper100km"] is not None
        assert float(data["efficiency_lper100km"]) == pytest.approx(8.75, abs=0.01)
        assert data["distance_since_last"] == "400.00"

    async def test_create_fuel_log_wrong_vehicle_forbidden(
        self,
        client: AsyncClient,
        auth_headers: dict,
    ):
        """Cannot log fuel for another user's vehicle."""
        other_vehicle_id = str(uuid.uuid4())
        
        response = await client.post(
            f"/api/v1/vehicles/{other_vehicle_id}/fuel-logs",
            json={"odometer_reading": 1000, "volume_liters": 30, "price_per_liter": 90},
            headers=auth_headers,
        )
        assert response.status_code == 404

    async def test_create_fuel_log_odometer_regression_rejected(
        self,
        client: AsyncClient,
        auth_headers: dict,
        vehicle: Vehicle,
    ):
        """Odometer must increase — cannot log lower odometer than current."""
        # Set vehicle's current odometer to 20000
        await client.post(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            json={"odometer_reading": 20000, "volume_liters": 30, "price_per_liter": 90, "is_full_tank": True},
            headers=auth_headers,
        )
        
        # Try to log at lower odometer
        response = await client.post(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            json={"odometer_reading": 19000, "volume_liters": 30, "price_per_liter": 90},
            headers=auth_headers,
        )
        assert response.status_code == 422
        error_data = response.json()
        assert not error_data["success"]

    async def test_list_fuel_logs_paginated(
        self,
        client: AsyncClient,
        auth_headers: dict,
        vehicle: Vehicle,
    ):
        """List endpoint returns paginated results."""
        # Create 5 fuel logs
        for i in range(5):
            await client.post(
                f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
                json={
                    "odometer_reading": 15000 + (i + 1) * 300,
                    "volume_liters": 30 + i,
                    "price_per_liter": 96.72,
                    "is_full_tank": True,
                },
                headers=auth_headers,
            )

        response = await client.get(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs?page=1&page_size=3",
            headers=auth_headers,
        )
        assert response.status_code == 200
        data = response.json()["data"]
        
        assert len(data["items"]) == 3
        assert data["total"] == 5
        assert data["total_pages"] == 2
        assert data["page"] == 1

    async def test_delete_fuel_log(
        self,
        client: AsyncClient,
        auth_headers: dict,
        vehicle: Vehicle,
    ):
        """Delete a fuel log and verify it's no longer in history."""
        # Create a log
        create_resp = await client.post(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            json={"odometer_reading": 16000, "volume_liters": 30, "price_per_liter": 90, "is_full_tank": True},
            headers=auth_headers,
        )
        log_id = create_resp.json()["data"]["id"]
        
        # Delete it
        delete_resp = await client.delete(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs/{log_id}",
            headers=auth_headers,
        )
        assert delete_resp.status_code == 204
        
        # Verify not in list
        list_resp = await client.get(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            headers=auth_headers,
        )
        log_ids = [item["id"] for item in list_resp.json()["data"]["items"]]
        assert log_id not in log_ids

    async def test_unauthenticated_request_rejected(self, client: AsyncClient, vehicle: Vehicle):
        """No auth header → 401"""
        response = await client.post(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            json={"odometer_reading": 1000, "volume_liters": 30, "price_per_liter": 90},
        )
        assert response.status_code == 401

    async def test_validation_missing_required_fields(
        self,
        client: AsyncClient,
        auth_headers: dict,
        vehicle: Vehicle,
    ):
        """Missing required fields returns 422 with field-level errors."""
        response = await client.post(
            f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
            json={"volume_liters": 30},  # Missing odometer_reading and price_per_liter
            headers=auth_headers,
        )
        assert response.status_code == 422
        errors = response.json()["errors"]
        error_fields = [e.get("field", "") for e in errors]
        assert any("odometer" in f for f in error_fields)
