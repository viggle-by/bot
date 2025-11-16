const { app, BrowserWindow } = require('electron');
const path = require('path');
const express = require('express');
const startBot = require('./sigmabot');
const { mineflayer: prismarineViewer } = require('prismarine-viewer');

// Ports
const VIEWER_PORT = 6767;
const ELECTRON_PORT = 3000; // optional, if serving Electron content via express

// ===== Express Server for Prismarine Viewer =====
const viewerServer = express();
viewerServer.use(express.static(path.join(__dirname)));
viewerServer.listen(VIEWER_PORT, () => {
  console.log(`Prismarine Viewer running on http://localhost:${VIEWER_PORT}`);
});

// ===== Electron Window =====
let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 720,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  // Electron loads the Prismarine Viewer
  mainWindow.loadURL(`http://localhost:${VIEWER_PORT}/viewer.html`);
  // mainWindow.webContents.openDevTools(); // optional
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });

  // Start bot after window is ready
  startBot(({ bot }) => {
    if (bot) {
      global.botViewer = prismarineViewer(bot, { canvas: 'canvas' });
      console.log(`[${bot.showIpAs}] Prismarine Viewer attached.`);
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
