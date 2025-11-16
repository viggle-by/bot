#!/bin/bash

echo "=== Sigmabot Electron + Canvas Setup ==="

# Step 1: Initialize npm project
if [ ! -f package.json ]; then
  echo "Initializing npm project..."
  npm init -y
fi

# Step 2: Install dependencies
echo "Installing dependencies..."
npm install mineflayer mineflayer-pathfinder prismarine-viewer express vec3 minecraft-data canvas
npm install --save-dev electron

# Step 3: Create sigmabot.js
echo "Creating sigmabot.js..."
cat > sigmabot.js << 'EOF'
const mineflayer = require('mineflayer');
const { pathfinder, Movements } = require('mineflayer-pathfinder');
const Vec3 = require('vec3');

const BOT_OWNER = 'YeeGigtek';
const DISCORD_PREFIX = `[Discord] ${BOT_OWNER} »`;

const options = [
  { host: 'chipmunk.land', port: 25565, username: '§§ChatBridge1§§', version: '1.19.1', showIpAs: 'server1' },
  { host: 'kaboom.pw', port: 25565, username: '§§ChatBridge2§§', version: '1.19.1', showIpAs: 'server2' },
  { host: 'ayunboom.shhnowisnottheti.me', port: 25565, username: '§§ChatBridge3§§', version: '1.19.1', showIpAs: 'server3' },
  { host: '168.100.225.224', port: 25565, username: '§§ChatBridge4§§', version: '1.19.1', showIpAs: 'server4' }
];

const bots = [];

function startBot(callback) {
  function createBot(option) {
    const bot = mineflayer.createBot({
      host: option.host,
      port: option.port,
      username: option.username,
      version: option.version
    });

    bot.showIpAs = option.showIpAs;
    bot.loadPlugin(pathfinder);

    bot.once('spawn', () => {
      console.log(`[${bot.showIpAs}] Connected.`);
      const mcData = require('minecraft-data')(bot.version);
      const defaultMove = new Movements(bot, mcData);
      bot.pathfinder.setMovements(defaultMove);
      if (callback) callback({ bot, server: bot.showIpAs });
    });

    bot.on('chat', (username, message) => {
      if (username === bot.username) return;
      if (message.startsWith(DISCORD_PREFIX)) return;

      if (message.startsWith('!dmsg ')) {
        const content = message.slice(6);
        const formattedMessage = `[${bot.showIpAs}] ${DISCORD_PREFIX} ${content}`;
        bots.forEach(b => {
          if (b.username && b.showIpAs !== bot.showIpAs) {
            b.chat(formattedMessage);
          }
        });
        if (callback) callback({ message: formattedMessage });
      }
    });

    bot.on('error', err => console.log(`[${bot.showIpAs}] Error: ${err.message}`));
    bot.on('end', () => {
      console.log(`[${bot.showIpAs}] Disconnected. Reconnecting in 5s...`);
      setTimeout(() => createBot(option), 5000);
    });

    bots.push(bot);
  }

  options.forEach(opt => createBot(opt));
}

module.exports = startBot;
EOF

# Step 4: Create server.js
echo "Creating server.js..."
cat > server.js << 'EOF'
const startBot = require('./sigmabot');
const { mineflayer: prismarineViewer } = require('prismarine-viewer');

startBot(({ bot }) => {
  if (bot) {
    prismarineViewer(bot, { canvas: 'canvas' }).then(botViewer => {
      window.botViewer = botViewer; // allow WASD control
    });
  }
});
EOF

# Step 5: Create viewer.html
echo "Creating viewer.html..."
cat > viewer.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Sigmabot Viewer</title>
<style>
  body { margin: 0; background: #111; overflow: hidden; }
  canvas { display: block; width: 100vw; height: 100vh; }
</style>
</head>
<body>
  <canvas id="canvas"></canvas>
  <script src="https://unpkg.com/three/build/three.min.js"></script>
  <script>
    const canvas = document.getElementById('canvas');
    const keys = { w: false, a: false, s: false, d: false, space: false };

    window.addEventListener('keydown', e => {
      if (keys[e.key.toLowerCase()] !== undefined) keys[e.key.toLowerCase()] = true;
    });
    window.addEventListener('keyup', e => {
      if (keys[e.key.toLowerCase()] !== undefined) keys[e.key.toLowerCase()] = false;
    });

    function updateControls(botViewer) {
      if (!botViewer) return;
      botViewer.controls.forward = keys.w;
      botViewer.controls.back = keys.s;
      botViewer.controls.left = keys.a;
      botViewer.controls.right = keys.d;
      botViewer.controls.jump = keys.space;
      requestAnimationFrame(() => updateControls(botViewer));
    }

    window.addEventListener('load', () => {
      if (window.botViewer) updateControls(window.botViewer);
    });
  </script>
</body>
</html>
EOF

# Step 6: Create main.js for Electron
echo "Creating main.js..."
cat > main.js << 'EOF'
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 720,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  win.loadFile('viewer.html');
  // win.webContents.openDevTools(); // optional
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
EOF

# Step 7: Create start.sh
echo "Creating start.sh..."
cat > start.sh << 'EOF'
#!/bin/bash
npm run start
EOF
chmod +x start.sh

echo "=== Setup Complete ==="
echo "Run './start.sh' to launch Sigmabot in Electron with Prismarine Viewer and WASD controls."

