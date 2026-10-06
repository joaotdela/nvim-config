return {
    'olimorris/codecompanion.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-treesitter/nvim-treesitter',
        'zbirenbaum/copilot.lua',
        'ravitemer/codecompanion-history.nvim',
    },
    config = function()
        vim.api.nvim_create_autocmd('User', {
            pattern = 'CodeCompanionChatCreated',
            callback = function(ev)
                local chat = require('codecompanion').buf_get_chat(ev.data.bufnr)
                if chat and chat.adapter and chat.adapter.name == 'copilot' then chat.tool_registry:add_group 'agent' end
            end,
        })

        require('codecompanion').setup {
            adapters = {
                acp = {
                    claude_code = function()
                        return require('codecompanion.adapters').extend('claude_code', {
                            env = {
                                CLAUDE_CODE_OAUTH_TOKEN = vim.env.CLAUDE_CODE_OAUTH_TOKEN,
                            },
                        })
                    end,
                },
                http = {
                    copilot = function()
                        return require('codecompanion.adapters').extend('copilot', {
                            schema = {
                                model = {
                                    default = 'gpt-4.1',
                                },
                            },
                        })
                    end,
                    gemini = function()
                        return require('codecompanion.adapters').extend('gemini', {
                            env = {
                                api_key = vim.env.GEMINI_API_KEY,
                            },
                            schema = {
                                model = {
                                    default = 'gemini-3-flash-preview',
                                    choices = {
                                        ['gemini-3-flash-preview'] = { opts = { can_reason = true, has_vision = true } },
                                        ['gemini-3-pro-preview'] = { opts = { can_reason = true, has_vision = true } },
                                    },
                                },
                            },
                        })
                    end,
                },
            },
            interactions = {
                chat = {
                    adapter = 'claude_code',
                    opts = {
                        stream = true,
                        max_tokens = 4096,
                        temperature = 0.5,
                    },
                    roles = {
                        ---@param adapter CodeCompanion.Adapter
                        ---@return string
                        llm = function(adapter)
                            local model = adapter.model and adapter.model.name or nil
                            if model then return adapter.formatted_name .. ' (' .. model .. ')' end
                            return adapter.formatted_name
                        end,
                    },
                },
                agent = {
                    opts = {
                        max_tokens = 4096,
                    },
                },
                inline = {
                    adapter = 'claude_code',
                },
            },
            prompt_library = {
                ['Browse Chat History'] = {
                    strategy = 'chat',
                    description = 'Browse and restore saved chat history',
                    opts = {
                        index = 4,
                        is_default = false,
                        is_slash_cmd = false,
                        short_name = 'history',
                        modes = { 'n', 'v' },
                    },
                    prompts = {
                        n = function() vim.cmd 'CodeCompanionHistory' end,
                        v = function() vim.cmd 'CodeCompanionHistory' end,
                    },
                },
                ['Browse Summaries'] = {
                    strategy = 'chat',
                    description = 'Browse saved chat summaries',
                    opts = {
                        index = 5,
                        is_default = false,
                        is_slash_cmd = false,
                        short_name = 'summaries',
                        modes = { 'n', 'v' },
                    },
                    prompts = {
                        n = function() vim.cmd 'CodeCompanionSummaries' end,
                        v = function() vim.cmd 'CodeCompanionSummaries' end,
                    },
                },
                ['With CoT'] = {
                    strategy = 'chat',
                    description = 'Grounded Chain-of-Thought: Evaluation of logic and trade-offs before implementation',
                    opts = {
                        index = 6,
                        is_default = false,
                        is_slash_cmd = false,
                        short_name = 'think',
                        modes = { 'n', 'v' },
                        ignore_system_prompt = false,
                    },
                    prompts = {
                        {
                            role = 'system',
                            content = [[You are a Lead Systems Architect. You must validate logic and evaluate trade-offs before providing any technical solution.

OPERATIONAL CONSTRAINTS:
1. GROUNDING: Base all logic strictly on the provided context. Do not invent libraries or architectural states not present.
2. CIRCUIT BREAKER: Limit each PHASE to 10 bullet points or fewer. Signal "REASONING_LIMIT_REACHED" if more depth is required.
3. PRECISION: Cite file paths and line numbers during the EXPLORE and ANSWER phases.

ANALYSIS PROTOCOL:
- PHASE 1 (THINK): Restate core problem. Identify edge cases, assumptions, and missing context.
- PHASE 2 (EXPLORE): Evaluate ≥2 distinct approaches. Compare performance, security, and maintainability.
- PHASE 3 (DECIDE): Select the optimal path and justify.
- PHASE 4 (ANSWER): Deliver final implementation or refined technical advice.

STRICT RULE: Never skip to the answer. If ambiguous, stop at PHASE 1 and request clarification.]],
                        },
                        {
                            role = 'user',
                            content = '',
                        },
                    },
                },
                ['With Repomix'] = {
                    strategy = 'chat',
                    description = 'Audit Agent: ReAct pattern utilizing MCP tools for repository ingestion',
                    opts = {
                        index = 10,
                        is_default = false,
                        is_slash_cmd = false,
                        short_name = 'audit',
                        modes = { 'n' },
                    },
                    prompts = {
                        {
                            role = 'system',
                            content = [[You are a Senior Software Engineer. Your mission is to conduct a rigorous, evidence-based codebase analysis.

OPERATIONAL CONSTRAINTS:
1. GROUNDING: Base all claims strictly on provided code. Do not infer logic that is not present.
2. PRECISION: Every observation MUST cite the file path and specific line numbers.
3. CIRCUIT BREAKER: Limit each section to 10 items or fewer. Signal "CONTEXT_LIMIT_REACHED" if more context is needed.
4. TONE: Concise, technical, and objective. No conversational filler.]],
                        },
                        {
                            role = 'user',
                            content = '',
                        },
                    },
                },

                -- Security Review: OWASP-focused analysis of the current buffer or selection.
                ['Security Review'] = {
                    strategy = 'chat',
                    description = 'OWASP Top 10 security review of current file or selection',
                    opts = {
                        index = 11,
                        is_default = false,
                        is_slash_cmd = false,
                        short_name = 'sec',
                        modes = { 'n', 'v' },
                    },
                    prompts = {
                        {
                            role = 'system',
                            content = [[You are an application security engineer.
Check against: OWASP Top 10, injection (SQL/NoSQL/command/LDAP), broken auth/authz, IDOR, SSRF, XXE, insecure deserialization, sensitive data exposure, and security misconfiguration.
Distinguish confirmed vulnerabilities from potential risks. Cite file:line for every finding.]],
                        },
                        {
                            role = 'user',
                            content = '',
                        },
                    },
                },

                -- Refactor Plan: safe, incremental refactoring proposal with rollback steps.
                ['Refactor Plan'] = {
                    strategy = 'chat',
                    description = 'Incremental refactoring plan with rollback strategy',
                    opts = {
                        index = 12,
                        is_default = false,
                        is_slash_cmd = true,
                        short_name = 'refactor',
                        modes = { 'n', 'v' },
                    },
                    prompts = {
                        {
                            role = 'system',
                            content = [[You are a senior engineer creating a safe, incremental refactoring plan.
Constraints: keep each step independently deployable, preserve all existing tests, never break the public API unless explicitly asked.
Think in phases: understand → identify smells → propose steps → estimate risk.]],
                        },
                        {
                            role = 'user',
                            content = '',
                        },
                    },
                },
            },
            -- MCP (Model Context Protocol) Servers
            -- MCP lets LLMs call external tool servers via JSON-RPC over stdio.
            -- These add capabilities that built-in tools don't have.
            -- Use /mcp in a chat buffer to toggle servers on/off.
            mcp = {
                servers = {
                    -- Live, up-to-date documentation for libraries/frameworks.
                    -- Instead of relying on stale training data, the AI fetches
                    -- current docs from the source. No API key needed.
                    -- https://github.com/upstash/context7
                    ['context7'] = {
                        cmd = { 'npx', '-y', '@upstash/context7-mcp@latest' },
                    },
                    -- Structured step-by-step reasoning with revision and branching.
                    -- Forces the AI to break complex problems into explicit steps
                    -- instead of jumping to conclusions. No API key needed.
                    -- https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking
                    ['sequential-thinking'] = {
                        cmd = { 'npx', '-y', '@modelcontextprotocol/server-sequential-thinking' },
                    },
                    -- PDF reader — extracts text and metadata from PDF files.
                    -- Lets the AI read books, papers, and documents directly.
                    -- https://github.com/github/pdf-reader-mcp
                    ['pdf-reader'] = {
                        cmd = { 'uvx', 'pdf-reader-mcp' },
                    },
                    -- Git operations (status, diff, log, commit, branch, etc.) on local repos.
                    -- No GitHub/GitLab — pure Git. Pass the repo path as the first argument,
                    -- or omit it to default to the current working directory.
                    -- https://github.com/modelcontextprotocol/servers/tree/main/src/git
                    ['git'] = {
                        cmd = { 'uvx', 'mcp-server-git' },
                    },
                    -- Repomix — packs a repository (or subset of files) into a single
                    -- AI-friendly text file (XML/plain/markdown). Useful for giving the
                    -- AI full codebase context in one shot.
                    -- Run on-demand via `/mcp` in chat; no API key needed.
                    -- https://github.com/yamadashy/repomix
                    ['repomix'] = {
                        cmd = { 'npx', '-y', 'repomix', '--mcp' },
                    },
                    -- Persistent memory as a knowledge graph.
                    -- The AI can store entities, relations and observations
                    -- that survive across conversations. Data lives in a local JSON file.
                    -- Works with any adapter (Copilot, Gemini, etc.) — it's an external
                    -- MCP server, not the Anthropic-specific built-in memory tool.
                    -- https://github.com/modelcontextprotocol/servers/tree/main/src/memory
                    ['memory'] = {
                        cmd = { 'npx', '-y', '@modelcontextprotocol/server-memory' },
                        env = {
                            MEMORY_FILE_PATH = vim.fn.stdpath 'data' .. '/mcp-memory/memory.json',
                        },
                    },
                },
                opts = {
                    -- Servers listed here auto-start when CodeCompanion loads.
                    -- Remove a name to make it on-demand only (toggle with /mcp in chat).
                    default_servers = { 'context7', 'memory' },
                },
            },
            display = {
                chat = {
                    show_token_count = true,
                },
            },
            extensions = {
                history = {
                    enabled = true,
                    opts = {
                        -- Keymap to open history from chat buffer
                        keymap = 'gh',
                        -- Keymap to save the current chat manually
                        save_chat_keymap = 'gW',
                        -- Save directory
                        dir_to_save = vim.fn.stdpath 'data' .. '/codecompanion-history',
                        -- Picker: 'telescope' | 'snacks' | 'fzf_lua' | 'mini_pick' | 'default'
                        picker = 'default',
                        summary = {
                            -- NOTE: avoid 'gcs'/'gbs' — 'gc' and 'gb' are prefixes of existing keymaps
                            -- ('gc' = codeblock, 'gba'/'gbd' = buffer sync), causing input delay.
                            -- 'gz' is unused by codecompanion, making it a safe prefix.
                            create_summary_keymap = 'gzs',
                            browse_summaries_keymap = 'gzb',
                        },
                    },
                },
            },
        }
    end,
    keys = {
        { '<leader>ac', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = '[A]I [C]hat' },
        { '<leader>ai', '<cmd>CodeCompanion<cr>',            mode = 'v',          desc = '[A]I [I]nline Edit' },
        { '<leader>aa', '<cmd>CodeCompanionActions<cr>',     mode = { 'n', 'v' }, desc = '[A]I [A]ctions' },
        {
            '<leader>aR',
            function() require('custom.cc_budget').reset() end,
            mode = 'n',
            desc = '[A]I [R]eset turn counter',
        },
    },
}
