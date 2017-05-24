require 'shellwords'

DEPS = %w{Contents.swift Resources Sources}

task :default => :build

desc 'Build both macOS Xcode- and iPad-compatible Swift playgrounds'
task :build => [:'ipad:build', :'xcode:build']

desc 'Delete both built playground files'
task :clean => [:'ipad:clean', :'xcode:clean']

namespace :ipad do
  IPAD_TARGET = 'iPad.playground'

  desc 'Create an iPad-compatible Swift playground'  
  task :build do
    `mkdir -p #{IPAD_TARGET}`
    DEPS.each { |dep| `cp -R #{dep.shellescape} #{IPAD_TARGET}` }

    contents = <<~CONTENTS
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <playground version='6.0' target-platform='ios' display-mode='raw'/>
    CONTENTS
    File.write("#{IPAD_TARGET}/contents.xcplayground", contents)
  end

  desc 'Delete the built iPad.playground'  
  task :clean do
    `rm -rf #{IPAD_TARGET}`
  end

  desc 'Copy source files from iPad.playground to the root directory'
  task :sync do
    DEPS.each { |dep| `cp -R #{IPAD_TARGET}/#{dep.shellescape} .` }
  end
end

namespace :xcode do
  XCODE_TARGET = 'Xcode.playground'

  desc 'Create an macOS Xcode-compatible Swift playground'  
  task :build do
    `mkdir -p #{XCODE_TARGET}`
    DEPS.each { |dep| `cp -R #{dep.shellescape} #{XCODE_TARGET}` }
    
    contents = <<~CONTENTS
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <playground version='5.0' target-platform='macos' executeOnSourceChanges='false'/>
    CONTENTS
    File.write("#{XCODE_TARGET}/contents.xcplayground", contents)
  end

  desc 'Deletes the built Xcode.playground'  
  task :clean do
    `rm -rf #{XCODE_TARGET}`
  end

  desc 'Copy source files from Xcode.playground to the root directory'
  task :sync do
    DEPS.each { |dep| `cp -R #{XCODE_TARGET}/#{dep.shellescape} .` }
  end
end
