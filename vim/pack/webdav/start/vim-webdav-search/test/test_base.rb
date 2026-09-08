#!/usr/bin/env ruby
# Base test class. Mounts both packages into one container: this plugin opens
# results through vim-webdav, so the pair has to be present together.
# Reuses vim-webdav's image and tmux/screen helpers rather than copying them.

require 'minitest/autorun'
require 'securerandom'
require 'json'

PACK_DIR = File.expand_path('../..', __dir__)
WEBDAV_TEST_DIR = File.join(PACK_DIR, 'vim-webdav', 'test')

require File.join(WEBDAV_TEST_DIR, 'tmux_helper')
require File.join(WEBDAV_TEST_DIR, 'screen_helper')

class TestWebDAVSearchBase < Minitest::Test
  include TmuxHelper
  include ScreenHelper

  MOCK_PORT = 9998

  def setup
    @container = "vim-webdav-search-test-#{SecureRandom.hex(4)}"

    system(
      "docker run --rm -d --name #{@container}" \
      " -v #{PACK_DIR}/vim-webdav:/root/.vim/pack/webdav/start/vim-webdav" \
      " -v #{PACK_DIR}/vim-webdav-search:/root/.vim/pack/webdav/start/vim-webdav-search" \
      " vim-webdav-test",
      out: '/dev/null'
    )
    wait_for_container
    wait_for_server
    start_mock_api
    docker_exec("tmux new-session -d -s test")
  end

  def teardown
    system("docker rm -f #{@container}", out: '/dev/null')
  end

  # start_vim's env, with both backends pointed at the container
  def search_env(extra = {})
    webdav_env.merge("WEBDAV_SEARCH_URL" => "http://localhost:#{MOCK_PORT}").merge(extra)
  end

  # WebDAV alone: the search plugin stays silent without WEBDAV_SEARCH_URL.
  # WEBDAV_UI_HOME names the server results open on; WEBDAV_DEFAULT_URL lets a
  # bare :WebDAVGet resolve too.
  def webdav_env(extra = {})
    {
      "WEBDAV_UI_HOME" => "http://localhost:9999",
      "WEBDAV_DEFAULT_URL" => "http://localhost:9999",
      # A server rooted below the vault, to check scope survives the difference
      "WEBDAV_UI_DEEP" => "http://localhost:9999/test/deep"
    }.merge(extra)
  end

  def start_mock_api
    # -d so the server outlives the exec that launched it
    system(
      "docker exec -d #{@container} ruby" \
      " /root/.vim/pack/webdav/start/vim-webdav-search/test/mock-api.rb",
      out: '/dev/null'
    )
    wait_for_mock_api
  end

  def wait_for_container(timeout = 5)
    start = Time.now
    while Time.now - start < timeout
      return if docker_exec("printf ready").strip == "ready"

      sleep 0.05
    end
    raise "Container not ready"
  end

  def wait_for_server(timeout = 5)
    start = Time.now
    while Time.now - start < timeout
      return if docker_exec("curl -s -o /dev/null -w '%{http_code}' http://localhost:9999 || printf 000").strip != "000"

      sleep 0.05
    end
    raise "Mock WebDAV server not ready"
  end

  def wait_for_mock_api(timeout = 10)
    start = Time.now
    probe = "curl -s -o /dev/null -w '%{http_code}' 'http://localhost:#{MOCK_PORT}/api/vault/tags' || printf 000"
    while Time.now - start < timeout
      return if docker_exec(probe).strip == "200"

      sleep 0.1
    end
    raise "Mock search index not ready: #{docker_exec('cat /tmp/mock.log 2>/dev/null')}"
  end

  # Read the API directly, to separate a client bug from a fixture one
  def api(path)
    JSON.parse(docker_exec("curl -s 'http://localhost:#{MOCK_PORT}#{path}'"))
  end
end
