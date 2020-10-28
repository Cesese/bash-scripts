#!/usr/bin/zsh

version="1.0"

followings="twitch_following.txt"

infinity='\u221e'

usage="USAGE\n\t$0 [-h/-v/-f] [-s/-g/-c/-w <arg>]\nARGUMENTS\n\t[-h/--help]\n\t\tPrints usage\n\t[-v/--version]\n\t\tPrints version\n\t[-s/--stream] <channel(s)> (1-100 args)\n\t\tMake a get call on 'https://api.twitch.tv/helix/streams?user_login=<channel>'.\n\t\tUseful to check if a stream is online, and to get information like the stream's title or category.\n\t\tYou can repeat the call for multiple channels, for instance:\n\t\t$0 --stream channel1 channel2 channel3 ...\n\t\tfor up to 100 channels\n\t[-f/--followings] (0 arg)\n\t\tSame as --stream, except that it reads the channels from the file $followings.\n\t\tAlso, it's not limited to 100 channels.\n\t[-g/--game] <game ids> (1-100 args)\n\t\tMake a call to get information on a game.\n\t[-vi/--video] <video id(s)> (1-100 args)\n\t\tGives you info on the videos\n\t[-c/--channel] <username> (1 arg)\n\t\tSame as --video, but for a channel.\n\t[-w/--watch] <channel> <video player> [args] (2-$infinity args)\n\t\tStarts said stream through said video player. For instance:\n\t\t$0 --watch lilypichu mpv\n\t\t-> mpv https://twitch.tv/lilypichu\n\t[-/--]\n\t\tDescription"
usage=`/bin/echo -e $usage | head -n -2` # this is so we don't print the template at the end

client_id=`cut -d$'\n' -f1 .credentials.txt`
oauth_token=`cut -d$'\n' -f2 .credentials.txt`

die()
{
	/bin/echo -e $usage 1>&2
	exit 1
}

if [ "$#" -eq "0" ]
then
	die	
fi

# https://dev.twitch.tv/docs/api/reference

# commercial() {}
# I don't need it

# extension_analytics() {}
# I don't need it

# get_cheermotes() {}
# I don't need it

# game_analytics() {}
# I don't need it

# bits_leaderboard() {}
# I don't need it

# extension_transaction_list() {}
# I don't need it

create_clip()
{
	# in : streamer ID 
	POST -H "client-id: $client_id" -H "Authorization: Bearer $oauth_token" https://api.twitch.tv/helix/clips?broadcaster_id=$1	
	# out : id of the clip + edit url
}

get_clips()
{
	# in : clip id
	GET -H "client-id: $client_id" -H "Authorization: Bearer $oauth_token" https://api.twitch.tv/helix/clips?id=$1
	# out : lots of info https://dev.twitch.tv/docs/api/reference#get-clips
}

# entitlement() {}
# I don't need it

# get_code_status() {}
# I don't need it

# entitlement_list() {}
# I don't need it

# redeem_code() {}
# I don't need it

# get_top_games() {}
# I don't need it

get_games()
{
	# in : list of game IDs
	a=( $@ )
	b=""
	for c in $a
	do
		b="$b&id=$c"
	done
	b=${b:1}
	GET -H "client-id: $client_id" -H "Authorization: Bearer $oauth_token" "https://api.twitch.tv/helix/games?$b"
	# out : id/name/boxart for each game
}

# hype_train() {}
# I don't need it

# check_automod() {}
# I don't need it

# get_banned_users() {}
# I don't need it

# get_banned_events() {}
# I don't need it

# get_mods() {}
# I don't need it

# get_mod_events() {}
# I don't need it

# search_categories() {}
# I don't need it

# search_channels() {}
# I don't need it

# get_stream_key() {}
# I don't need it

get_streams()
{
	a=( $@ )
	b=""
	for c in $a
	do
		b="$b&user_login=$c"
	done
	b=${b:1}
	GET -H "client-id: $client_id" -H "Authorization: Bearer $oauth_token" "https://api.twitch.tv/helix/streams?$b"
}

# create_marker() {}
# I don't need it

# get_markers() {}
# I don't need it

# get_channel_info() {}
# I don't need it

edit_channel_info()
{
	# in : game id, broadcaster language, title
	PATCH -H "client-id: $client_id" -H "Authorization: Bearer $oauth_token" "https://api.twitch.tv/helix/channels?broadcaster_id=$my_id&game_id=$1&broadcaster_language=$2&title=$3"
	# out : 204 = successful, 400 = client error, 500 = server error
}

# get_subs() {}
# I don't need it

# get_all_stream_tags() {}
# I don't need it

# get_stream_tags() {}
# I don't need it

# edit_stream_tags() {}
# I don't need it

# follow() {}
# I'll do it later (also need to edit my local files)

# unfollow() {}
# bis

get_users() 
{
	# in : usernames (up to 100)
	a=( $@ )
	b=""
	for c in $a
	do
		b="$b&login=$c"
	done
	b=${b:1}
	GET -H "client-id: $client_id" -H "Authorization: Bearer $oauth_token" "https://api.twitch.tv/helix/users?$b"
	# out : id
}

# get_users_follows() {}
# I don't need it

# update_user() {}
# I don't need it

# get_user_extensions() {}
# I don't need it

# get_user_active_extensions() {}
# I don't need it

# update_user_extensions() {}
# I don't need it

get_videos()
{
	# in : "id"/"user_id"/"game_id" (id limited to 100 videos, others limited to 1 user/game) followed by the list of IDs
	string=$1
	shift
	a=( $@ )
	b=""
	for c in $a
	do
		b="$b&$string=$c"
	done
	b=${b:1}
	GET -H "client-id: $client_id" -H "Authorization: Bearer $oauth_token" "https://api.twitch.tv/helix/videos?$b"
	# out : video id, description, url, title (and other stuff)
}

# get_webhook_subs() {}
# I don't need it



while [ "$#" -gt "0" ]
do
	case "$1" in
		"-h" | "--help")
			die
		;;
		"-v" | "--version")
			/bin/echo $version
			exit 1
		;;
		"-s" | "--stream") # get info for 1-100 stream(s)
			if [ "$#" -lt "2" ]
			then
				die
			fi
			shift
			get_streams $@
			exit
		;;
		"-f" | "--followings") # get info for all followings
			i=1
			a="go"
			while [ "$a" != "" ]
			do
				a=( `tail -n +$i $followings | head -n 100 | tr '\n' ' '` )
				[[ "$a" != "" ]] && get_streams $a
				i=$(( $i + 100 ))
			done
			exit
		;;
		"-g" | "--game") # get info for 1-100 game(s)
			if [ "$#" -lt "2" ]
			then
				die
			fi
			shift
			get_games $@
			exit
		;;
		"-vi" | "--video")
			if [ "$#" -lt "2" ]
			then
				die
			fi
			shift
			get_videos "id" $@
			exit
		;;
		"-c" | "--channel")
			if [ ! "$#" = "2" ]
			then
				die
			fi
			shift
			id=`get_users $1 | jq -r ".data" | jq -r ".[]" | jq -r ".id"`
			
			get_videos "user_id" $id
			exit
		;;
		"-w" | "--watch")
			if [ "$#" -lt "3" ]
			then
				die
			fi
			channel=$2
			shift 2
			cmd="$@ https://twitch.tv/$channel"
			echo "$cmd"
			bash -c "$cmd"
			exit
		;;
		#GET -H "client-id: $client_id" -H "Authorization: Bearer $oauth_token" "https://api.twitch.tv/helix/channels?broadcaster_id=116990597"
		*)
			echo "$0 - ERROR : wrong argument : $1 (not stopping process)" 1>&2
			shift
		;;
	esac
done

