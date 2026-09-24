require "test_helper"
require "open3"

class FreshInstallMigrationsTest < ActiveSupport::TestCase
  MIGRATE_AN_EMPTY_DATABASE = <<~RUBY
    require "bundler/setup"
    require "tmpdir"
    ENV["RAILS_ENV"] = "test"
    require "./test/dummy/config/environment"

    Dir.mktmpdir do |dir|
      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: File.join(dir, "fresh.sqlite3"))
      ActiveRecord::Migration.verbose = false
      ActiveRecord::MigrationContext.new("db/migrate").migrate
    end
  RUBY

  test "easy_flow's migrations run in order from an empty database" do
    output, status = Open3.capture2e(RbConfig.ruby, "-e", MIGRATE_AN_EMPTY_DATABASE, chdir: EasyFlow::Engine.root.to_s)

    assert status.success?, output
  end
end
