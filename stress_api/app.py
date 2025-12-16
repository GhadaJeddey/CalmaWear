import torch
import numpy as np
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Enable CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --------------------------
# Load TorchScript LSTM model
# --------------------------
model = torch.jit.load("stress_lstm_cpu.pt", map_location="cpu")
model.eval()

# --------------------------
# ESTIMATED NORMALIZATION VALUES
# Based on typical physiological ranges
# --------------------------
# Mean values for [HR, BR, Temp, Motion]
PHYS_MEAN = np.array([75.0, 18.0, 36.5, 50.0], dtype=np.float32)

# Standard deviation values
PHYS_STD = np.array([15.0, 5.0, 0.5, 25.0], dtype=np.float32)

class SequenceInput(BaseModel):
    sequence: list

@app.post("/predict")
def predict(data: SequenceInput):
    seq = np.array(data.sequence, dtype=np.float32)

    if seq.ndim != 2 or seq.shape[1] != 4:
        return {"error": "sequence must have shape [T, 4]"}
    
    # DEBUG: Print raw input
    print(f"📥 Raw input (first): HR={seq[0,0]}, BR={seq[0,1]}, Temp={seq[0,2]}, Motion={seq[0,3]}")
    print(f"📥 Raw input (avg): HR={np.mean(seq[:,0]):.1f}, BR={np.mean(seq[:,1]):.1f}")
    
    # NORMALIZE THE INPUT (This was missing!)
    seq_normalized = (seq - PHYS_MEAN) / PHYS_STD
    
    # DEBUG: Print normalized
    print(f"📊 Normalized (avg): HR={np.mean(seq_normalized[:,0]):.2f}, BR={np.mean(seq_normalized[:,1]):.2f}")

    # Convert to tensor for LSTM: (batch, seq_len, features)
    x = torch.tensor(seq_normalized, dtype=torch.float32).unsqueeze(0)

    with torch.no_grad():
        logits = model(x)
        probs = torch.softmax(logits, dim=1)
        stress_percent = float(probs[0, 1].item() * 100)
        
        # DEBUG: Print model outputs
        print(f"🧠 Model outputs:")
        print(f"   Logits: {logits[0].tolist()}")
        print(f"   Probabilities: Class 0={probs[0,0].item()*100:.2f}%, Class 1={probs[0,1].item()*100:.2f}%")

    # Rule-based level
    if stress_percent < 20:
        level = 0
    elif stress_percent < 40:
        level = 1
    elif stress_percent < 70:
        level = 2
    else:
        level = 3
    
    print(f"🎯 Final: {stress_percent:.2f}% stress, Level {level}")
    print("-" * 40)

    return {
        "stress_percent": stress_percent,
        "level": level
    }