import { app, BrowserWindow, ipcMain, shell } from 'electron'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { applyCodexConfig } from './codex-config'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const createWindow = () => {
  const win = new BrowserWindow({
    width: 460,
    height: 420,
    resizable: false,
    title: 'Codex Setup',
    backgroundColor: '#0e0e11',
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    trafficLightPosition: { x: 16, y: 16 },
    webPreferences: {
      preload: path.join(__dirname, 'preload.mjs'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  })

  if (process.env.VITE_DEV_SERVER_URL) {
    win.loadURL(process.env.VITE_DEV_SERVER_URL)
  } else {
    win.loadFile(path.join(__dirname, '../dist/index.html'))
  }
}

app.whenReady().then(() => {
  ipcMain.handle('codex:apply', async (_evt, apiKey: string) => {
    return applyCodexConfig(apiKey)
  })

  ipcMain.handle('shell:openExternal', async (_evt, url: string) => {
    if (/^https?:\/\//i.test(url)) {
      await shell.openExternal(url)
    }
  })

  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})
