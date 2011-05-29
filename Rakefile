#!/usr/bin/env ruby
require 'yaml'
require 'erb'

CURRENT_DIR = File.expand_path(File.dirname(__FILE__))
HOME_DIR = File.expand_path("~")

APPENDING_TO_PROFILE_START = "# start: added by git_setup/setup.rb\n"
APPENDING_TO_PROFILE_END = "# end: added by git_setup/setup.rb\n"

task :default => [:install]

desc "set recommended git global configs, and show git statuses on bash prompt"
task :install => %w(git_configs:install bash_prompt:install)

namespace :git_configs do
  git_global_configs = nil

  desc "set recommended git global configs"
  task :install => [:load_config, :update_git_config]

  desc "send git config commands"
  task :update_git_config do
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
    git_version = `git --version`.split(" ")[2]
    config_yaml = ERB.new(File.read(File.join(CURRENT_DIR, "git_configs.yaml"))).result(binding)
    git_global_configs = YAML.load(config_yaml)["global"]
  end
end

namespace :bash_prompt do
  init_src_files = FileList[File.join(CURRENT_DIR, "init_script_additions", "*")]
  init_target_files = init_src_files.map {|f| File.join(HOME_DIR, ".#{f.pathmap("%f")}")}

  sh_src_dir = File.join(CURRENT_DIR, "bash.d")
  sh_target_dir = File.join(HOME_DIR, ".bash.d")
  sh_src_files = FileList[File.join(sh_src_dir, "**/*")]
  sh_target_files = sh_src_files.sub(sh_src_dir, sh_target_dir)

  desc "show git statuses on bash prompt"
  task :install => [:back_up, :update]

  desc "backup current init scripts"
  task :back_up do
    init_target_files.each do |f|
      if File.exists?(f)
        backup_file = "#{f}.saved.#{Time.now.strftime("%Y-%m-%d_%H:%M:%S")}"
        puts "backing up #{f} to #{backup_file}"
        copy_file(f, backup_file, true)
      end
    end
  end

  desc "modify init scripts"
  task :update => sh_target_files do
    init_target_files.each_with_index do |file, i|
      append_to_script = ERB.new(File.read(init_src_files[i])).result(binding)
      rewrite_config_file(file, append_to_script)
    end
  end

  directory sh_target_dir

  sh_src_files.each_with_index do |src, i|
    desc "copy shell file to home dir"
    file sh_target_files[i] => [sh_target_dir, src] do |t|
      install t.prerequisites[1], t.name
    end
  end


end

def rewrite_config_file(target, append_string)
  appends = "\n\n#{APPENDING_TO_PROFILE_START}#{append_string}#{APPENDING_TO_PROFILE_END}"

  puts "  - reading current #{target}"
  contents = []
  File.open(target) {|f| contents = f.readlines} if File.exists?(target)
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
