class AlterListBuilds < ActiveRecord::Migration

  def up

    rename_column :list_builds, :commit_code, :list_commit
    rename_column :list_builds, :prev_commit_code, :prev_list_commit

    remove_column :list_builds, :file_name

    remove_column :list_builds, :commit_started_at
    remove_column :list_builds, :commit_finished_at

    change_column :list_builds, :file_size, :float
    
  end

  def down

    rename_column :list_builds, :list_commit, :commit_code
    rename_column :list_builds, :prev_list_commit, :prev_commit_code

    add_column    :list_builds, :file_name, :string, :limit => 100

    add_column    :list_builds, :commit_started_at, :datetime
    add_column    :list_builds, :commit_finished_at, :datetime

    change_column :list_builds, :file_size, :integer

  end
end

