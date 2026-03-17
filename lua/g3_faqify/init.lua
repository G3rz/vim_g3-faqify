local M = {}

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parse_qa(text)
  local lines = vim.split(text, "\n", { plain = true })
  local cleaned = {}

  for _, line in ipairs(lines) do
    local trimmed = trim(line)
    if trimmed ~= "" then
      table.insert(cleaned, trimmed)
    end
  end

  local pairs = {}
  for i = 1, #cleaned, 2 do
    table.insert(pairs, {
      q = cleaned[i] or "",
      a = cleaned[i + 1] or "",
    })
  end

  return pairs
end

local function html_escape_attr(text)
  return (text or "")
    :gsub("&", "&amp;")
    :gsub('"', "&quot;")
    :gsub("<", "&lt;")
    :gsub(">", "&gt;")
end

local function encode_json(value)
  local ok, encoded = pcall(vim.json.encode, value)
  if ok then
    return encoded
  end
  return "{}"
end

local function build_json_ld(pairs)
  local main_entity = {}

  for _, pair in ipairs(pairs) do
    table.insert(main_entity, {
      ["@type"] = "Question",
      name = pair.q,
      acceptedAnswer = {
        ["@type"] = "Answer",
        text = pair.a,
      },
    })
  end

  return {
    ["@context"] = "https://schema.org",
    ["@type"] = "FAQPage",
    mainEntity = main_entity,
  }
end

local function build_pov_output(pairs)
  local items = {}

  for _, pair in ipairs(pairs) do
    local title = html_escape_attr(pair.q)
    table.insert(items, string.format('\t\t[item nadpis="%s"]\n\t\t\t%s\n\t\t[/item]', title, pair.a))
  end

  local accordion = "[accordion]\n" .. table.concat(items, "\n") .. "\n[/accordion]"
  local json_block = "<script type=\"application/ld+json\">\n" .. encode_json(build_json_ld(pairs)) .. "\n</script>"

  return table.concat({
    "<!-- FAQ -->\n<h2>Nejčastěji kladené otázky - FAQ</h2>",
    accordion,
    "<!-- /FAQ -->\n" .. json_block,
  }, "\n")
end

local function build_suri_output(pairs)
  local faqs = {}

  for _, pair in ipairs(pairs) do
    local title = html_escape_attr(pair.q)
    table.insert(faqs, string.format('\t[faq otazka="%s"]\n\t\t<p>%s</p>\n\t[/faq]', title, pair.a))
  end

  local shortcode_block = table.concat({
    "[cta-mini]",
    "",
    "<!-- FAQ -->",
    "[faqs]",
    table.concat(faqs, "\n"),
    "[/faqs]",
    "<!-- /FAQ -->",
  }, "\n")

  local json_block = "<script type=\"application/ld+json\">\n" .. encode_json(build_json_ld(pairs)) .. "\n</script>"
  return shortcode_block .. "\n\n" .. json_block
end

local function split_lines(text)
  return vim.split(text, "\n", { plain = true })
end

local function apply_builder(builder, opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local start_idx = 0
  local end_idx = line_count

  if opts.range and opts.range > 0 then
    start_idx = opts.line1 - 1
    end_idx = opts.line2
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_idx, end_idx, false)
  local text = table.concat(lines, "\n")
  local pairs = parse_qa(text)
  local output = builder(pairs)

  vim.api.nvim_buf_set_lines(bufnr, start_idx, end_idx, false, split_lines(output))
end

function M.faqify_suri(opts)
  apply_builder(build_suri_output, opts or {})
end

function M.faqify_pov(opts)
  apply_builder(build_pov_output, opts or {})
end

function M.setup(opts)
  opts = opts or {}
  local keymaps = opts.keymaps
  local command_prefix = opts.command_prefix or "G3"

  vim.api.nvim_create_user_command(command_prefix .. "FaqifySuri", function(cmd_opts)
    M.faqify_suri(cmd_opts)
  end, {
    desc = "FAQify: Suri",
    range = true,
  })

  vim.api.nvim_create_user_command(command_prefix .. "FaqifyPov", function(cmd_opts)
    M.faqify_pov(cmd_opts)
  end, {
    desc = "FAQify: POV",
    range = true,
  })

  if keymaps ~= false then
    local suri_key = type(keymaps) == "table" and keymaps.suri or "<leader>fqs"
    local pov_key = type(keymaps) == "table" and keymaps.pov or "<leader>fqp"

    vim.keymap.set("n", suri_key, "<cmd>%" .. command_prefix .. "FaqifySuri<cr>", { desc = "FAQify Suri (buffer)" })
    vim.keymap.set("n", pov_key, "<cmd>%" .. command_prefix .. "FaqifyPov<cr>", { desc = "FAQify POV (buffer)" })
    vim.keymap.set("x", suri_key, ":<C-U>'<,'>" .. command_prefix .. "FaqifySuri<cr>", { desc = "FAQify Suri (selection)" })
    vim.keymap.set("x", pov_key, ":<C-U>'<,'>" .. command_prefix .. "FaqifyPov<cr>", { desc = "FAQify POV (selection)" })
  end
end

return M
