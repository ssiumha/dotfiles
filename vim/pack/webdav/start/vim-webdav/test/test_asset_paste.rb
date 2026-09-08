#!/usr/bin/env ruby
# WebDAVPasteImage and asset:// reference tests

require_relative 'test_base'

class TestAssetPaste < TestWebDAVBase
  # 1x1 PNG. Fixed bytes, so a paste always resolves to the same path and the
  # dedup test can compare two runs.
  FIXTURE_B64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

  # /vault/notes/daily/2024-01-01.md comes from init-webdav.sh. Its parent
  # folder and basename decide the slug, so the expected name is fixed.
  NOTE = '/vault/notes/daily/2024-01-01.md'
  SLUG = 'daily-2024-01-01'

  def setup
    super
    docker_exec("printf %s #{FIXTURE_B64} | base64 -d > /root/fixture.png")
  end

  def configure_pattern
    vim_cmd("let g:webdav_asset_clipboard_cmd = \\\"cp /root/fixture.png %s\\\"")
    vim_cmd("let g:webdav_asset_patterns = {}")
    vim_cmd("let g:webdav_asset_patterns.default = {}")
    vim_cmd("let g:webdav_asset_patterns.default.server = \\\"\\\"")
    vim_cmd("let g:webdav_asset_patterns.default.prefix = \\\"vim/assets/%Y/%m\\\"")
  end

  def paste_into_note
    vim_cmd("WebDAVGet #{NOTE}")
    wait_for_text("Daily", 2)
    vim_cmd("normal! G$")
    vim_cmd("WebDAVPasteImage")
    wait_for_text("Asset:", 5)

    vim_cmd("let g:t_ref = matchstr(join(getline(1, \\\"$\\\"), \\\"\\\"), \\\"asset://[^)]*\\\")")
    vim_cmd("echo g:t_ref")
    capture
  end

  def test_slugify_matches_asset_manager
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    vim_cmd("echo webdav#asset#slugify(\\\"  Daily/2026 06 15  \\\")")
    assert_includes capture, "Daily-2026-06-15"

    # Path-hostile characters collapse to a single dash, edges are trimmed
    vim_cmd("echo webdav#asset#slugify(\\\"-a?*b-\\\")")
    assert_includes capture, "a-b"
  end

  def test_note_slug_uses_parent_folder
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    vim_cmd("echo webdav#asset#note_slug({\\\"dir\\\": \\\"/vault/notes/daily/\\\", \\\"name\\\": \\\"2024-01-01.md\\\"})")
    assert_includes capture, "daily 2024-01-01"

    # At the root there is no parent folder, so the basename stands alone
    vim_cmd("echo webdav#asset#note_slug({\\\"dir\\\": \\\"/\\\", \\\"name\\\": \\\"index.md\\\"})")
    output = capture
    assert_includes output, "index"
    refute_includes output, "index index"
  end

  def test_ref_and_parse_ref_round_trip
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    vim_cmd("echo webdav#asset#ref(\\\"vim/a/b.webp\\\", \\\"\\\")")
    assert_includes capture, "asset://vim/a/b.webp"

    vim_cmd("echo webdav#asset#ref(\\\"/vim/a/b.webp\\\", \\\"photos\\\")")
    assert_includes capture, "asset://photos@vim/a/b.webp"

    vim_cmd("echo webdav#asset#parse_ref(\\\"asset://photos@vim/a/b.webp\\\").store")
    assert_includes capture, "photos"

    vim_cmd("echo webdav#asset#parse_ref(\\\"asset://vim/a/b.webp\\\").path")
    assert_includes capture, "vim/a/b.webp"
  end

  def test_mkcol_p_creates_every_ancestor
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    vim_cmd("echo webdav#asset#mkcol_p(\\\"vimtest/deep/nest\\\", webdav#server#get_info(\\\"\\\"))")
    assert_includes capture, "1"

    ["vimtest", "vimtest/deep", "vimtest/deep/nest"].each do |dir|
      result = docker_exec("curl -s -X PROPFIND -H Depth:0 http://localhost:9999/#{dir}/ 2>&1")
      refute_includes result, "404", "#{dir} should exist"
    end
  end

  def test_mkcol_p_is_idempotent
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    vim_cmd("echo webdav#asset#mkcol_p(\\\"vimtest/twice\\\", webdav#server#get_info(\\\"\\\"))")
    assert_includes capture, "1"

    # A second run hits 405 on both levels, which counts as success
    vim_cmd("echo webdav#asset#mkcol_p(\\\"vimtest/twice\\\", webdav#server#get_info(\\\"\\\"))")
    assert_includes capture, "1"
  end

  def test_paste_uploads_and_inserts_ref
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    output = paste_into_note
    ym = Time.now.strftime('%Y/%m')

    assert_match %r{asset://vim/assets/#{ym}/#{SLUG}-[0-9a-f]{8}\.webp}, output

    path = output[%r{asset://(\S+\.webp)}, 1]
    size = docker_exec("curl -s -o /tmp/a.webp -w '%{size_download}' http://localhost:9999/#{path}").strip
    assert size.to_i > 0, "Uploaded asset should have bytes on the server"

    kind = docker_exec("head -c 4 /tmp/a.webp").strip
    assert_equal "RIFF", kind, "Uploaded asset should be a webp container"
  end

  def test_paste_inserts_the_embed_form
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    paste_into_note
    vim_cmd("echo matchstr(join(getline(1, \\\"$\\\"), \\\"\\\"), \\\"!\\\\[\\\\](asset://\\\")")
    assert_includes capture, "![](asset://"
  end

  def test_paste_dedups_identical_bytes
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    first = paste_into_note[%r{asset://\S+\.webp}]
    refute_nil first, "First paste should insert a reference"
    second = paste_into_note[%r{asset://\S+\.webp}]
    assert_equal first, second, "Same bytes should resolve to the same path"

    ym = Time.now.strftime('%Y/%m')
    # A PROPFIND entry names its file in both href and displayname, so count
    # distinct names rather than occurrences.
    listing = docker_exec("curl -s -X PROPFIND -H Depth:1 http://localhost:9999/vim/assets/#{ym}/ 2>&1")
    names = listing.scan(%r{[^/<>"]+\.webp}).uniq
    assert_equal 1, names.size, "Only one asset should exist, got #{names.inspect}"
  end

  def test_url_resolves_a_ref_to_the_server
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    vim_cmd("echo webdav#asset#url(\\\"asset://vim/a/b.webp\\\")")
    assert_includes capture, "http://localhost:9999/vim/a/b.webp"
  end

  def test_ref_at_cursor_reads_the_embed_under_the_cursor
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    vim_cmd("call setline(1, \\\"text ![](asset://vim/a/b.webp) tail\\\")")
    vim_cmd("normal! 1G15|")
    vim_cmd("echo webdav#asset#ref_at_cursor()")
    assert_includes capture, "asset://vim/a/b.webp"

    # Outside the reference there is nothing to open
    vim_cmd("normal! 1G$")
    vim_cmd("echo empty(webdav#asset#ref_at_cursor())")
    assert_includes capture, "1"
  end

  # nr2char(34) is '"', the unnamed register, spelled this way so the quote
  # survives the trip through sh and tmux.
  def test_p_pastes_normally_when_the_register_holds_text
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    vim_cmd("WebDAVGet #{NOTE}")
    wait_for_text("Daily", 2)
    vim_cmd("call setreg(nr2char(34), \\\"PASTEDTEXT\\\")")
    vim_cmd("normal! G$")
    send_keys("p")

    wait_for_text("PASTEDTEXT", 2)
    vim_cmd("echo matchstr(join(getline(1, \\\"$\\\"), \\\"\\\"), \\\"asset://\\\")")
    output = capture
    refute_includes output, "asset://", "A text paste must not upload"
  end

  def test_p_uploads_when_the_register_is_empty
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    vim_cmd("WebDAVGet #{NOTE}")
    wait_for_text("Daily", 2)
    vim_cmd("call setreg(nr2char(34), \\\"\\\")")
    vim_cmd("normal! G$")
    send_keys("p")

    wait_for_text("Asset:", 5)
    vim_cmd("echo matchstr(join(getline(1, \\\"$\\\"), \\\"\\\"), \\\"asset://[^)]*\\\")")
    assert_match %r{asset://vim/assets/}, capture
  end

  # A stale session is what the reader actually hits: vim sources an autoload
  # script once, so p must still paste when the asset module is not there.
  def test_p_falls_back_when_the_asset_module_is_missing
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    vim_cmd("WebDAVGet #{NOTE}")
    wait_for_text("Daily", 2)
    vim_cmd("call setreg(nr2char(34), \\\"FALLBACKTEXT\\\")")
    vim_cmd("silent! call webdav#asset#put(nr2char(112))")
    vim_cmd("delfunction webdav#asset#put")
    vim_cmd("normal! G$")
    send_keys("p")

    wait_for_text("FALLBACKTEXT", 2)
  end

  def test_p_keeps_the_count_and_the_named_register
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    vim_cmd("WebDAVGet #{NOTE}")
    wait_for_text("Daily", 2)
    vim_cmd("call setreg(\\\"a\\\", \\\"XY\\\")")
    vim_cmd("normal! G$")
    send_keys("\\\"a2p")

    wait_for_text("XYXY", 2)
  end

  def open_note_with_ref(ref)
    vim_cmd("WebDAVGet #{NOTE}")
    wait_for_text("Daily", 2)
    vim_cmd("call setline(1, \\\"![](#{ref})\\\")")
    vim_cmd("normal! 1G10|")
  end

  def put_checkerboard
    docker_exec("magick -size 16x16 pattern:checkerboard /root/checker.png")
    docker_exec("curl -s -X PUT --data-binary @/root/checker.png http://localhost:9999/vim/assets/checker.png")
  end

  def preview_with(style = nil)
    put_checkerboard
    vim_cmd("let g:webdav_asset_preview_style = \\\"#{style}\\\"") if style
    open_note_with_ref("asset://vim/assets/checker.png")
    vim_cmd("call webdav#asset#preview()")
    wait_for_text("checker.png", 5)
    capture
  end

  # The default style paints each cell with a text property, so a failure to
  # build those shows up as a missing half block rather than a wrong colour.
  def test_preview_draws_half_blocks_by_default
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    assert_includes preview_with, "▀", "Popup should hold upper half blocks"
  end

  def test_preview_colours_every_cell
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern
    preview_with

    # The popup swallows the next key, so dismiss it before typing a command
    # The border, not the title: the note itself names the file on line 1
    docker_exec("tmux send-keys -t test Escape")
    wait_until_gone("═", 2)

    # Nothing else in this vim adds prop types, so a non-zero count is the
    # colour pairs. Nested quotes do not survive sh and tmux, hence no filter.
    vim_cmd("echo \\\"PROPS=\\\" . len(prop_type_list())")
    assert_match(/PROPS=[1-9]/, capture, "Colour pairs should become prop types")
  end

  def test_preview_braille_style_uses_braille
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    assert_match(/[⠀-⣿]/, preview_with("braille"), "Popup should hold braille")
  end

  def test_preview_blocks_style_uses_block_shades
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    output = preview_with("blocks")
    assert_match(/[░▒▓█]/, output, "Popup should hold block shades")
    refute_match(/[⠀-⣿]/, output, "blocks style must not use braille")
  end

  def test_preview_refuses_a_non_image
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    open_note_with_ref("asset://vim/assets/report.pdf")
    vim_cmd("call webdav#asset#preview()")

    wait_for_text("Not an image", 2)
  end

  def test_preview_without_a_reference_says_so
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    vim_cmd("WebDAVGet #{NOTE}")
    wait_for_text("Daily", 2)
    vim_cmd("normal! 1G1|")
    vim_cmd("call webdav#asset#preview()")

    wait_for_text("No asset:// reference under cursor", 2)
  end

  def test_paste_outside_a_document_buffer_is_refused
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    vim_cmd("WebDAVPasteImage")
    wait_for_text("Not a WebDAV document buffer", 2)
  end

  def test_unknown_pattern_is_reported
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    configure_pattern

    vim_cmd("WebDAVPasteImage nosuch")
    wait_for_text("not found", 2)
  end
end
