// Simple logger using console.log for development
const logger = {
  info: (...args) => {
    console.log(`[${new Date().toISOString()}] INFO:`, ...args);
  },
  error: (...args) => {
    console.error(`[${new Date().toISOString()}] ERROR:`, ...args);
  },
  warn: (...args) => {
    console.warn(`[${new Date().toISOString()}] WARN:`, ...args);
  },
  debug: (...args) => {
    console.debug(`[${new Date().toISOString()}] DEBUG:`, ...args);
  },
  // For morgan
  stream: {
    write: (message) => {
      console.log(`[${new Date().toISOString()}] HTTP:`, message.trim());
    },
  },
};

module.exports = logger;
