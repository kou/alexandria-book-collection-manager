# Copyright (C) 2004-2005 Masao Mutoh, Laurent Sansonetti 

copyright = <<EOS
# This file is automatically generated by the installer.
# Do not edit by hands.
EOS

File.open('config.rb', 'w') do |file|
    file.print <<EOS

module Alexandria
    module Config
        MAIN_DATA_DIR = '#{config('data-dir')}'
        DATA_DIR = '#{config('data-dir')}/alexandria'
        LIB_DIR = '#{config('rb-dir')}'
    end
end
EOS
end

File.open('version.rb', 'w') do |file|
    begin
        version = IO.readlines('../../VERSION').join
    rescue Errno::ENOENT
        version = "CVS"
    end
    file.print <<EOS
# This file is automatically generated by the installer.
# Do not edit by hands.

module Alexandria
    VERSION = "#{version}"
end
EOS
end
