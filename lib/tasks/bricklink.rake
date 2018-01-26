namespace :bricklink do
  task :get_all_set_values => :environment do
    BricklinkQueueGetSetValueJobs.perform_later
  end

  task :delete_all_bricklink_values => :environment do
    BricklinkValue.destroy_all
  end

  task :push_values_to_heroku => :environment do
    re = /postgres:\/\/([a-zA-Z0-9]*):([a-zA-Z0-9]*)@([a-zA-Z0-9\-\.]*):([0-9]*)\/([a-zA-Z0-9]*)/
    filepath = "_bricklink_sql_dumps_/bricklink_values_#{Time.now.to_i}.sql"

    %x{ pg_dump --data-only --table=bricklink_values brickulator_api_development > #{filepath} }

    heroku_db_config = %x{ heroku config | grep HEROKU_POSTGRESQL }
    config = heroku_db_config.scan(re).flatten

    host = config[2]
    port = config[3]
    username = config[0]
    db_name = config[4]
    password = config[1]
    command = "PGPASSWORD=#{password} psql -h #{host} -p #{port} -U #{username} #{db_name} < #{filepath}"

    %x{ #{command} }

    # puts heroku_db_config
# psql -h ec2-107-22-183-40.compute-1.amazonaws.com -p 5432 -U hkqxmggoatsqid d9t8pireu4lls9 < bricklink_values.sql

# 760265de0731ae175c7d11a83c35aac4092a0c3953604f9a03f1f1df50b04ff1

  end
end
