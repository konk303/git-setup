#!/usr/bin/env ruby
require 'yaml'
require 'erb'

APPENDING_TO_PROFILE_START = "# start: added by git_setup/setup.rb\n"
APPENDING_TO_PROFILE_END = "# end: added by git_setup/setup.rb\n"

GIT_VERSION = `git --version`.split(" ")[2]
CURRENT_DIR = File.expand_path(File.dirname(__FILE__))
HOME_DIR = File.expand_path("~")

task :default => [:install]

desc "set recommended git global configs, and show git statuses on bash prompt"
task :install => %w(git_configs:set bash_prompt:install)

namespace :git_configs do
  git_global_configs = nil

  desc "set recommended git global configs"
  task :install => [:load_config] do
    puts "setting global configs"
    git_global_configs.each do |category, configs|
      configs.each do |k, v|
        key = "#{category}.#{k}"
        value = v.is_a?(String) ? v : v["value"]
        description = v.is_a?(String) ? "#{key} -> #{value}" : v["desc"]
        command = "git config --global #{key} '#{value}'"
        puts "  - #{description}"
        puts "    - #{command}"
        sh command
      end
    end
  end

  desc "load configs from yaml"
  task :load_config do
    config_yaml = ERB.new(File.read(File.join(CURRENT_DIR, "git_configs.yaml"))).result
    git_global_configs = YAML.load(config_yaml)["global"]
  end
end

namespace :bash_prompt do
  desc "show git statuses on bash prompt"
  task :install

  desc "hoge"
  directory File.join(HOME_DIR, ".bash.d")
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



# puts "adding git status to prompt"

# puts "  - rewriting bashrc"
# bashrc = File.join(File.expand_path("~"), ".bashrc")
# source_file = File.expand_path(__FILE__).sub(File.basename(__FILE__), "bash_prompt_with_git")
# append_to_bashrc = ERB.new(File.read(File.join(CURRENT_DIR, "bashrc_addition"))).result
# rewrite_config_file(bashrc, append_to_bashrc)

# puts "  - rewriting profile"
# profile = File.join(File.expand_path("~"), ".bash_profile")
# profile = File.join(File.dirname(profile), ".profile") unless File.exist?(profile)
# append_to_profile = ERB.new(File.read(File.join(CURRENT_DIR, "profile_addition"))).result
# rewrite_config_file(profile, append_to_profile)
