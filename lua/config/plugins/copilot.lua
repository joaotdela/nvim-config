return {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
        require('copilot').setup {
            suggestion = {
                enabled = true,
                auto_trigger = true,
                keymap = {
                    accept = '<C-l>', -- Aceita a sugestão com Ctrl+l (para não conflitar com o Tab do blink.cmp)
                    accept_word = false,
                    accept_line = false,
                    next = '<M-]>',
                    prev = '<M-[>',
                    dismiss = '<C-]>',
                },
            },
            panel = { enabled = false },
        }
    end,
}
