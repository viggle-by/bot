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
