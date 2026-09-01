#!/usr/bin/env ruby
# WebDAV <space><space> command palette tests

require_relative 'test_base'

class TestWebDAVPalette < TestWebDAVBase
  # tmux swallows a literal double space, so name the key explicitly
  def send_palette_key
    docker_exec("tmux send-keys -t test Space Space")
  end

  # Wait until the resource shows up at its new path, then let vim settle. MOVE
  # and the buffer reopen that follows are two round trips, and typing into vim
  # between them lands in the wrong buffer.
  def wait_for_move(relative_path, timeout = 10)
    wait_for(timeout) do
      docker_exec("curl -s -o /dev/null -w '%{http_code}' http://localhost:9999/test/#{relative_path}").strip == "200"
    end
    sleep 0.5
  end

  # Filter the palette down to one entry. The window only shows a handful of
  # rows, so asserting on the whole screen would miss anything scrolled off.
  def palette_query(text)
    docker_exec("tmux send-keys -t test C-u")
    send_keys(text)
    sleep 0.3
  end

  # Test palette lists the listing actions and names its target
  def test_palette_opens_in_listing
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("file1.txt")

    send_keys("/file1.txt")
    send_enter
    wait_for_text("file1.txt", 1)

    send_palette_key
    wait_for_text("WebDAV>", 3)
    assert_includes capture, "target: /test/file1.txt", "Header should name the target"

    palette_query("Rename")
    wait_for_text("change name or path", 2)

    palette_query("New folder")
    wait_for_text("create folder here", 2)

    palette_query("Find file")
    wait_for_text("recursive fzf from here", 2)
  end

  # Test target-only actions disappear when the cursor is not on a resource
  def test_palette_hides_target_actions_without_target
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("file1.txt")

    send_keys("3G")  # line 3 = ../
    send_palette_key
    wait_for_text("WebDAV>", 3)
    assert_includes capture, "target: /test/", "Header should fall back to the directory"

    palette_query("Rename")
    refute_includes capture, "change name or path", "Rename needs a target"

    palette_query("Delete")
    refute_includes capture, "remove (DELETE)", "Delete needs a target"

    palette_query("New file")
    wait_for_text("create .md here", 2)
  end

  # Test the document buffer gets the file-only actions
  def test_palette_in_document_buffer
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content")

    send_palette_key
    wait_for_text("WebDAV>", 3)
    assert_includes capture, "target: /test/file1.txt", "Header should name the open file"

    palette_query("Diff")
    wait_for_text("compare against remote", 2)

    palette_query("Backlinks")
    wait_for_text("notes linking here", 2)

    palette_query("Save")
    wait_for_text("upload buffer (PUT)", 2)
  end

  # Test Rename from a document buffer moves the file and follows it
  def test_palette_rename_from_document
    random_key = rand(100000..999999)
    src = "palette_rename_#{random_key}.txt"
    dst = "palette_renamed_#{random_key}.txt"
    docker_exec("curl -s -X PUT http://localhost:9999/test/#{src} -d PaletteRenameContent > /dev/null")

    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVGet /test/#{src}")
    wait_for_text("PaletteRenameContent", 2)

    send_palette_key
    wait_for_text("WebDAV>", 3)
    send_keys("Rename")
    sleep 0.3
    send_enter
    wait_for_text("Rename file to", 2)

    send_keys("\u0015")  # Ctrl-U clears the prefilled current name
    send_keys(dst)
    send_enter

    # The server is the authoritative signal that MOVE finished; probing the
    # buffer first races with the reopen that follows it
    wait_for_move(dst)
    vim_cmd("echo b:webdav_original_path")
    wait_for_text("/test/#{dst}", 3)

    output = capture
    assert_includes output, "/test/#{dst}", "Buffer should follow the renamed file"

    result = docker_exec("curl -s -o /dev/null -w '%{http_code}' http://localhost:9999/test/#{src}")
    assert_equal "404", result.strip, "Old path should be gone on the server"

    result = docker_exec("curl -s http://localhost:9999/test/#{dst}")
    assert_includes result, "PaletteRenameContent", "New path should hold the content"
  end

  # Test Move picks a folder from the recursive scan and MOVEs into it
  def test_palette_move_picks_folder
    random_key = rand(100000..999999)
    name = "palette_move_#{random_key}.txt"
    docker_exec("curl -s -X PUT http://localhost:9999/test/#{name} -d PaletteMoveContent > /dev/null")

    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVGet /test/#{name}")
    wait_for_text("PaletteMoveContent", 2)

    send_palette_key
    wait_for_text("WebDAV>", 3)
    send_keys("Move to")
    sleep 0.3
    send_enter
    wait_for_text("Move to>", 3)

    # test/deep/subfolder/ is three levels down, so it only shows up if the
    # scanner emits directories the same way it emits files
    send_keys("deep/subfolder")
    wait_for_text("test/deep/subfolder/", 5)
    send_enter

    wait_for_move("deep/subfolder/#{name}")
    vim_cmd("echo b:webdav_original_path")
    wait_for_text("/test/deep/subfolder/#{name}", 3)

    output = capture
    assert_includes output, "/test/deep/subfolder/#{name}", "Buffer should follow the moved file"

    result = docker_exec("curl -s http://localhost:9999/test/deep/subfolder/#{name}")
    assert_includes result, "PaletteMoveContent", "File should be at the new path"

    result = docker_exec("curl -s -o /dev/null -w '%{http_code}' http://localhost:9999/test/#{name}")
    assert_equal "404", result.strip, "Old path should be gone on the server"
  end

  # Test the palette refuses buffers that share the filetype but carry no path
  def test_palette_declines_recent_buffer
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVGet /test/file1.txt")
    wait_for_text("This is test file content")

    vim_cmd("WebDAVRecent")
    wait_for_text("Recent WebDAV Files", 2)

    send_palette_key
    wait_for_text("Not a WebDAV buffer", 2)

    output = capture
    assert_includes output, "Not a WebDAV buffer",
                    "Recent buffer uses filetype=webdavlist but keeps no path"
  end
end
