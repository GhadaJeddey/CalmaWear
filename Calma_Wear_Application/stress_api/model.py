"""
Stress Detection LSTM Model with Automatic RPM to Hz Conversion
================================================================

This is a complete, standalone file that includes:
1. RPM to Hz conversion for breathing rate
2. LSTM model definition
3. Prediction functions
4. Rule-based corrections
5. Validation

Usage:
    from stress_model_complete import StressPredictor
    
    predictor = StressPredictor(model_path='your_model.pt')
    result = predictor.predict(
        hr=85,
        rmssd=35,
        breathing_rpm=18,  # Your sensor gives RPM
        movement=0.20
    )
    print(f"Stress: {result['stress_percentage']:.1f}%")
"""

import numpy as np
import torch
import torch.nn as nn


# ============================================================================
# SENSOR PREPROCESSING - RPM TO HZ CONVERSION
# ============================================================================

def rpm_to_hz(rpm):
    """
    Convert breathing rate from RPM (Respirations Per Minute) to Hz (Hertz)
    
    Args:
        rpm: Breathing rate in respirations per minute
    
    Returns:
        hz: Breathing rate in Hertz
    
    Example:
        >>> rpm_to_hz(15)  # Normal breathing
        0.25
    """
    return rpm / 60.0


def hz_to_rpm(hz):
    """
    Convert breathing rate from Hz (Hertz) to RPM (Respirations Per Minute)
    
    Args:
        hz: Breathing rate in Hertz
    
    Returns:
        rpm: Breathing rate in respirations per minute
    """
    return hz * 60.0


def validate_sensor_data(hr, rmssd, breathing_rpm, movement):
    """
    Validate sensor data ranges
    
    Args:
        hr: Heart rate in BPM
        rmssd: RMSSD in milliseconds
        breathing_rpm: Breathing rate in RPM
        movement: Accelerometer variance
    
    Returns:
        dict with 'valid' (bool) and 'warnings' (list of strings)
    """
    warnings = []
    
    # Heart rate validation
    if hr < 30 or hr > 220:
        warnings.append(f"Heart rate {hr} BPM is outside normal range (30-220)")
    
    # RMSSD validation
    if rmssd < 0:
        warnings.append(f"RMSSD {rmssd} ms cannot be negative")
    if rmssd > 200:
        warnings.append(f"RMSSD {rmssd} ms is unusually high (>200)")
    
    # Breathing rate validation
    if breathing_rpm < 5 or breathing_rpm > 60:
        warnings.append(f"Breathing rate {breathing_rpm} RPM is outside normal range (5-60)")
    
    # Movement validation
    if movement < 0:
        warnings.append(f"Movement variance {movement} cannot be negative")
    
    return {
        'valid': len(warnings) == 0,
        'warnings': warnings
    }


# ============================================================================
# LSTM MODEL DEFINITION
# ============================================================================

class StressLSTM(nn.Module):
    """
    LSTM model for stress detection
    
    Input: (batch_size, sequence_length, 4 features)
    Features: [HR, RMSSD, breathing_Hz, movement]
    Output: Stress probability (0-1)
    """
    
    def __init__(self, input_dim=4, hidden_dim=64, num_layers=1, num_classes=2):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=input_dim,
            hidden_size=hidden_dim,
            num_layers=num_layers,
            batch_first=True
        )
        self.fc = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(32, num_classes)
        )

    def forward(self, x):
        out, (h_n, c_n) = self.lstm(x)
        h_last = h_n[-1]
        logits = self.fc(h_last)
        return logits


# ============================================================================
# NORMALIZATION PARAMETERS (from training)
# ============================================================================

PHYS_MEAN = np.array([153.80, 125.88, 1.87, 0.0006], dtype=np.float32)
PHYS_STD = np.array([13.75, 51.71, 0.08, 0.014], dtype=np.float32)
SEQ_LEN = 10


# ============================================================================
# STRESS PREDICTOR CLASS
# ============================================================================

class StressPredictor:
    """
    Complete stress predictor with automatic RPM to Hz conversion
    
    Example:
        predictor = StressPredictor(model_path='stress_model.pt')
        result = predictor.predict(hr=85, rmssd=35, breathing_rpm=18, movement=0.20)
        print(f"Stress: {result['stress_percentage']:.1f}%")
    """
    
    def __init__(self, model_path, device='cpu'):
        """
        Initialize the predictor
        
        Args:
            model_path: Path to trained model file (.pt or .pth)
            device: 'cpu' or 'cuda'
        """
        self.device = device
        self.model = StressLSTM().to(device)
        
        # Load trained weights
        try:
            self.model.load_state_dict(torch.load(model_path, map_location=device))
            self.model.eval()
            print(f"✅ Model loaded from {model_path}")
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            raise
    
    def predict(self, hr, rmssd, breathing_rpm, movement, validate=True):
        """
        Predict stress level from sensor data
        
        Args:
            hr: Heart rate in BPM
            rmssd: RMSSD in milliseconds
            breathing_rpm: Breathing rate in RPM (from sensor) - AUTOMATICALLY CONVERTED TO HZ
            movement: Accelerometer variance
            validate: Whether to validate inputs (recommended)
        
        Returns:
            dict with:
                - stress_percentage: Final stress percentage (0-100)
                - stress_level: 0=CALM, 1=MODERATE, 2=HIGH, 3=CRISIS
                - level_name: Human-readable level name
                - lstm_raw: Raw LSTM prediction
                - rule_applied: Which rule was applied
                - inputs: All input values including converted breathing_hz
        """
        # Validate inputs
        if validate:
            validation = validate_sensor_data(hr, rmssd, breathing_rpm, movement)
            if not validation['valid']:
                print("⚠️ Sensor data validation warnings:")
                for warning in validation['warnings']:
                    print(f"   {warning}")
        
        # *** AUTOMATIC RPM TO HZ CONVERSION ***
        breathing_hz = rpm_to_hz(breathing_rpm)
        
        # Create sequence (repeat same values SEQ_LEN times)
        raw_seq = np.tile(
            np.array([hr, rmssd, breathing_hz, movement]),
            (SEQ_LEN, 1)
        )
        
        # Normalize
        scaled = self._normalize(raw_seq)
        
        # Predict with LSTM
        x = torch.tensor(scaled.reshape(1, SEQ_LEN, 4), dtype=torch.float32).to(self.device)
        
        with torch.no_grad():
            logits = self.model(x)
            prob = torch.softmax(logits, dim=1)[0, 1].item()
            lstm_stress_pct = prob * 100.0
        
        # Apply rule-based correction
        final_stress, level, rule = self._apply_rules(
            hr, rmssd, breathing_hz, movement, lstm_stress_pct
        )
        
        return {
            'stress_percentage': final_stress,
            'stress_level': level,
            'level_name': self._get_level_name(level),
            'lstm_raw': lstm_stress_pct,
            'rule_applied': rule,
            'inputs': {
                'hr': hr,
                'rmssd': rmssd,
                'breathing_rpm': breathing_rpm,  # Original RPM
                'breathing_hz': breathing_hz,    # Converted Hz
                'movement': movement
            }
        }
    
    def _normalize(self, X):
        """Normalize features using training statistics"""
        return ((X - PHYS_MEAN) / PHYS_STD).astype(np.float32)
    
    def _apply_rules(self, hr, rmssd, breath_hz, movement, lstm_pct):
        """Apply rule-based corrections for edge cases"""
        
        # SPORT OVERRIDE - High movement + high HRV = exercising, not stressed
        if movement > 0.9 and rmssd > 40:
            return 5.0, 0, "SPORT"
        
        # PANIC OVERRIDE - Very high HR + very low HRV + no movement = panic
        if hr > 120 and rmssd < 8 and movement < 0.4:
            return 95.0, 3, "PANIC"
        
        # HIGH STRESS OVERRIDE
        if hr > 100 and rmssd < 20 and movement < 0.4:
            return 75.0, 2, "HIGH_STRESS"
        
        # SLEEP OVERRIDE - Low HR + high HRV + no movement = sleeping
        if hr < 60 and rmssd > 70 and movement < 0.1:
            return 2.0, 0, "SLEEP"
        
        # LIGHT ACTIVITY CAP - Moderate HR + good HRV = talking/light activity
        if 80 < hr < 100 and rmssd > 30 and movement < 0.4:
            return min(lstm_pct, 25.0), 1, "LIGHT_ACTIVITY"
        
        # DEFAULT - TRUST LSTM
        level = (
            0 if lstm_pct < 20 else
            1 if lstm_pct < 40 else
            2 if lstm_pct < 70 else
            3
        )
        return lstm_pct, level, "LSTM"
    
    def _get_level_name(self, level):
        """Get human-readable level name"""
        names = {0: "CALM", 1: "MODERATE", 2: "HIGH", 3: "CRISIS"}
        return names.get(level, "UNKNOWN")


# ============================================================================
# STANDALONE PREDICTION FUNCTION (Alternative to using the class)
# ============================================================================

def predict_stress(model, hr, rmssd, breathing_rpm, movement, device='cpu'):
    """
    Standalone prediction function with automatic RPM to Hz conversion
    
    Args:
        model: Trained StressLSTM model
        hr: Heart rate in BPM
        rmssd: RMSSD in milliseconds
        breathing_rpm: Breathing rate in RPM (automatically converted to Hz)
        movement: Accelerometer variance
        device: 'cpu' or 'cuda'
    
    Returns:
        dict with prediction results
    """
    # Convert RPM to Hz
    breathing_hz = rpm_to_hz(breathing_rpm)
    
    # Create sequence
    raw_seq = np.tile(
        np.array([hr, rmssd, breathing_hz, movement]),
        (SEQ_LEN, 1)
    )
    
    # Normalize
    scaled = ((raw_seq - PHYS_MEAN) / PHYS_STD).astype(np.float32)
    
    # Predict
    x = torch.tensor(scaled.reshape(1, SEQ_LEN, 4), dtype=torch.float32).to(device)
    
    model.eval()
    with torch.no_grad():
        logits = model(x)
        prob = torch.softmax(logits, dim=1)[0, 1].item()
        stress_pct = prob * 100.0
    
    return {
        'stress_percentage': stress_pct,
        'breathing_rpm': breathing_rpm,
        'breathing_hz': breathing_hz
    }


# ============================================================================
# USAGE EXAMPLES
# ============================================================================

if __name__ == "__main__":
    print("\n" + "=" * 70)
    print("STRESS DETECTION MODEL - COMPLETE WITH RPM CONVERSION")
    print("=" * 70)
    
    print("\n📖 USAGE EXAMPLES:\n")
    
    print("Example 1: Using StressPredictor class (RECOMMENDED)")
    print("-" * 70)
    print("""
    from stress_model_complete import StressPredictor
    
    # Load model once
    predictor = StressPredictor(model_path='your_model.pt')
    
    # Predict with RPM input (from sensor)
    result = predictor.predict(
        hr=85,              # Heart rate in BPM
        rmssd=35,           # RMSSD in ms
        breathing_rpm=18,   # Breathing in RPM (from sensor)
        movement=0.20       # Movement variance
    )
    
    print(f"Stress: {result['stress_percentage']:.1f}%")
    print(f"Level: {result['level_name']}")
    print(f"Breathing: {result['inputs']['breathing_rpm']} RPM = "
          f"{result['inputs']['breathing_hz']:.2f} Hz")
    """)
    
    print("\nExample 2: Just convert RPM to Hz")
    print("-" * 70)
    print("""
    from stress_model_complete import rpm_to_hz
    
    breathing_rpm = 18  # From sensor
    breathing_hz = rpm_to_hz(breathing_rpm)
    print(f"{breathing_rpm} RPM = {breathing_hz:.4f} Hz")
    # Output: 18 RPM = 0.3000 Hz
    """)
    
    print("\nExample 3: Real-time sensor loop")
    print("-" * 70)
    print("""
    predictor = StressPredictor(model_path='your_model.pt')
    
    while True:
        # Read from your sensor
        sensor_data = your_sensor.read()
        
        # Predict (RPM automatically converted to Hz)
        result = predictor.predict(
            hr=sensor_data['heart_rate'],
            rmssd=sensor_data['rmssd'],
            breathing_rpm=sensor_data['breathing_rpm'],  # RPM from sensor
            movement=sensor_data['movement']
        )
        
        if result['stress_level'] >= 2:
            print(f"⚠️ High stress: {result['stress_percentage']:.1f}%")
    """)
    
    print("\n" + "=" * 70)
    print("✅ This file includes EVERYTHING you need!")
    print("=" * 70)
    print("\nFeatures:")
    print("  ✓ Automatic RPM to Hz conversion")
    print("  ✓ LSTM model definition")
    print("  ✓ Sensor data validation")
    print("  ✓ Rule-based corrections")
    print("  ✓ Easy-to-use StressPredictor class")
    print("\n" + "=" * 70 + "\n")
