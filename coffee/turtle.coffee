###
000000000  000   000  00000000   000000000  000      00000000
   000     000   000  000   000     000     000      000     
   000     000   000  0000000       000     000      0000000 
   000     000   000  000   000     000     000      000     
   000      0000000   000   000     000     0000000  00000000
###

shortcut      = require 'global-shortcut'
path          = require 'path'
app           = require 'app'
ipc           = require("electron").ipcMain
fs            = require 'fs'
events        = require 'events'
Tray          = require 'tray'
BrowserWindow = require 'browser-window'
Menu          = require 'menu'

debug = false
win   = undefined
tray  = undefined
    
ipc.on 'console.log',   (event, args) -> console.log.apply console, args
ipc.on 'console.error', (event, args) -> console.log.apply console, args
ipc.on 'process.exit',  (event, code) -> console.log 'exit via ipc';  process.exit code
    
noToggle = false 
ipc.on 'enableToggle', -> noToggle = false
ipc.on 'disableToggle', -> noToggle = true
ipc.on 'globalShortcut', (event, key) -> 
    shortcut.unregisterAll()
    shortcut.register key, toggleWindow
     
###
 0000000  000   000   0000000   000   000
000       000   000  000   000  000 0 000
0000000   000000000  000   000  000000000
     000  000   000  000   000  000   000
0000000   000   000   0000000   00     00
###

showWindow = () ->
    win.show() unless win.isVisible()
    win.setResizable debug
    win

###
000000000   0000000    0000000    0000000   000      00000000
   000     000   000  000        000        000      000     
   000     000   000  000  0000  000  0000  000      0000000 
   000     000   000  000   000  000   000  000      000     
   000      0000000    0000000    0000000   0000000  00000000
###

toggleWindow = () ->
    return if noToggle
    if win && win.isVisible()
        win.hide()
    else
        win.show()

createWindow = () ->
    
    app.on 'hide', () -> console.log 'hide!'
    
    app.on 'ready', () ->

        if app.dock then app.dock.hide()
        
        Menu.setApplicationMenu Menu.buildFromTemplate [
            label: app.getName()
            submenu: [
                label: 'Cut'
                accelerator: 'CmdOrCtrl+X'
                selector: 'cut:'
            ,
                label: 'Copy'
                accelerator: 'CmdOrCtrl+C'
                selector: 'copy:'
            ,
                label: 'Paste'
                accelerator: 'CmdOrCtrl+V'
                selector: 'paste:'
            ,
                label: 'Select All'
                accelerator: 'Command+A'
                selector: 'selectAll:'            
            ,
                label: 'Quit'
                accelerator: 'Command+Q'
                click: app.quit
            ]
        ]
        
        cwd = path.join __dirname, '..'
        
        iconFile = path.join cwd, 'img', 'menuicon.png'

        tray = new Tray iconFile
        
        tray.on 'click', toggleWindow

        # 000   000  000  000   000
        # 000 0 000  000  0000  000
        # 000000000  000  000 0 000
        # 000   000  000  000  0000
        # 00     00  000  000   000

        screenSize = (require 'screen').getPrimaryDisplay().workAreaSize
        windowWidth = 364
        x = Number(((screenSize.width-windowWidth)/2).toFixed())
        y = 0

        values = loadPrefs()
        if values.winpos?
            x = values.winpos[0]
            y = values.winpos[1]

        win = new BrowserWindow
            dir:           cwd
            preloadWindow: true
            x:             x
            y:             y
            width:         windowWidth
            height:        360
            frame:         false

        try
            if values?.shortcut != ''
                shortcut.register (values?.shortcut or 'ctrl+`'), toggleWindow
        catch err
            console.log 'shortcut installation failed', err

        win.loadURL 'file://' + cwd + '/turtle.html'
        
        if not debug
            win.on 'blur', win.hide
            
        setTimeout showWindow, 100
              
createWindow()            
  
###
00000000   00000000   00000000  00000000   0000000
000   000  000   000  000       000       000     
00000000   0000000    0000000   000000    0000000 
000        000   000  000       000            000
000        000   000  00000000  000       0000000 
###

prefsFile = process.env.HOME+'/Library/Preferences/password-turtle.json'

loadPrefs = () ->
    try
        return JSON.parse(fs.readFileSync(prefsFile, encoding:'utf8'))
    catch err     
        return {}

savePrefs = (values) ->
    fs.writeFileSync prefsFile, jsonStr(values), encoding:'utf8'
