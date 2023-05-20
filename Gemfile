# frozen_string_literal: true

source "https://rubygems.org"

# The gem's dependencies are specified in the gemspec
gemspec

group :development, :test do
  gem "pry"
  gem "simplecov"
  gem "yard", "~> 0.9.5"
end

gem "segv-handler-gdb"
git "file://#{Dir.pwd}/ruby-gnome/.git" do
  gem "atk"
  gem "cairo-gobject"
  gem "gdk3"
  gem "gdk_pixbuf2"
  gem "gio2"
  gem "glib2"
  gem "gobject-introspection"
  gem "gtk3"
  gem "pango"
end
