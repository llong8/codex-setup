import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('codexAPI', {
  apply: (apiKey: string) => ipcRenderer.invoke('codex:apply', apiKey),
  openExternal: (url: string) => ipcRenderer.invoke('shell:openExternal', url),
})
