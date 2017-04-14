# Configuration
URL="http://www.byu.edu/housing/apps/apts.aspx"

# Preferences
read -r -d '' PREFERENCES <<'EOF'
Rooms: 1 2
Floor: 1 2 3
Location: Wyview wymount
Available: May June
EOF

function trimWhiteSpace(){
  read var
  # remove leading whitespace characters
  var="${var#"${var%%[![:space:]]*}"}"
  # remove trailing whitespace characters
  var="${var%"${var##*[![:space:]]}"}"
  echo "$var"
}

function filterPreference(){
  INPUT="$1"

  # For each line in preferences
  while read -r preference; do
    FIELD="$(echo $preference | cut -d':' -f1 | trimWhiteSpace)"
    VALUES="($(echo $preference | cut -d':' -f2 | trimWhiteSpace | sed 's/  */|/g'))"

    SEARCHSTRING='#'"$FIELD"':[^#]*'"$VALUES"'[^#]*'

    INPUT="$(echo "$INPUT" | grep -i -E $SEARCHSTRING)"

  done <<< "$PREFERENCES"
  echo "$INPUT"
}

# Retrieve data
FULLPAGE="$(curl --silent "http://www.byu.edu/housing/apps/apts.aspx")"

# Parse out the lines we're interested in
LINES="$(echo "$FULLPAGE" | grep "<tr>" | sed 's/[<]tr[>]/\n/g' | grep ":none'>2.../../..</span>")"

# Adjust formatting
FORMATTED="$(echo "$LINES"                                              \
  | sed 's/<\/td><td>/<tdb>/ g'                                         \
  | sed 's/<td>/#Location: /'                                           \
  | sed 's/<tdb>[^<]*<tdb>/#Rooms: / '                                  \
  | sed 's/<tdb>\([^<]*\)<tdb>/#Floor: \1/ '                            \
  | sed 's/<[^<]*<\/span>[^<]*<tdb><[^<]*<\/span>/#Available: /g'       \
  | sed 's/<tdb>.*//g'                                                  \
  | sed 's/<span[^<]*<\/span>//')"

# Filter
filterPreference "$FORMATTED" | tr '#' '\n'
