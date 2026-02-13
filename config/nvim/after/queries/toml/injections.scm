; extends

; mise.toml run = """...""" → bash
(pair
  (bare_key) @key (#eq? @key "run")
  (string) @injection.content

  (#is-mise?)
  (#lua-match? @injection.content "^\"\"\"")
  (#offset! @injection.content 0 3 0 -3)
  (#set! injection.language "bash")
)

; mise.toml run = "..." → bash
(pair
  (bare_key) @key (#eq? @key "run")
  (string) @injection.content

  (#is-mise?)
  (#not-lua-match? @injection.content "^\"\"\"")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "bash")
)
