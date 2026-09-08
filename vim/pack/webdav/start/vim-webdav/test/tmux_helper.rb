# Helper methods for tmux + Docker testing
module TmuxHelper
  # The command is wrapped in single quotes here, so a ' inside it ends the
  # quoting and its contents reach the shell unquoted. Write vim strings with
  # \\\" rather than ' — see test_wikilink.rb for the shape.
  def docker_exec(cmd)
    `docker exec #{@container} sh -c '#{cmd}'`
  end

  def send_keys(keys)
    docker_exec("tmux send-keys -t test \"#{keys}\"")
  end

  def send_enter
    docker_exec("tmux send-keys -t test C-m")
  end

  def vim_cmd(cmd)
    send_keys(":")
    send_keys(cmd)
    send_enter
  end

  def clear_screen
    docker_exec("tmux send-keys -t test C-l")  # Ctrl+L to clear
    sleep 0.1
  end

  def capture
    docker_exec("tmux capture-pane -t test -p").strip
  end

  def start_vim(env = {})
    env_str = env.map { |k, v| "#{k}=#{v}" }.join(" ")
    send_keys("#{env_str} vim")
    send_enter
    wait_for { capture.include?("VIM") || capture.include?("~") }
  end

  def wait_for(timeout = 1)
    start = Time.now
    while Time.now - start < timeout
      return if yield
      sleep 0.02
    end
    screen = capture
    raise "Timeout waiting for condition\n\nCurrent screen:\n#{screen}"
  end

  # Wait for specific text to appear on screen
  def wait_for_text(text, timeout = 2)
    wait_for(timeout) { capture.include?(text) }
  end

  # Wait for specific text to disappear from screen
  def wait_until_gone(text, timeout = 2)
    wait_for(timeout) { !capture.include?(text) }
  end

  # Wait for screen content to change
  def wait_for_screen_change(timeout = 1)
    initial = capture
    wait_for(timeout) { capture != initial }
  end
end