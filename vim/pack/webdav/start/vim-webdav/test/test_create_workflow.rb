#!/usr/bin/env ruby
# WebDAV file and folder creation workflow tests

require_relative 'test_base'

class TestWebDAVCreateWorkflow < TestWebDAVBase
  # Test creating a new file from List with +New
  def test_create_new_file_from_list
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+New")

    # Select +New item (line 4)
    send_keys("4G")
    send_enter
    wait_for_text("New file name", 2)

    # Enter filename (without extension)
    send_keys("newfile")
    send_enter
    wait_for_text("newfile", 2)

    # Verify file opened in editor
    vim_cmd("echo expand('%')")
    output = capture
    assert_includes output, "newfile.md", "New file should be opened in editor"

    # Verify initial content
    vim_cmd("echo getline(1)")
    output = capture
    assert_includes output, "# newfile", "Should have title as first line"

    # Verify file created on server
    result = docker_exec("curl -s http://localhost:9999/test/newfile.md")
    assert_includes result, "# newfile", "File should exist on server with correct content"
  end

  # Test creating a new folder from List with +Folder
  def test_create_new_folder_from_list
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+Folder")

    # Select +Folder item (line 5)
    send_keys("5G")
    send_enter
    wait_for_text("New folder name", 2)

    # Enter folder name
    send_keys("newfolder")
    send_enter
    wait_for_text("newfolder/", 2)

    # Verify list refreshed and folder appears
    vim_cmd("echo getline(1, '$')")
    output = capture
    assert_includes output, "newfolder/", "New folder should appear in list"

    # Verify folder created on server (PROPFIND should succeed)
    result = docker_exec("curl -s -X PROPFIND http://localhost:9999/test/newfolder/ 2>&1")
    refute_includes result, "404", "Folder should exist on server"
  end

  # Test creating file with Korean name
  def test_create_file_with_korean_name
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+New")

    # Select +New item
    send_keys("4G")
    send_enter
    wait_for_text("New file name", 2)

    # Enter Korean filename
    send_keys("새파일")
    send_enter
    wait_for_text("새파일", 2)

    # Verify file opened
    vim_cmd("echo expand('%')")
    output = capture
    assert_includes output, "새파일.md", "Korean filename should work"

    # Verify initial content
    vim_cmd("echo getline(1)")
    output = capture
    assert_includes output, "# 새파일", "Should have Korean title"

    # Verify file created on server
    result = docker_exec("curl -s http://localhost:9999/test/새파일.md")
    assert_includes result, "# 새파일", "Korean filename should work on server"
  end

  # Test creating folder with Korean name
  def test_create_folder_with_korean_name
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+Folder")

    # Select +Folder item
    send_keys("5G")
    send_enter
    wait_for_text("New folder name", 2)

    # Enter Korean folder name
    send_keys("새폴더")
    send_enter
    wait_for_text("새폴더/", 2)

    # Verify folder appears in list
    vim_cmd("echo getline(1, '$')")
    output = capture
    assert_includes output, "새폴더/", "Korean folder name should work"

    # Verify folder created on server
    result = docker_exec("curl -s -X PROPFIND http://localhost:9999/test/새폴더/ 2>&1")
    refute_includes result, "404", "Korean folder should exist on server"
  end

  # Test creating file in nested directory
  def test_create_file_in_nested_directory
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")

    # Open nested directory directly (folder is pre-created in init-webdav.sh)
    vim_cmd("WebDAVList /test/nested/")
    wait_for_text("+New")

    # Verify we're in nested folder
    output = capture
    assert_includes output, "+New", "Should show +New in nested directory listing"

    # Create file in nested folder - search for +New
    send_keys("/+New")
    send_enter  # Execute search
    send_enter  # Activate +New
    wait_for_text("New file name", 2)

    # Enter filename
    send_keys("nestedfile")
    send_enter
    wait_for_text("nestedfile", 2)

    # Verify file opened
    vim_cmd("echo expand('%')")
    output = capture
    assert_includes output, "nestedfile.md", "Should create file in nested directory"

    # Verify file created on server (file is auto-created with initial content)
    result = docker_exec("curl -s http://localhost:9999/test/nested/nestedfile.md")
    assert_includes result, "# nestedfile", "File should exist in nested directory on server"
  end

  # Test editing and saving newly created file
  def test_edit_and_save_new_file
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+New")

    # Create new file
    send_keys("4G")
    send_enter
    wait_for_text("New file name", 2)
    send_keys("editable")
    send_enter
    wait_for_text("editable", 2)

    # Edit the file
    send_keys("G")  # Last line
    send_keys("o")  # New line
    send_keys("Additional content")
    send_keys("\e")  # Exit insert mode

    # Save
    vim_cmd("write")

    # Verify saved on server
    result = docker_exec("curl -s http://localhost:9999/test/editable.md")
    assert_includes result, "# editable", "Should have title"
    assert_includes result, "Additional content", "Should have edited content"
  end

  # Test cancelling file creation
  def test_cancel_file_creation
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+New")

    # Count files before
    vim_cmd("let before = line('$')")

    # Try to create file but cancel
    send_keys("4G")
    send_enter
    wait_for_text("New file name", 2)
    # Send empty name (cancel)
    send_enter
    wait_for_text("+New", 2)

    # Verify still in list
    vim_cmd("echo &filetype")
    output = capture
    assert_includes output, "webdavlist", "Should still be in list after cancel"

    # Verify no file created
    vim_cmd("let after = line('$')")
    vim_cmd("echo before == after")
    output = capture
    assert_includes output, "1", "Line count should not change after cancel"
  end

  # Test cancelling folder creation
  def test_cancel_folder_creation
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+Folder")

    # Count items before
    vim_cmd("let before = line('$')")

    # Try to create folder but cancel
    send_keys("5G")
    send_enter
    wait_for_text("New folder name", 2)
    # Send empty name (cancel)
    send_enter
    wait_for_text("+Folder", 2)

    # Verify still in list
    vim_cmd("echo &filetype")
    output = capture
    assert_includes output, "webdavlist", "Should still be in list after cancel"

    # Verify line count unchanged (list refreshes but no new folder)
    vim_cmd("let after = line('$')")
    vim_cmd("echo before == after")
    output = capture
    assert_includes output, "1", "Line count should not change after cancel"
  end

  # Test automatic .md extension
  def test_automatic_md_extension
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+New")

    # Create file with name that already has .md
    send_keys("4G")
    send_enter
    wait_for_text("New file name", 2)
    send_keys("test.md")
    send_enter
    wait_for_text("test.md", 2)

    # Verify double extension added
    vim_cmd("echo expand('%')")
    output = capture
    assert_includes output, "test.md.md", "Should add .md even if name has extension"
  end

  # Test folder trailing slash
  def test_folder_trailing_slash_added
    start_vim("WEBDAV_DEFAULT_URL" => "http://localhost:9999")
    vim_cmd("WebDAVList /test/")
    wait_for_text("+Folder")

    # Create folder without trailing slash
    send_keys("5G")
    send_enter
    wait_for_text("New folder name", 2)
    send_keys("noslash")
    send_enter
    wait_for_text("noslash/", 2)

    # Verify folder appears with trailing slash
    vim_cmd("echo getline(1, '$')")
    output = capture
    assert_includes output, "noslash/", "Should add trailing slash to folder"

    # Verify folder created on server
    result = docker_exec("curl -s -X PROPFIND http://localhost:9999/test/noslash/ 2>&1")
    refute_includes result, "404", "Folder should exist on server"
  end
end
