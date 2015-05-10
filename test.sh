#!/bin/bash
###
### The following block runs after commit to "master" branch
###

    # function to convert a plain .md file to one that renders nicely in gh-pages
    function convert {
        # sed - convert links with *.md to *.html (assumed relative links in local pages)
        # awk - convert backtick fencing to highlights (script from bottom of file)
        sed -e 's/(\(.*\)\.md)/(\1.html)/g' "$1" | awk -f <(sed -e '0,/^#!.*awk/d' $0) > _temp && mv _temp "$1"
    } 

    if ! git show-ref --verify --quiet refs/heads/gh-pages; then
        echo "No gh-pages, so not syncing"
        exit 0
    fi

    # Switch to gh-pages branch to sync it with master
    ###################################################################
    git checkout gh-pages

    mkdir -p _includes

    # Sync the README.md in master to index.md adding jekyll header
    ###################################################################
    git checkout master -- README.md
    if [ -f README.md ]; then
        cp README.md _includes/
        convert _includes/README.md
        git add README.md
        git add _includes/README.md
    fi

    # Generate index if there isn't one already
    ###################################################################
    if [ ! -f index.md ]; then
        echo -e '---\ntitle: Docs\nlayout: default\n---\n\n{% include README.md %}' > index.md
        git add index.md
    fi

    # Generate a header if there isn't one already
    ###################################################################
    if [ ! -f _includes/header.txt ]; then
        echo -e '---\ntitle: Docs\nlayout: default\nhome: \n---\n\n' > _includes/header.txt
        git add _includes/header.txt
    fi

    # Sync the markdown files in all docs/* directories
    ###################################################################
    for file in `git ls-tree -r --name-only master | grep 'docs/.*\.md'`
    do
        git checkout master -- "$file"
        dir=`echo ${file%/*} | sed -e "s,[^/]*,..,g"`
        cat _includes/header.txt | sed -e "s,^home: .*$,home: ${dir}/," > _temp
        cat "$file" >> _temp && mv _temp "$file"
        convert "$file"
        git add "$file"
    done

    git commit -a -m "Sync docs from master branch to docs gh-pages directory"

    # Uncomment the following push if you want to auto push to
    # the gh-pages branch whenever you commit to master locally.
    # This is a little extreme. Use with care!
    ###################################################################
    # git push origin gh-pages

    # Finally, switch back to the master branch and exit block
    git checkout master