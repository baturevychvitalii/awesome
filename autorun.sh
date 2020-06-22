function run()
{
	if ! pgrep -f $1; then
		$@&
	fi
}


sleep 1 && run xxkb
run keepassxc
run xterm
run firefox
run telegram-desktop
run redshift

