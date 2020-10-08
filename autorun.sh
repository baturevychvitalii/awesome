function run()
{
	if ! pgrep -f $1; then
		echo "running $1";
		$@&
	fi
}

function kill_it()
{
	if pgrep -f $1; then
		echo "killin' $1";
		pkill $1;

		seconds=0;
		while pgrep -f $1 && [ $seconds -lt 10 ]; do
			echo "waiting to kill $1";
			seconds=$((seconds + 3));
			sleep 3s;
		done

		if pgrep -f $1; then
			return 1;
		fi
	fi

	return 0;
}


#sleep 1 && run xxkb
run keepassxc
run xterm
run firefox
run telegram-desktop
run teams
kill_it redshift && sleep 3s && run redshift
#run /usr/lib/xscreensaver/glmatrix -root -no-rotate

