from flask import Flask, jsonify
import subprocess
import os

app = Flask(__name__)

REPO_URL = "https://github.com/SnokOS/SnokNAS_V2" # Example repo
SCRIPT_PATH = "/usr/local/bin/snoknas-update.sh"

@app.route('/api/check-update', methods=['GET'])
def check_update():
    # Simulate checking git remote
    # In real world: git ls-remote tags...
    return jsonify({"has_update": False, "version": "1.0.0", "latest": "1.0.0"})

@app.route('/api/apply-update', methods=['POST'])
def apply_update():
    # Trigger update script
    # Ensure backup before update
    try:
        # subprocess.Popen([SCRIPT_PATH]) # Run in background
        return jsonify({"status": "updating", "message": "Update started. System will restart."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/version', methods=['GET'])
def version():
    return jsonify({"version": "v1.0.0"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
