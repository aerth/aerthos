#!/bin/bash
# my-chromium-browser.bash
# part of aerthOS (https://github.com/aerth/aerthos)
#################  
## editing: add to urltype switch (above yad), then add to opener switch (below yad)
## installing: 
# update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/my-chromium-browser.bash  500
## remember to run:
# update-desktop-database ~/.local/share/applications
URL=about:blank
if [ ${#} -ne 0 ]; then 
  echo ARGS=$@ | tee -a ${HOME}/.url.log
  URL="$1"
fi
default_browser=(/usr/bin/chromium "--profile-directory=Profile 1")
if [ $? -ne 0 ]; then
	exit 1
fi
open_github(){
	exec /usr/bin/chromium --profile-directory=GithubBrowser --app="$1"
}
open_code(){
	code --open-url "$1"
	return $?
}


urltype=defaultbrowser
echo 1>&2 $URL
# if github prefix, open with github browser
case $URL in
	*https://github.dev*|*https://gist.github.com*|*https://github.com*)
		urltype=github
		;;
	vscode:*)
		urltype=vscode
		;;
	irc:*)
		urltype=irc
		;;
	*)
		urltype=defaultbrowser    
		;;
esac

if [ -z "$URL" ]; then
	URL=about:blank
fi
if [ -z "$urltype" ]; then
	urltype=defaultbrowser
fi

echo "using $urltype to visit $URL" | tee -a ${HOME}/.url.log

urllog=${HOME}/.url.log
# ask user and possibly edit URL
URL=$(yad --title="aerthos-browser ($urltype)" \
	--text="Opening URL (press ESC to kill):" \
	--entry \
	--entry-label="URL:" \
	--entry-text="$URL" \
	--button="Quit:1" \
	--button="Visit:0" \
	--width=300 2>/dev/null)
exitcode=$?
# became blank after edit
if [ -z "$URL" ]; then
	URL="about:blank"
fi
if [ $exitcode -ne 0 ]; then
	echo "CANCEL=\"$URL\"" | tee -a $urllog
	exit 0
fi
echo "URL=\"$URL\"" | tee -a $urllog
case $urltype in 
	github)
		echo 1>&2 "github.com chosen for ${URL}" | tee -a ${HOME}/.url.log
		set -x
		open_github "$URL"
		exit $?
		;;
	irc)
		echo woops
		;;
	vscode)
		set -x
		open_code "$URL"
		;;
	message)
		yad --title not-opening --editable --text "URL: $URL"
		;;
	defaultbrowser)
		set -x
		exec "${default_browser[@]}" "$URL"
		;;
esac
