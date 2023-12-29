#!/bin/bash

#IFS=$'\n'; set -f

LOG=logs/$1.log

if [ -z "$*" ]; then
    echo "Needs a directory argument"
    exit 0
    if [ -d $1 ]; then
        echo $1 is not a directory
        exit 0
    fi
fi

errors=""

# Delete all the non-english translations
delete_translations() {
    set -x
    for lang in id-id ms-my ru-ru th-th tl-ph tr-tr vi-vn zh-tw; do
        find $1 -name "$lang" -type d -exec rm -r "{}" \;
    done
    set +x
}

# Process only the json files so we can look at them while all the rest of the stuff is still decoding
process_json() {
    echo 'begin process_json'
    echo `date`
    OIFS="$IFS"
    IFS=$'\n'
    for file in $(grep --include=*.zip -rPl '^doboyugame' $1); do
        # The ^ anchor doesn't work for lib/libcocos2dlua.so
        if [[ $(head -c10 $file) = doboyugame ]]; then
            echo $file
            /home/ejwu/src/ff/datamine/decode.py $file > /dev/null

            if [[ -f $file-unxxtea ]]; then
                mv $file-unxxtea $file
            else
                echo $file-unxxtea does not exist
                exit 1
            fi
        fi
    done
    IFS="$OIFS"
    echo 'end process_data'
}

process_lua() {
    echo 'begin process_lua'
    echo `date`
    # Try to get every file prefixed by "doboyu", but not "doboyugame"
    # Exclude libcocos2dlua.so, which also contains the strings
    for file in $(grep --exclude=*.so -rPl '^doboyu(?!game)' $1); do
        # The ^ anchor doesn't work for lib/libcocos2dlua.so
        if [[ $(head -c6 $file) = doboyu ]]; then
            echo $file
            /home/ejwu/src/ff/datamine/decode.py $file > /dev/null

            if [[ ! -f $file-unxxtea ]]; then
                echo $file-unxxtea does not exist
                exit 1
            else
                if [[ $file == *lua ]]; then
                    # Overwrite back into the original file
                    java -jar /home/ejwu/src/ff/datamine/unluac/bin/unluac.jar $file-unxxtea > $file-unlua
                    rm $file-unxxtea
                    if [[ ! -f $file-unlua ]]; then
                        echo $file-unlua does not exist
                        exit 1
                    else
                        mv $file-unlua $file
                    fi
                fi
            fi
        fi
    done
    echo 'end process_lua'
}

process_data() {
    echo 'begin process_data'
    echo `date`
    # There's a file with a space in its name that confuses things
    OIFS="$IFS"
    IFS=$'\n'
    # zip files should have already been dealt with in process_json
    for file in $(grep --exclude=*.so --exclude=*.zip -rPl '^doboyugame' $1); do
        # The ^ anchor doesn't work for lib/libcocos2dlua.so
        if [[ $(head -c10 $file) = doboyugame ]]; then
            echo $file
            /home/ejwu/src/ff/datamine/decode.py $file > /dev/null

            if [[ -f $file-unxxtea ]]; then
                mv $file-unxxtea $file
            else
                echo $file-unxxtea does not exist
                exit 1
            fi
        fi
    done
    IFS="$OIFS"
    echo 'end process_data'
}

unzip_everything() {
    echo 'begin unzip_everything'
    echo `date`
    for file in $(find $1 -name '*.zip'); do
        echo $file
        unzip -o $file -d ${file%/*} > /dev/null
        if [ $? -ne 0 ]; then
            echo unzip $file failed >> $LOG
        else
            rm $file
        fi
    done
    echo 'end unzip_everything'
}

prettify_json() {
    echo 'begin prettify_json'
    echo `date`
    for file in $(find $1 -name '*.json'); do
        echo $file
        python -m json.tool $file > $file.pretty
        if [ $? -ne 0 ]; then
            echo prettify $file failed >> $LOG
        else
            rm $file
            mv $file.pretty $file
        fi
    done
    echo 'end prettify_json'
}

unpack_textures() {
    echo 'begin unpack_textures'
    echo `date`
    for file in $(find $1 -name '*.pvr.ccz'); do
        echo $file
        pvr=${file%.ccz}
        prefix=${file%.pvr.ccz}
        dotnet run $prefix --project /home/ejwu/src/ff/datamine/cczp/DecryptCocos2dAsset
        if [ $? -ne 0 ]; then
            echo unccz $file failed from .NET >> $LOG
            errors=$errors"\nunccz $file failed from .NET"
        else
            if [ -f $pvr ]; then
                rm $file
#                TexturePacker $pvr --data $prefix --algorithm Basic --no-trim --png-opt-level 0 --disable-auto-alias --extrude 0 > /dev/null
#                if [ $? -ne 0 ]; then
#                    echo failed to unpack texture $pvr
#                    exit 1
#                else
#                    rm $pvr
#                    if [ -f $prefix ]; then
                        # This line changes every time a .pvr is unpacked, making the diffs unhelpful
#                        sed '/\$TexturePacker\:SmartUpdate/d' -i $prefix
#                    fi
#                fi                    
            else
                echo unccz $file failed to generate $pvr
#                exit 1
            fi
        fi

    done
    echo 'end unpack_textures'
}

# Nuke non-en-US locales
delete_translations $1
# Decode json first to allow faster analysis
process_json $1
# json files are all zipped, unzip and then prettify them
unzip_everything $1
prettify_json $1
# Decode doboyu prefixes (lua)
process_lua $1
# Back to doboyugame files, mostly images 
process_data $1
# Unpack ccz images
unpack_textures $1

# Hack, more json found in the later process steps
process_json $1
prettify_json $1

echo $errors

echo "done"
echo `date`

#unset IFS; set +f
