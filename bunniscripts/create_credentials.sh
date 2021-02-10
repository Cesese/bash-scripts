#!zsh

cfg="$HOME/.config/bunniscripts"
[[ ! -d "$cfg" ]] && mkdir "$cfg"

version="1.0"

/bin/echo -e "This is going to use cesese's app \"cesesefollowings\" and generate an oauth token for your use automatically.\nAre you sure? [y/N]"
read test
[[ ! "$test" = "y" ]] && [[ ! "$test" = "Y" ]] && exit 1

client_id="vukepd8idlqd8ulf4ky5ghlerliqfr"
url="https://id.twitch.tv/oauth2/authorize?response_type=token&client_id=$client_id&redirect_uri=http://localhost&scope=viewing_activity_read"
xdg-open "$url"
/bin/echo -en "You should have been redirected to 'http://localhost#access_token=<an access token>' on your browser after login.\nPlease copy/paste the whole link (easier) or the access token here so the script can get it.\nlink/oauth: "
read oauth

if [ ! "`echo $oauth | egrep "#"`" = "" ]
then
	oauth="`echo $oauth | cut -d'=' -f2 | cut -d'&' -f1`"
fi

/bin/echo -e "$client_id\n$oauth" > $cfg/.credentials.txt
