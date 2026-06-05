const fs = require('fs');
const readline = require('readline');

const logPath = 'C:\\Users\\lee\\.gemini\\antigravity\\brain\\3591071c-09cd-4cce-8a00-8abd5acec2b8\\.system_generated\\logs\\transcript.jsonl';

async function main() {
  const fileStream = fs.createReadStream(logPath);
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });

  let index = 1;
  for await (const line of rl) {
    try {
      const step = JSON.parse(line);
      if (step.type === 'USER_INPUT') {
        if (index <= 6) {
          console.log(`\n--- USER INPUT #${index} (Step ${step.step_index}) ---`);
          console.log(step.content);
        }
        index++;
      }
    } catch (e) {
      // ignore
    }
  }
}

main();
