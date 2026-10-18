
return {
    {
        url = "https://codeberg.org/andyg/leap.nvim",
        init = function()
            -- Mapeamentos padrão estilo "Sneak"
            vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward)')
            vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward)')
            vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)')

            -- Mapeamentos padrão "Exclusive pair"
            vim.keymap.set({'x', 'o'}, 'x', '<Plug>(leap-forward-x)')
            vim.keymap.set({'x', 'o'}, 'X', '<Plug>(leap-backward-x)')
        end,
        config = function()
            vim.cmd([[
                hi! link LeapMatch Search
                hi! link LeapLabelPrimary IncSearch
                hi! link LeapLabelSecondary Search
                hi! link LeapBackdrop Comment
            ]])

            local leap = require('leap')
            leap.opts.highlight_unlabeled_phase_one_targets = true
        end,
    },
}
