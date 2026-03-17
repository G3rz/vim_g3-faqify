# vim_g3-faqify

Neovim plugin pro prevod jednoducheho seznamu otazka/odpoved na FAQ bloky.

## Struktura

```text
vim_g3-faqify/
├─ README.md
└─ lua/
   └─ g3_faqify/
      └─ init.lua
```

## LazyVim

Do sveho LazyVim configu pridej plugin spec:

```lua
return {
  {
    "USERNAME/vim_g3-faqify",
    config = function()
      require("g3_faqify").setup()
    end,
  },
}
```

## Pouziti

Vstup je jednoduchy seznam po radcich:

```text
Otazka 1
Odpoved 1
Otazka 2
Odpoved 2
```

Prikazy:

- `:G3FaqifySuri`
- `:G3FaqifyPov`

Vizuální vyber lze zpracovat pres range prikazu nebo defaultni keymapy:

- `<leader>fqs`
- `<leader>fqp`

## Konfigurace

```lua
require("g3_faqify").setup({
  command_prefix = "G3",
  keymaps = {
    suri = "<leader>fqs",
    pov = "<leader>fqp",
  },
})
```

Keymapy lze vypnout:

```lua
require("g3_faqify").setup({
  keymaps = false,
})
```
