pg_dump --data-only --table=bricklink_values brickulator_api_development > bricklink_values.sql

heroku config | grep HEROKU_POSTGRESQL

psql -h ec2-107-22-183-40.compute-1.amazonaws.com -p 5432 -U hkqxmggoatsqid d9t8pireu4lls9 < bricklink_values.sql

760265de0731ae175c7d11a83c35aac4092a0c3953604f9a03f1f1df50b04ff1
