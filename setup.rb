#!/usr/bin/env ruby
require 'fileutils'

ALIASES = {
  :co => "checkout",
  :ci => "commit",
  :st => "status",
  :br => "branch",
  :f => "fetch",
  :m => "merge",
  :rb => "rebase",
  :rbo => "rebase origin/master",
  :cp => "cherry-pick",
  :s => "submodule",
  :su => "submodule update --init"
}
GLOBALS = [
  ["setting colorful output", "color.ui" => "auto"],
  ["make push only pushes current branch", "push.default" => "upstream"],
  ["make pull do the rebase instead of merge", "branch.autosetuprebase" => "always"]
]
APPENDING_TO_PROFILE_START = "# start: added by git_setup/setup.rb\n"
APPENDING_TO_PROFILE_END = "# end: added by git_setup/setup.rb\n"

def set_git_global_config(key, value)
  command = "git config --global #{key} '#{value}'"
  puts "    - #{command}"
  system command
end

def rewrite_config_file(target, append_string)
  appends = "\n\n#{APPENDING_TO_PROFILE_START}#{append_string}#{APPENDING_TO_PROFILE_END}"

  puts "    - reading current #{target}"
  contents = []
  File.open(target) {|f| contents = f.readlines} if File.exists?(target)

  if File.exists?(target)
    backup_file = target + ".saved.#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}"
    puts "    - backing up #{target} to #{backup_file}"
    FileUtils.copy_file(target, backup_file, true)
  end

  if added_starts = contents.index(APPENDING_TO_PROFILE_START) and
      added_ends = contents.index(APPENDING_TO_PROFILE_END) and
      added_starts < added_ends
    puts "    - removing lines added beforehand"
    contents[added_starts, added_ends] = nil
    2.times {|t| contents[added_starts - t.succ] = nil if  contents[added_starts - t.succ] == "\n"}
  end

  puts "    - adding strings"
  contents << appends

  puts "    - writing new #{target}"
  File.open(target, "w+") do |f|
    f.write(contents.join(""))
  end
end


puts "setting global aliases"
ALIASES.each { |k, v| set_git_global_config("alias.#{k.to_s}", v) }

puts "setting other globals"
GLOBALS.each do |g|
  commands = g.last.is_a?(::Hash) ? g.pop : {}
  puts "  - #{g.first}"
  commands.each  { |k, v| set_git_global_config(k ,v) }
end

puts "adding git status to prompt"

puts "  - rewriting bashrc"
bashrc = File.join(File.expand_path("~"), ".bashrc")
source_file = File.expand_path(__FILE__).sub(File.basename(__FILE__), "bash_prompt_with_git")
append_to_bashrc = <<-EOS
# if running bash
if [ -n \"$BASH_VERSION\" ]; then
    # include #{source_file}
    if [ -f '#{source_file}' ]; then
        . '#{source_file}'
    fi
fi
EOS
rewrite_config_file(bashrc, append_to_bashrc)

puts "  - rewriting profile"
profile = File.join(File.expand_path("~"), ".bash_profile")
profile = File.join(File.dirname(profile), ".profile") unless File.exist?(profile)
append_to_profile = <<-EOS
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
EOS
rewrite_config_file(profile, append_to_profile)

puts "finished"
