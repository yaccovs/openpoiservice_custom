#!/bin/sh
OSM_PBF_FILE="israel-and-palestine-latest.osm.pbf"
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

if [[ ! -f "osm/$OSM_PBF_FILE" ]] || ! diff <(cd osm; md5sum $OSM_PBF_FILE) <(wget -O - https://download.geofabrik.de/asia/$OSM_PBF_FILE.md5); then
  echo "download pbf...";
  wget https://download.geofabrik.de/asia/$OSM_PBF_FILE -O osm/$OSM_PBF_FILE;
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
