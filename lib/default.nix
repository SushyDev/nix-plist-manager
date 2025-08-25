{ lib }:
let

	/**
	 * Executes a command as a specified user using `launchctl` and `sudo`.
	 *
	 * @param user The username to run the command as.
	 * @param cmd The command to execute as the specified user.
	 * @return A string representing the command to be executed.
	 */
	runAsUser = user: cmd: "launchctl asuser \"$(id -u -- ${user})\" sudo --user=${user} -- ${cmd}";
in 
{
	types = import ./types.nix { inherit lib; };
	inherit runAsUser;
}
