# VS Code Setup

## Extensions

*Here is my list for VS Code extensions that I use mostly.*

* https://marketplace.visualstudio.com/items?itemName=Equinusocio.vsc-material-theme
* https://marketplace.visualstudio.com/items?itemName=robinbentley.sass-indented
* https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer
* https://marketplace.visualstudio.com/items?itemName=HookyQR.beautify
* https://marketplace.visualstudio.com/items?itemName=spywhere.guides
* https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode

---

## User Settings

*And my settings (they may be can change from time to time)*

```javascript 
{
  // EDITOR  
  "editor.tabSize": 2,
  "editor.fontSize": 14,
  "editor.lineHeight": 21,
  "editor.fontWeight": "100",
  // "editor.fontFamily": "Operator Mono, Menlo, monospace",
  "editor.minimap.renderCharacters": false,
  "editor.minimap.enabled": true,
  "editor.tabCompletion": true,
  "editor.glyphMargin": false,
  "editor.wordWrap": "on",
  "editor.renderWhitespace": "all",
  "workbench.activityBar.visible": true,
  "workbench.statusBar.visible": false,
  "explorer.openEditors.visible": 0,
  "window.title": "${dirty} ${activeEditorMedium}${separator}${rootName}",
  
  // THEME
  "workbench.iconTheme": "vs-minimal",
  "workbench.colorTheme": "One Dark Pro",
  "monokaiPro.fileIconsMonochrome": true,
  
  // TERMINAL
  "terminal.integrated.lineHeight": 1.1,
  // "terminal.integrated.fontSize": 14,
  // "terminal.integrated.fontWeight": "100",
  "terminal.integrated.shell.osx": "/bin/zsh",
  // "terminal.integrated.fontFamily": "Operator Mono, Menlo, monospace",
  
  // FILES
  "files.defaultLanguage": "html",
  "files.exclude": {
    "**/.hg": true,
    "**/CVS": true,
    "**/.git": true,
    "**/.svn": true,
    "**/.next": true,
    "**/.DS_Store": true,
    "node_modules/": true,
    "package-lock.json": true
  },

  // PRETTIER
  "prettier.singleQuote": true,

  // EXTENSIONS
  "extensions.autoUpdate": true,
  "[javascript]": {
    "editor.rulers": [
      80,
      120
    ]
  }
}
```

