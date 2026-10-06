
return {
    {
        url = "https://codeberg.org/andyg/leap.nvim",
        config = function()
            local leap = require('leap')

            -- Mapeamentos padrão estilo "Sneak"
            vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward)')
            vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)')
            vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)')

            -- Mapeamentos padrão "Exclusive pair"
            vim.keymap.set({'x', 'o'}, 'x', '<Plug>(leap-forward-x)')
            vim.keymap.set({'x', 'o'}, 'X', '<Plug>(leap-backward-x)')

            -- Sua configuração original
            leap.opts.highlight_unlabeled_phase_one_targets = true
        end,
    },
}
