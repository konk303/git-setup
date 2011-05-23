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

puts "setting global aliases"
ALIASES.each do |k, v|
  command = "git config --global alias.#{k.to_s} '#{v}'"
  puts "  - #{command}"
  system command
end

puts "setting other globals"
GLOBALS.each do |g|
  commands = g.last.is_a?(::Hash) ? g.pop : {}
  puts "  - #{g.first}"
  commands.each do |k, v|
    command = "git config --global #{k.to_s} '#{v}'"
    puts "    - #{command}"
    system command
  end
end


puts "adding git status to prompt"
source_file = File.expand_path(__FILE__).sub(File.basename(__FILE__), "bash_prompt_with_git")
append_string = <<-EOS
# if running bash
if [ -n \"$BASH_VERSION\" ]; then
    # include #{source_file}
    if [ -f '#{source_file}' ]; then
        . '#{source_file}'
    fi
fi
EOS
append_string = "\n\n#{APPENDING_TO_PROFILE_START}#{append_string}#{APPENDING_TO_PROFILE_END}"
target_file = File.join(File.expand_path("~"), ".bash_profile")
target_file = File.join(File.dirname(target_file), ".profile") unless File.exist?(target_file)
backup_file = target_file + ".saved.#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}"

puts "  - reading current #{target_file}"
contents = []
File.open(target_file) {|f| contents = f.readlines}

puts "  - backing up #{target_file} to #{backup_file}"
FileUtils.copy_file(target_file, backup_file, true)

if added_starts = contents.index(APPENDING_TO_PROFILE_START) and
    added_ends = contents.index(APPENDING_TO_PROFILE_END) and
    added_starts < added_ends
  puts "  - removing lines added beforehand"
  contents[added_starts, added_ends] = nil
  2.times {|t| contents[added_starts - t.succ] = nil if  contents[added_starts - t.succ] == "\n"}
end

puts "  - including #{source_file}"
contents << append_string

puts "  - writing new #{target_file}"
File.open(target_file, "w+") do |f|
  f.write(contents.join(""))
end

puts "finished"
