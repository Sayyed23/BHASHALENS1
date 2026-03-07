"""
Shared Circuit Breaker utility
"""
import time
import logging

logger = logging.getLogger(__name__)

from enum import Enum
import threading

class CircuitState(Enum):
    CLOSED = "CLOSED"
    OPEN = "OPEN"
    HALF_OPEN = "HALF_OPEN"

class CircuitBreaker:
    def __init__(self, failure_threshold=3, recovery_timeout=60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = 0
        self.state = CircuitState.CLOSED
        self._lock = threading.Lock()
        self._half_open_test_in_progress = False
    def record_success(self):
        """Reset the breaker on success"""
        with self._lock:
            self.failure_count = 0
            self.state = "CLOSED"
            self._half_open_test_in_progress = False

    def record_failure(self):
        """Record a failure and potentially open the breaker"""
        with self._lock:
            if self.state == "HALF_OPEN":
                self.state = "OPEN"
                self.last_failure_time = time.time()
                self._half_open_test_in_progress = False
                logger.warning("Circuit Breaker re-OPENED after HALF_OPEN test failure")
                return
            
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"
                logger.warning(f"Circuit Breaker OPENED after {self.failure_count} failures")
    def is_allowed(self) -> bool:
        """Check if calls are currently allowed"""
        with self._lock:
            if self.state == "CLOSED" or self.state == CircuitState.CLOSED:
                return True
                
            if self.state == CircuitState.OPEN:
                # Check if enough time has passed to transition to HALF_OPEN
                if time.time() - self.last_failure_time > self.recovery_timeout:
                    self.state = CircuitState.HALF_OPEN
                    self._half_open_test_in_progress = True
                    logger.info("Circuit Breaker transitioned to HALF_OPEN")
                    return True
                return False
                
            if self.state == CircuitState.HALF_OPEN:
                if not self._half_open_test_in_progress:
                    self._half_open_test_in_progress = True
                    return True
                return False
                
            return False
