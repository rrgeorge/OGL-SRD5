#!/usr/bin/env bash
CWD=`pwd`
mkdir SRD
cat > SRD/Module.yaml << YAML
id: c425e0ee-6203-53df-9202-aa5df5234832
name: The Systems Reference Document
slug: the-systems-reference-document
description: The Systems Reference Document (SRD) contains guidelines for publishing content under the Open-Gaming License (OGL). The Dungeon Masters Guild also provides self-publishing opportunities for individuals and groups.
author: Wizards of the Coast
category: rules
code: srd-5.1
version: 5.1
YAML

for f in [0-9]*.md
do
    echo $f
    SEC=`head -1 $f|sed -e 's/^#* //;s/.*/\L&/;s/[a-z]*/\u&/g'`
    if [ -z "$SEC" ]
    then
        continue
    fi
    ORD="${f%.*.*}"
    mkdir "SRD/$SEC"
    re='^[0-9]+$'
    if [[ $ORD =~ $re ]] ; then
        #echo -e "name: $SEC\nslug: $(slugify "$SEC")\norder: $ORD" > "SRD/$SEC/Group.yaml"
        echo -e "name: $SEC\norder: $ORD" > "SRD/$SEC/Group.yaml"
    else
        #echo -e "name: $SEC\nslug: $(slugify "$SEC")" > "SRD/$SEC/Group.yaml"
        echo -e "name: $SEC" > "SRD/$SEC/Group.yaml"
    fi
    csplit -s $f '/^# /' '{*}' --prefix="SRD/$SEC/${f%.*}" --suffix='-%0.2d.md'
    cd "SRD/$SEC"
    find . -empty -type f -delete
    for i in *.md
    do
        if $( grep -qPzi "^# \Q$SEC\E\n+$" "$i" )
        then
            rm -v "$i"
            continue
        fi
        TITLE=`head -1 $i|sed -e 's/^#* //;s/.*/\L&/;s/[a-z]*/\u&/g'`
        SLUG=`/usr/bin/slugify "$TITLE"`
        SORD=${i#*-}
        SORD=${SORD%.*}
        mv "$i" "$TITLE.md"
        if [[ "${TITLE% *}" == "Monsters" ]]
        then
            csplit -s "$TITLE.md" '/^###\? /' '{*}' --prefix="monster" --suffix='-%0.2d.md'
            mc=1
            rm "$TITLE.md"
            for m in monster-*.md
            do
                if $( grep -qPzi "^# \Q$TITLE\E\n+$" "$m" )
                then
                    cat "$m" >> "$TITLE.md"
                    continue
                fi
                MONSTER=`head -1 "$m"|sed -e 's/^#* //;s/.*/\L&/;s/[a-z]*/\u&/g;s/\//_/g'`
                sed -i -E -e '
                    /^$/d
                    s/\|([-|]*| STR.*CHA *)\|//;s/\| *([0-9]+).*\| *([0-9]+).*\| *([0-9]+).*\| *([0-9]+).*\| *([0-9]+).*\| *([0-9]+).*\|/str: \1\ndex: \2\ncon: \3\nint: \4\nwis: \5\ncha: \6/
                    s/^\*{2}Armor Class\*{2} /ac: /
                    s/^\*{2}Hit Points\*{2} /hp: /
                    s/^\*{2}Speed\*{2} /speed: /
                    s/^\*{2}Saving Throws\*{2} /saves: /
                    s/^\*{2}(Damage|Condition) Immunities\*{2} /\L\1\uImmunities: /
                    s/^\*{2}Damage (Vulnerabilities|Resistances)\*{2} /\L\1: /
                    s/^\*{2}Challenge\*{2} (.*?)( ?\(.*?\))?/challenge: \1\ntraits:/
                    s/^\*{2}([a-zA-Z]*)\*{2} /\L\1: /
                    s/^\*{2,3}([^*]*)\*{2,3}. (.*)/  - name: \1\n    description: "\2"/
                    /^###### Legendary Actions/{$!{N;/^##+ .*\n$/N;s/^###### Legendary Actions\n+(.*)/legendaryActions:\n  "\1"/}}
                    s/^###### (.*)/\L\1:/
                    /^$/d
                    /##+ / {$!{N;/^##+ .*\n$/N;s/^(##+ ([^\n]*))\n+\*(Tiny|Small|Medium|Large|Huge|Gargantuan) (.*), ([^*]*)\*(.*)/\1\nname: \2\nsize: \3\ntype: \4\nalignment: \5/;t;P;D}}
                    ' "$m"
                csplit -s "$m" '/^##+ /' '{*}' --prefix="mtmp" --suffix='-%0.2d.md'
                for mtmp in mtmp-*.md
                do
                    sed -E -e '5,$s/##+/```\n\0/;s/^name: .*/```Monster\n\0/;$a```' "$mtmp" >> "$MONSTER.md"
                    rm "$mtmp"
                done
                rm "$m"
                sed -i "1s/^/---\\nname: $MONSTER\\nparent: $SLUG\\norder: $mc\\n---\\n/" "$MONSTER.md"
                #mv "$m" "$MONSTER.md"
                mc=$((mc+1))
            done
        else
            sed -i -E -e 's/([0-9]*[dD][0-9]+([+-][0-9]+)?)/[\1](\/roll\/\1)/' "$TITLE.md"
        fi
        if [[ $SORD =~ $re ]] ; then
            #sed -i "1s/^/---\\nname: $TITLE\\nslug: $SLUG\\norder: $SORD\\n---\\n/" "$TITLE.md"
            sed -i "1s/^/---\\nname: $TITLE\\norder: $SORD\\n---\\n/" "$TITLE.md"
        else
            #sed -i "1s/^/---\\nname: $TITLE\\nslug: $SLUG\\n---\\n/" "$TITLE.md"
            sed -i "1s/^/---\\nname: $TITLE\\n---\\n/" "$TITLE.md"
        fi
    done
    cd $CWD
done
mkdir SRD/Legal
cp legal.md SRD/Legal/
cp README.md SRD/Legal/
cp "RE&.logo.png" SRD/Legal/
echo -e "name: Legal\nslug: legal\norder: 99999" > "SRD/Legal/Group.yaml"
