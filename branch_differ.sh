#!/usr/bin/env bash

# Gerrit branch diff-er

set -eu -o pipefail

UPDATE_GIT=${UPDATE_GIT:-no}
COMMENT_LEN=${COMMENT_LEN:-40}

REPOS="voltha-bbsim \
    voltha-go \
    voltha-openolt-adapter \
    voltha-openonu-adapter \
    pyvoltha"
REF1=origin/master
REF2=origin/voltha-2.1
FORMAT="%s|%s|%s|%s|%s|%.${COMMENT_LEN}s\n"

if [ "$UPDATE_GIT" == "yes" ]; then
    for REPO in $REPOS; do
        if [ ! -d $REPO ]; then
            git clone http://gerrit.opencord.org/$REPO
        else
            cd $REPO
            git fetch --all
            cd ..
        fi
    done
fi

(printf "$FORMAT" "REPOSITORY" "BRANCH" "OWNER" "CHANGE_ID" "PATCHSET" "COMMENT" &&
for REPO in $REPOS; do
    cd $REPO

    # get the commit at which the refs diverge
    COMMON_ANCESTOR=$(git merge-base $REF1 $REF2)

    # Build lists of commits since ancestor on each branch
    REFLIST1=$(git rev-list "${COMMON_ANCESTOR}..${REF1}")
    REFLIST2=$(git rev-list "${COMMON_ANCESTOR}..${REF2}")

    # Build lists of gerrit Change-Id for all commits on each branch
    CHLIST1=
    CHLIST2=
    EXCEPT=

    for changeref in $REFLIST1; do
        CHLIST1+="$(git show -q "$changeref" | grep Change-Id | sed 's/^.*Change-Id: \(.*\)$/\1/g')\n"
    done

    for changeref in $REFLIST2; do
        CHLIST2+="$(git show -q "$changeref" | grep Change-Id | sed 's/^.*Change-Id: \(.*\)$/\1/g')\n"
    done

    # If exceptions or "cleared" change refs are present eliminate those from
    # list
    if [ -r ../$REPO-exceptions.txt ]; then
        for changeref in $(cat ../$REPO-exceptions.txt | sed -e 's/\w*#.*$//g'); do
            EXCEPT+="${changeref}\n"
        done
    fi

    # Find Change-Id's are only found once in the combined list
    UNSHARED=$(uniq -u <(echo -e "${CHLIST1}${CHLIST2}${EXCEPT}" | sort ))

    # print short log message on each branch if that Change-Id's is found
    for unshared in $UNSHARED; do
        unshared_log=$(git log  --pretty="%H|%ae|%s" --grep="$unshared" $REF1)
        if [[ -n $unshared_log ]]; then
            ID=$(echo $unshared_log | cut -d\| -f1)
            OWNER=$(echo $unshared_log | cut -d\| -f2)
            COMMENT=$(echo $unshared_log | cut -d\| -f3)
            printf "$FORMAT" "$REPO" "$(basename $REF1)" "$OWNER" "$unshared" "$ID" "$COMMENT"
        fi
    done
    for unshared in $UNSHARED; do
        unshared_log=$(git log  --pretty="%H|%ae|%s" --grep="$unshared" $REF2)
        if [[ -n $unshared_log ]]; then
            ID=$(echo $unshared_log | cut -d\| -f1)
            OWNER=$(echo $unshared_log | cut -d\| -f2)
            COMMENT=$(echo $unshared_log | cut -d\| -f3)
            printf "$FORMAT" "$REPO" "$(basename $REF2)" "$OWNER" "$unshared" "$ID" "$COMMENT"
        fi
    done
    cd ..
done) | column -tx '-s\|'
