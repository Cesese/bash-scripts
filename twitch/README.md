# twitch followings script
I'm lazy so let's do it quickly :
1. download this folder
2. make sure the shell scripts (*.sh) are executable. If not, run `chmod +x *.sh`
3. run ./create\_credentials.sh (from X11 because we need to open a link in your browser) OR
3. manually add a client id and oauth token in ./.credentials.txt ( https://dev.twitch.tv/docs/authentication/getting-tokens-oauth )
4. export your twitch following list to ./twitch\_following.txt (I used this https://twitch-tools.rootonline.de/followinglist_viewer.php , exported to csv, and from libreoffice calc I copy/pasted the list into gedit)
5. now it's installed. You just need to run ./whos-online.sh 

To add categories : read the ./whos-online.sh file

You can also use the /twitch\_api.sh independently, and even add things yourself if you need them.
But don't PR, this is a small personal repo.
Feel free to fork if you want to share your own version.

PS: I'm using /usr/bin/zsh on ubuntu 18 LTS. If your zsh is elsewhere, edit the files to match it. If you don't have zsh, feel free to change it to whatever shell you use but beware that some things might be broken, like `[[ "$var" = "x" ]] && echo test` (also if you aren't using the same zsh as me idk if things might be broken)

GLHF
