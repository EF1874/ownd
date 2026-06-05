const fs = require('fs');
const path = require('path');

const backupPath = path.join(__dirname, 'imported_backup.json');
if (!fs.existsSync(backupPath)) {
  console.error('backup file not found');
  process.exit(1);
}

const data = JSON.parse(fs.readFileSync(backupPath, 'utf8'));
console.log(`Backup version: ${data.version}`);
console.log(`Total devices: ${data.devices.length}`);

data.devices.forEach((dev, index) => {
  console.log(`[${index + 1}] Device: ${dev.name}`);
  console.log(`    Category Name: ${dev.categoryName}`);
  console.log(`    Category UUID: ${dev.categoryUuid}`);
  console.log(`    Platform: ${dev.platform}`);
});
