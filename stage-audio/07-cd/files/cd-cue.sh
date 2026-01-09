#!/bin/bash

ENV_FILE="/tmp/cd_var.env"
MB_URL="https://musicbrainz.org/ws/2"
COVER_ART_URL="https://coverartarchive.org/release"
CACHE_LOCATION="/home/$(id --user --name 1000)/.cddb"

getDiscId() {
    ./mbdiscid.pl || { logger "Error: Failed to fetch Disc ID"; exit 1; }
}

getRelease() {
    local disc_id="$1"
    res=$(curl -s "${MB_URL}/discid/${disc_id}?inc=artists+recordings+release-groups&fmt=json") || {
        logger "Error: Failed to fetch release data"; exit 1; }

    echo "$res" | jq -c '.releases[0]'
}

getCoverArtFromMBId() {
    local mb_id="$1"
    local cover_file="$2"
    wget --quiet "${COVER_ART_URL}/${mb_id}/front" -O "${cover_file}"
}

createPlaylist() {
    local cue_file="$1"
    local release="$2"
    local disc_cover="$3"
    install --mode=644 --owner=1000 --group=1000 /dev/null "${cue_file}"

    if [[ -z "$release" ]]; then
        logger "Error: No release data found."
        return 1
    fi

    disc_title=$(echo "$release" | jq -r '.title')
    disc_performer=$(echo "$release" | jq -r '.["artist-credit"][0].name')
    disc_year=$(echo "$release" | jq -r '.date')

    # Write CUE file
    {
        echo "REM DATE \"${disc_year}\""
        echo "REM COVER \"${disc_cover}\""
        echo "PERFORMER \"${disc_performer}\""
        echo "TITLE \"${disc_title}\""
        track_number=1
        echo "$release" | jq -rc '.media[0].tracks | sort_by(.position) | .[].title' | while IFS= read -r track; do
            echo "FILE \"cdda:///${track_number}\" WAVE"
            echo "  TRACK $(printf "%02d" "${track_number}") AUDIO"
            echo "    TITLE \"${track}\""
            ((track_number++))
        done
    } > "${cue_file}"
    logger "info: CUE file generated: ${cue_file}"
}

rm --force "${ENV_FILE}"

disc_id=$(getDiscId)
#disc_id="VBp.rfhj1s2PoGNYGjpzmsk_vV0-"
cue_file="${CACHE_LOCATION}/${disc_id}.cue"
if [[ ! -s "${cue_file}" ]]; then
    release=$(getRelease "${disc_id}")
    cover_file="${CACHE_LOCATION}/${disc_id}.jpg"
    if [[ ! -s ${cover_file} ]]; then
        getCoverArtFromMBId "$(echo "${release}" | jq -r '.id')" "${cover_file}"
    fi
    createPlaylist "${cue_file}" "${release}" "${cover_file}"
fi

logger "info: Playlist found ${cue_file}"
echo "$cue_file" > "${ENV_FILE}"
