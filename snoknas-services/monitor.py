from flask import Flask, jsonify, request
import subprocess
import json
import shutil
import psutil

app = Flask(__name__)

# --- Helper Functions ---
def get_disk_health(disk_path):
    # Simulate SMART data for now or use smartctl
    # In a real scenario, we run: smartctl -H -A -j disk_path
    try:
        # Check if smartctl exists
        if not shutil.which("smartctl"):
            return "unknown", 0, 0
        
        # Run smartctl
        cmd = ["smartctl", "-H", "-A", "-j", disk_path]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        data = json.loads(result.stdout)
        
        passed = data.get("smart_status", {}).get("passed")
        health = "Healthy" if passed else "Critical"
        
        temp = 0
        temperature_data = data.get("temperature", {})
        temp = temperature_data.get("current", 0)
        
        # Calculate a health score (simplified logic)
        score = 100
        if not passed:
            score = 0
        elif temp > 50:
            score -= 20
        
        return health, temp, score
    except Exception as e:
        return "Unknown", 0, 0

@app.route('/api/disks', methods=['GET'])
def get_disks():
    disks = []
    # List physical partitions/disks
    partitions = psutil.disk_partitions()
    for p in partitions:
        usage = psutil.disk_usage(p.mountpoint)
        # Identify physical device (simplified)
        device = p.device
        
        health, temp, score = get_disk_health(device)
        
        disk_info = {
            "device": device,
            "mountpoint": p.mountpoint,
            "total_gb": round(usage.total / (1024**3), 2),
            "used_gb": round(usage.used / (1024**3), 2),
            "percent": usage.percent,
            "health": health,
            "temperature": temp,
            "health_score": score,
            "smart_status": "Good" if score > 80 else "Warning"
        }
        disks.append(disk_info)
    
    return jsonify({"disks": disks})

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "running", "service": "snoknas-monitor"})

@app.route('/api/system', methods=['GET'])
def system_info():
    return jsonify({
        "cpu_percent": psutil.cpu_percent(),
        "memory_percent": psutil.virtual_memory().percent,
        "hostname": "snoknas" # Should get real hostname
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
