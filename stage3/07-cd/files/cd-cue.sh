#!/bin/bash

CDDB_URL="http://gnudb.gnudb.org/~cddb/cddb.cgi"
OPTS="3 $(whoami) $(hostname)"
CACHE_LOCATION="/home/$(id --user --name 1000)/.cddb"
ENV_FILE="/tmp/cd_var.env"

createPlaylist() {
    local cue_file="$1"
    local data="$2"
    install --mode=644 --owner=1000 --group=1000 /dev/null "${cue_file}"

    IFS=$'\n' read -r -d '' -a lines <<< "$data"
    local full_title=""
    local tracks=()
    for line in "${lines[@]}"; do
        case "$line" in
            DTITLE=*)
                full_title=$(echo "${line#DTITLE=}" | sed 's/\r//')
                ;;
            TTITLE*)
                title=$(echo "${line#TTITLE*=}" | sed 's/\r//')
                tracks+=("${title}")
                ;;
        esac
    done

    if [[ -z $full_title ]]; then
        logger "error: Unable to create playlist with data"
        return 1
    fi

    local disc_performer="${full_title%% / *}"
    local disc_title="${full_title##* / }"

    # Write CUE file
    {
        echo "PERFORMER \"${disc_performer}\""
        echo "TITLE \"${disc_title}\""
        for i in "${!tracks[@]}"; do
            echo "FILE \"cdda:///$((i+1))\" WAVE"
            echo "  TRACK $(printf "%02d" $((i+1))) AUDIO"
            echo "    TITLE \"${tracks[$i]}\""
        done
    } > "${cue_file}"
    logger "info: CUE file generated: ${cue_file}"
}

queryDB() {
    local cd_id="$1"
    local cd_from_db
    local cddb_id

    cd_from_db=$(cddb-tool query "$CDDB_URL" $OPTS "$cd_id")
    cddb_id=$(echo "$cd_from_db" | head -1 | awk '{print $2 " " $3}')
    if [[ $cddb_id == "No match" ]]; then
        logger "error: No match found for CD ID ${cd_id} in ${CDDB_URL}"
        return 1
    fi
    cddb-tool read "$CDDB_URL" $OPTS "$cddb_id"
}

getCachedOrQueryData() {
    local cd_id="$1"
    local cache_file="$2"
    # Check if data is cached
    if [[ -f "${cache_file}" && -s "${cache_file}" ]]; then
        logger "info: Reading ${cd_id} from ${cache_file}"
        cat "${cache_file}"
        return 0
    fi

    # Query the CDDB if not cached
    if ! infos=$(queryDB "${cd_id}"); then
        return 1
    fi
    logger "info: match found in CDDB"
    echo "${infos}" | tee "${cache_file}"
}

rm --force "${ENV_FILE}"

CD_ID=$(cd-discid /dev/sr0)
NAME_FILE=$(echo "${CD_ID}" | awk '{print $1}')

cue_file="${CACHE_LOCATION}/${NAME_FILE}.cue"

# Check if the CUE file does not exist or is empty
if [[ ! -s "${cue_file}" ]]; then
    if ! data=$(getCachedOrQueryData "${CD_ID}" "${CACHE_LOCATION}/${NAME_FILE}"); then
        logger "error: Failed to get data for ${NAME_FILE}"
        exit 1
    fi
    if ! createPlaylist "${cue_file}" "${data}"; then
        logger "error: Failed to create playlist for ${NAME_FILE}"
        exit 1
    fi
fi

logger "info: Playlist found ${cue_file}"
echo "CUE_FILE=${cue_file}" > "${ENV_FILE}"
