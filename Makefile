.PHONY: all
all: ui_tests

dependencies:
	brew install rbenv
	rbenv install 3.0.0
	rbenv local 3.0.0
	gem install bundler
	bundle config set path 'vendor/bundle'
	bundle install

ui_tests: dependencies
	bundle exec fastlane test_ui --verbose

format:
	Scripts/format.sh

snapshots: dependencies
	brew update && brew install imagemagick
	bundle exec fastlane snapshot
	cd fastlane/screenshots
	fastlane frameit

