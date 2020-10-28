#!/usr/bin/zsh

version="1.0"

debug=false

gamesfile="twitch_games.txt"
gamessed=`cat $gamesfile | tr '\n' ' '`
stime="5m"
twitch_api="./twitch_api.sh"
knownError=false
error=""
new_games=false
separation="\n---\n"
cmdClear="clear"

lists=( )
channels=( )
gamegrep=( )

lists=( $lists "Online" )
channels=( $channels "--followings" ) # Online
gamegrep=( $gamegrep "" ) # whitelist for Online
# example of adding a category:
#lists=( $lists "Fedicuties" )
#channels=( "--stream cesese" ) # Fedicuties
#gamegrep=( $gamegrep "Fate\/Grand Order|The Lion King" ) # whitelist for Fedicuties
# note : the game must already be added in twitch_games.txt (I think I could make it look for an unknown game, but I'm lazy, and anyway if you want to whitelist a game it should be a streamed game so it's not like it's hard to get it)

# you can also make it smaller :
#lists=( "Online" "Fedicuties" )
#channels=( "--followings" "--stream cesese" )
#gamegrep=( "" "Fate\/Grand Order|The Lion King" )

# convert games from name to id
for g in `seq 1 1 ${#gamegrep[@]}`
do
	s="${gamegrep[$g]}"
	if [ ! "$s" = "" ]
	then
		s=`cat $gamesfile | egrep "$s" | cut -d'/' -f2 | tr '\n' '|'`
		gamegrep[$g]="${s:0:-1}"
	fi
done

[[ "$debug" = "true" ]] && echo "[Debug on]"
[[ "$debug" = "true" ]] && cmdClear="/bin/echo '<clear>\n'"

bash -c "$cmdClear"
while [ 1 ]
do
	/bin/echo "Checking online channels..."
	text=""
	for l in `seq 1 1 ${#lists[@]}`
	do
		[[ "$debug" = "true" ]] && echo "$l - ${lists[$l]}"
		
		subtext[$l]=""
		error=""
		
		json=`bash -c "$twitch_api ${channels[$l]}"`
		json=`echo $json | tr -d '\n' | tr -d '\t'`
		echo "$json" | egrep -q "Can't connect to api.twitch.tv:443" && knownError=true && error="$error\nCan't connect"
		echo "$json" | egrep -q "\{\"data\":\[\],\"pagination\":\{\}\}" && knownError=true && error="$error\nNo one online"
		error="${error:2}"
		
		ochannels=( `echo $json | jq -r ".data" | jq -r ".[]" | jq -r ".user_name" | tr '\n' ' '` )
		octitles=`echo $json | jq -r ".data" | jq -r ".[]" | jq -r ".title"`
		ocgameids=( `echo $json | jq -r ".data" | jq -r ".[]" | jq -r ".game_id" | sed -e 's/^\s*$/1234emptygame1234/g' | tr '\n' ' '` ) # https://stackoverflow.com/questions/16414410/delete-empty-lines-using-sed#16414489
		
		# if there's a whitelist
		if [ ! "${gamegrep[$l]}" = "" ]
		then
			whitelist=""
			for i in `seq 1 1 ${#ochannels[@]}`
			do
				if [ ! "`echo ${ocgameids[$i]} | egrep -w "${gamegrep[$l]}"`" = "" ]
				then
					whitelist="$whitelist,$i"
					[[ "$debug" = "true" ]] && echo "${ochannels[$i]} added to whitelist (game : ${ocgameids[$i]} = `echo ${ocgameids[$i]} | bash -c "sed $gamessed"`)"
				fi
			done
			[[ "$debug" = "true" ]] && echo "whitelist = $whitelist"
			if [ "$whitelist" = "" ]
			then
				ochannels=( "" )
				octitles=""
				ocgameids=( "" )
				knownError=true
				error="$error\nNo one online"
			else
				whitelist="${whitelist:1}" # ,1,2,3,... -> 1,2,3,...
				ochannels=( `echo ${ochannels[@]} | cut -d' ' -f"$whitelist"` )
				octitles=`echo $octitles | cut -d$'\n' -f"$whitelist"` # apparently the newline character is not '\n' but $'\n' ?
				ocgameids=( `echo ${ocgameids[@]} | cut -d' ' -f"$whitelist"` )
			fi
		fi
		
		# if an unknown error occurred 
		if [ "$ochannels" = "" ] && [ "$knownError" = false ]
		then
			echo $json;echo $ochannels ; echo $octitles; echo "ERROR occurred"; exit 1
		fi
		
		# looking up unknown games and adding them to twitch_games.txt
		arggamejson=`echo $ocgameids | tr ' ' '\n' | uniq -u | tr '\n' '|'`
		alreadythere=`cat $gamesfile | egrep -wo "$arggamejson" | tr '\n' '|'`
		arggamejson=`echo $arggamejson | tr '|' '\n' | egrep -vw "$alreadythere" | tr '\n' ' '`
		[[ ! "$arggamejson" = "" ]] && new_games=true || new_games=false
		if [ "$new_games" = true ]
		then
			[[ "$debug" = "true" ]] && echo "Adding new games to library:"
			gamejson=`bash -c "$twitch_api --game $arggamejson" | tr -d '\t'`
			gametitles=( `echo $gamejson | jq -r ".data" | jq -r ".[]" | jq -r ".name" | tr ' ' '_' | sed -e 's/\\//\\\\\//g' | sed -e 's/"/\\\"/g'` ) # sed / -> \/ for use later in sed (2 escapes : one for sed and one for ``. So \ is \\\ and / is \\/)
			gameids=( `echo $gamejson | jq -r ".data" | jq -r ".[]" | jq -r ".id"` )
			sedscripts=""
			for i in `seq 1 1 ${#gameids}` # sed -e "s/11557/The Legend of Zelda: Ocarina of Time/g"
			do
				[[ "$debug" = "true" ]] && /bin/echo -e "${gameids[$i]} - ${gametitles[$i]}" | tr '_' ' '
				sedscripts="$sedscripts\n-e \"s/${gameids[$i]}/`echo ${gametitles[$i]} | tr '_' ' '`/g\""
			done
			sedscripts="${sedscripts:2}"
			/bin/echo -e "$sedscripts" >> $gamesfile
			gamessed=`cat $gamesfile | tr '\n' ' '`
		fi
		
		for i in `seq 1 1 ${#ochannels[@]}`;
		do
			stitle=`echo $octitles | tail -n +$i | head -n 1`
			subtext[$l]="${subtext[$l]}\n${ochannels[$i]} is playing '$ocgameids[$i]' : $stitle"
		done
		
		if [ "$knownError" = true ]
		then
			subtext[$l]="${subtext[$l]}\n$error"
			knownError=false
		fi
		
		subtext[$l]=`echo ${subtext[$l]} | bash -c "sed $gamessed" | sort`
		text="$text$separation${lists[$l]} channels\n${subtext[$l]}" #\n\nNext update in $stime"
	done
	
	text="${text:${#separation[@]}}"
	/bin/echo -e "`bash -c "$cmdClear"`$text"
	sleep $stime #| pv -t # uncomment if you want to see the timer
done

# how to get oauth token : (https://dev.twitch.tv/docs/authentication/getting-tokens-oauth)
# access this link 'https://id.twitch.tv/oauth2/authorize?response_type=token&client_id=<clientid>&redirect_uri=http://localhost&scope=viewing_activity_read' (replace <clientid> by your client id)
# it will redirect you to http://localhost#access_token=<an access token>
