# mostly gpt generated

import torch
import socket
import struct

# === load model ===
model = torch.load('model.pt')
model.eval()

# === create input ===
# example input, replace with real data
x = torch.randn(1, 10)  # shape should match model input

# === run model prediction ===
with torch.no_grad():
    out = model(x)
    pred = (out > 0.5).int().item()  # assumes sigmoid output

# === save prediction ===
with open("pred.txt", "w") as f:
    f.write(str(pred))

# === udp send ===
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(1.0)

host = "127.0.0.1"
port = 12345

# pack input to bytes (example: float32 array)
payload = struct.pack(f"{x.numel()}f", *x.squeeze().tolist())
sock.sendto(payload, (host, port))

# === udp receive ===
try:
    data, _ = sock.recvfrom(1024)
    remote_pred = struct.unpack("i", data[:4])[0]  # assumes int32 response
except socket.timeout:
    remote_pred = None

# === compare ===
if remote_pred is None:
    print("no response")
elif remote_pred == pred:
    print("match")
else:
    print("mismatch: local =", pred, ", remote =", remote_pred)
