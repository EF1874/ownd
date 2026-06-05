const fs = require('fs');
const path = require('path');
const os = require('os');

const localJsonPath = path.join(__dirname, '..', 'ownd-app', 'config', 'local.json');

function getLocalIp() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        const lowerName = name.toLowerCase();
        if (lowerName.includes('wlan') || lowerName.includes('wi-fi') || lowerName.includes('ethernet') || lowerName.includes('本地') || lowerName.includes('无线')) {
          return net.address;
        }
      }
    }
  }
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return '127.0.0.1';
}

const localIp = getLocalIp();

// Write to ownd-app/config/local.json
const localConfig = {
  "OWND_API_BASE_URL": `http://${localIp}:3000/api/v1`
};
fs.mkdirSync(path.dirname(localJsonPath), { recursive: true });
fs.writeFileSync(localJsonPath, JSON.stringify(localConfig, null, 2) + '\n', 'utf8');
console.log(`[IP Logger] Saved local JSON config to ${localJsonPath}`);
