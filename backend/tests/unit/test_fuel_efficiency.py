"""
FuelIQ — Unit Tests: Fuel Efficiency Calculator
"""
import pytest
from decimal import Decimal

from app.modules.fuel.fuel_service import FuelEfficiencyCalculator


class TestFuelEfficiencyCalculator:
    """
    Tests for the efficiency calculation engine.
    These are pure unit tests — no DB, no IO.
    """

    def setup_method(self):
        self.calc = FuelEfficiencyCalculator()

    # ─── L/100km Tests ────────────────────────────────────────────────────────

    def test_lper100km_standard_case(self):
        """Standard calculation: 35L over 400km = 8.75 L/100km"""
        result = self.calc.calculate_lper100km(Decimal("400"), Decimal("35"))
        assert result == Decimal("8.750")

    def test_lper100km_efficient_vehicle(self):
        """Efficient vehicle: 25L over 600km = 4.167 L/100km"""
        result = self.calc.calculate_lper100km(Decimal("600"), Decimal("25"))
        assert result == Decimal("4.167")

    def test_lper100km_zero_distance_returns_none(self):
        """Zero distance should return None (not divide-by-zero)"""
        result = self.calc.calculate_lper100km(Decimal("0"), Decimal("35"))
        assert result is None

    def test_lper100km_zero_volume_returns_none(self):
        result = self.calc.calculate_lper100km(Decimal("400"), Decimal("0"))
        assert result is None

    def test_lper100km_negative_distance_returns_none(self):
        result = self.calc.calculate_lper100km(Decimal("-100"), Decimal("35"))
        assert result is None

    def test_lper100km_precision_3_decimals(self):
        """Results should be rounded to 3 decimal places"""
        result = self.calc.calculate_lper100km(Decimal("333"), Decimal("30"))
        assert result is not None
        assert len(str(result).split('.')[-1]) <= 3

    # ─── km/L Tests ───────────────────────────────────────────────────────────

    def test_kmperliter_standard_case(self):
        """Standard: 400km on 35L = 11.429 km/L"""
        result = self.calc.calculate_kmperliter(Decimal("400"), Decimal("35"))
        assert result == Decimal("11.429")

    def test_kmperliter_high_efficiency(self):
        """High efficiency: 600km on 25L = 24 km/L"""
        result = self.calc.calculate_kmperliter(Decimal("600"), Decimal("25"))
        assert result == Decimal("24.000")

    def test_kmperliter_zero_volume_returns_none(self):
        result = self.calc.calculate_kmperliter(Decimal("400"), Decimal("0"))
        assert result is None

    # ─── MPG Tests ────────────────────────────────────────────────────────────

    def test_mpg_calculation(self):
        """400km on 35L should give approximately 32.5 MPG"""
        result = self.calc.calculate_mpg(Decimal("400"), Decimal("35"))
        assert result is not None
        assert 30 < float(result) < 35

    def test_consistency_lper100km_kmperliter(self):
        """L/100km and km/L should be inversely consistent"""
        distance = Decimal("400")
        volume = Decimal("35")
        
        lper100 = self.calc.calculate_lper100km(distance, volume)
        kmperl = self.calc.calculate_kmperliter(distance, volume)
        
        assert lper100 is not None
        assert kmperl is not None
        
        # km/L ≈ 100 / (L/100km)
        expected_kmperl = Decimal("100") / lper100
        diff = abs(kmperl - expected_kmperl)
        assert diff < Decimal("0.01")  # Within 0.01 km/L tolerance


class TestFuelEfficiencyEdgeCases:
    """Edge cases and boundary conditions."""

    def setup_method(self):
        self.calc = FuelEfficiencyCalculator()

    def test_very_small_fill(self):
        """Very small fill (0.1L) should not crash"""
        result = self.calc.calculate_lper100km(Decimal("10"), Decimal("0.1"))
        assert result == Decimal("1.000")

    def test_very_large_values(self):
        """Large values (truck tank) should compute correctly"""
        result = self.calc.calculate_lper100km(Decimal("5000"), Decimal("500"))
        assert result == Decimal("10.000")

    def test_extremely_high_consumption(self):
        """200L over 100km (unrealistic but shouldn't crash)"""
        result = self.calc.calculate_lper100km(Decimal("100"), Decimal("200"))
        assert result == Decimal("200.000")
