# Stable Neovim Config

This is my current stable Neovim configuration (the old setup was renamed to `neovim-old`).

I use a custom, lightweight plugin manager (`packload`) inspired by `lazy.nvim`.
I wrote the core engine, validator, and types, while an LLM generated the UI and type documentation. 
Cold startup time sits around **~25ms** on my machine.

### Project Structure

```bash
$ tree -I "tests|.git|lsp|README.md"
.
├── after
│   └── ftplugin
│       ├── java.lua
│       ├── python.lua
│       └── qml.lua
├── init.lua
├── lua
│   ├── config
│   │   ├── debug.lua
│   │   ├── init.lua
│   │   └── utils
│   │       ├── dotnet
│   │       │   └── avalonia.lua
│   │       ├── lsp.lua
│   │       ├── togglebool.lua
│   │       └── toggleTerm.lua
│   ├── core
│   │   ├── keymaps.lua
│   │   ├── lsp.lua
│   │   └── set.lua
│   ├── init.lua
│   ├── nvim.log
│   ├── packload
│   │   ├── init.lua
│   │   ├── status.lua
│   │   ├── types.lua
│   │   └── validate.lua
│   ├── plugins
│   │   ├── extras.lua
│   │   ├── ui.lua
│   │   └── utility.lua
│   └── statusline.lua
└── nvim-pack-lock.json

10 directories, 24 files

```


