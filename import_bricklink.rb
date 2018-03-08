#!/usr/bin/env ruby
dir = "/Users/kevinpersonal/Sites/brickulator-api"
system( "cd #{dir}" )
system( "dropdb brickulator_api_development" )
system( "heroku pg:pull DATABASE_URL brickulator_api_development --app brickulator-api" )
system( "heroku local:run rake db:migrate" )
system( "heroku local:run rake bricklink:delete_all_bricklink_values" )
system( "heroku local:run rake bricklink:get_all_set_values" )
system( "heroku local" )
