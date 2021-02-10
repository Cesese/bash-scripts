#!zsh

cfg="$HOME/.config/bunniscripts"
[[ ! -d "$cfg" ]] && mkdir "$cfg"

version="0.1"

usage="USAGE\n\t$0 [-h/-v] [-n/-vi/-q/-o <arg>]\nARGUMENTS"
usage="$usage\n\t[-n/--number]\n\t\tNumber of videos to merge"
usage="$usage\n\t[-vi/--videos]\n\t\tIDs of videos to merge, separated by space"
usage="$usage\n\t[-q/--qualities]\n\t\tQualities of videos, separated by space"
usage="$usage\n\t[-o/--output]\n\t\tOutput file without extension"
#usage="$usage\n\t[-/--]\n\t\tDescription"
usage="$usage\nTO BE DONE"
usage="$usage\n\t- adding other services than twitch"
usage="$usage\n\t- testing with other things than 1 video 2 audio"
#usage="$usage\n\t"

n=0
v=( "" )
q=( "" )
t=( "" )
l=( "" )
o="out.ts"

die()
{
	/bin/echo -e $usage 1>&2
	exit 1
}

if [ "$#" -eq "0" ]
then
	die	
fi

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
		"-n" | "--number")
			if [ "$#" -lt "2" ]
			then
				die
			fi
			n=$2
			shift 2
		;;
		"-vi" | "--videos")
			if [ "$#" -lt "2" ]
			then
				die
			fi
			v=( `echo $2` )
			shift 2
		;;
		"-q" | "--qualities")
			if [ "$#" -lt "2" ]
			then
				die
			fi
			q=( `echo $2` )
			shift 2
		;;
		"-o" | "--output")
			if [ "$#" -lt "2" ]
			then
				die
			fi
			o="$2.ts"
			shift 2
		;;
		*)
			echo "$0 - ERROR : wrong argument : $1" 1>&2
			exit 1
		;;
	esac
done

ta="twitch_api.sh"

for i in `seq 1 1 ${#v[@]}`
do
	vi="${v[i]}"
	tvi="https://www.twitch.tv/videos/$vi"
	qi="${q[i]}"
	#time
	json=`bash -c "$ta -vi $vi"`
	ti=`echo $json | jq -r ".data" | jq -r ".[]" | jq -r ".created_at"`
	h=`echo $ti | cut -d'T' -f2 | cut -d':' -f1`
	m=`echo $ti | cut -d':' -f2`
	s=`echo $ti | cut -d':' -f3 | cut -d'Z' -f1`
	ti=$(($h * 3600 + $m * 60 + $s))
	t[$i]="$ti"
	#link
	li=`youtube-dl -f $qi -g $tvi`
	l[$i]="$li"
	echo "$vi - $qi - $ti - $li"
done

tmin="1"
tmax="1"

for i in `seq 1 1 ${#t[@]}`
do
	[[ "${t[$i]}" -lt "${t[$tmin]}" ]] && tmin="$i"
	[[ "${t[$i]}" -gt "${t[$tmax]}" ]] && tmax="$i"
done

cmd="ffmpeg"
suffix="-c copy -shortest"

for i in `seq 1 1 ${#v[@]}`
do
	j="$(($i - 1))"
	ti="${t[$i]}"
	li="${l[$i]}"
	qi="${q[i]}"
	ss="$(($ti - ${t[$tmin]}))"
	cmd="$cmd -ss $ss -i $li"
	[[ true ]] && suffix="$suffix -map ${j}:a"
	[[ ! "$qi" = "bestaudio" ]] && suffix="$suffix -map ${j}:v"
done

echo "$cmd $suffix $o"
zsh -c "$cmd $suffix $o"
