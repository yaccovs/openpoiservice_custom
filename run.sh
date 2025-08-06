#!/bin/sh

FLAG_FILE="osm/first_run.flag"
MAX_AGE_DAYS=30

should_run=false

# בדיקה אם הקובץ לא קיים
if [[ ! -f "$FLAG_FILE" ]]; then
    echo "First run, create-db"; 
    python manage.py drop-db
    python manage.py create-db
    touch "$FLAG_FILE";
fi

if ! diff <(cd osm; md5sum israel-and-palestine-latest.osm.pbf) <(curl https://download.geofabrik.de/asia/israel-and-palestine-latest.osm.pbf.md5); then
  echo "download pbf...";
  wget https://download.geofabrik.de/asia/israel-and-palestine-latest.osm.pbf -O osm/israel-and-palestine-latest.osm.pbf;
  echo "Updating POI database"
  python manage.py import-data;
fi

if [[ ! -z "$UPDATE_DB" ]]; then
  echo "Updating POI database"
  python manage.py import-data
elif [[ ! -z "$INIT_DB" ]]; then
    echo "Initializing POI database"
    python manage.py drop-db
    python manage.py create-db
    python manage.py import-data
elif [[ ! -z "$TESTING" ]]; then
  echo "Running tests"
  export TESTING="True"
  python manage.py test
else
  gunicorn --config gunicorn_config.py manage:app
fi
