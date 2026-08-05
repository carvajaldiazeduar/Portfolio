import pytest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from chronometer import format_time


class TestChronometer:
    def test_format_time_zero(self):
        assert format_time(0) == "00:00:00.000"

    def test_format_time_seconds(self):
        assert format_time(1) == "00:00:01.000"
        assert format_time(61.5) == "00:01:01.500"

    def test_format_time_minutes(self):
        assert format_time(60) == "00:01:00.000"
        assert format_time(3661) == "01:01:01.000"

    def test_format_time_milliseconds(self):
        assert format_time(0.001) == "00:00:00.001"
        assert format_time(0.123) == "00:00:00.123"
