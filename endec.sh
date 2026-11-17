#!/bin/bash

#Endec (v1.0)
#Copyright (C) 2021 Theodoros Arvanitis (Author)
#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
#This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/
#Email: theodorosarv@gmail.com

nameinput() { #prompt user to type file/folder name for encrypting & zipping / unzipping & decrypting

	printf "\nEnter file or folder name:\n"
	IFS= read -r response

}

promptdelete() { #prompt user to select whether to permanent delete initial encrypted '*.tar.gz.gpg' file & its decrypted+zipped '*.tar.gz' file after successfully unzipping & decrypting it, or not

	i=1

	printf "\nOriginal file/folder & its zipped '.*tar.gz' file can be deleted.\nDelete them, permanently: (y/n) ?";

	IFS= read -r response3

		if [[ "$response3" =~ [yY] ]]
		then
			rm -r -f --interactive=never "$response" && rm -r -f --interactive=never "$response2".tar.gz && rm -r -f --interactive=never "${response%.gpg}"
			rm -rf ~/.endecSTDERR.txt
		elif [[ "$response3" =~ [nN] ]]
		then
			:
		elif [[ "$response3" != [yYnN] ]]
		then
			while [[ $i -le 2 ]]
			do
				printf ""$response3" is invalid.\nPlease enter y/Y for Yes, or n/N for No\n";
				touch -f ~/.endecSTDERR.txt;
				IFS= read -r response3;
					if [[ "$response3" =~ [nN] ]]
					then
						rm -rf ~/.endecSTDERR.txt &> /dev/null;
						break
					elif [[ "$response3" =~ [yY] ]]
					then
						rm -r -f --interactive=never "$response" && rm -r -f --interactive=never "$response2".tar.gz && rm -r -f --interactive=never "${response%.gpg}"
						rm -rf ~/.endecSTDERR.txt &> /dev/null;
						break
					fi
					((i++))
			done
			if ls -la ~/ | grep -i "endecSTDERR.txt" &> /dev/null
			then
					printf ""$response3" is invalid.\n";
					printf "Failed Attempt! No files were deleted!\n";
					rm -rf ~/.endecSTDERR.txt &> /dev/null;
				else
					return 0

				fi
		fi

}

unzel() { #unzip decrypted 'tar.gz' file & prompt user to select whether to permanent delete initial encrypted '*.tar.gz.gpg' file & its decrypted+zipped '*.tar.gz' file after successfully unzipping & decrypting it, or not

	tar -xzvf "${response%.gpg}" -C ./ && promptdelete

}

decreload() { #clear the SHELL from any pre-entered passwds used w/ 'gpg' to decrypt files & passing any STDERR to a dummy, hidden, temp file for read use
	
	gpgconf --reload gpg-agent; 
	gpg -o "${response%.gpg}" -d "$response" 1> /dev/null 2> ~/.endecSTDERR.txt && gpgconf --reload gpg-agent

}

nxpassloop() { #activated when user enters an incorrect passwd for decrypting the '*.tar.gz.gpg' file by informing user for their incorrect passwd input & giving them up to 3 tries for passwd re-entering

	i=1

	printf "\nIncorrect Password! Try again...\n";
	sleep 1;
	if ! decreload;
	then	
		while [[ $i -lt 2 ]]
		do
			printf "\nIncorrect Password! Try again...\n\a";
			sleep 1;
			if ! decreload
			then
				break
			fi
				((i++))
		done	
		if cat ~/.endecSTDERR.txt 2> /dev/null | grep -i "decryption failed" &> /dev/null;
		then
			printf "\nIncorrect Password!\nFailed attempt... Halt!\n\a" 
		else
			unzel 2> /dev/null
		fi
	else
		unzel 2> /dev/null
	fi

}

newnamezipcrypt() { #prompt user to enter a name for the newly created zipped+encrypted file & zip+encrypt the user-selected file/folder

	printf "Enter new name of zipped file '*.tar.gz'\n";
	IFS= read -r response2;
	tar -czvf "$response2".tar.gz "$response" 2> /dev/null;
	gpg --symmetric --cipher-algo AES256 "$response2".tar.gz;
	gpgconf --reload gpg-agent;

}

uncrypt() { #final function unzipping & decrypting the user-selected '*.tar.gz.gpg' file by combining all related previous functions

	i=1

	nameinput;
	if [[ -e "./$response" ]] && [[ "$response" == *.tar.gz.gpg ]]
	then
		decreload;
		unzel 2> /dev/null;
		if cat ~/.endecSTDERR.txt 2> /dev/null | grep -i "decryption failed" &> /dev/null;
		then
			nxpassloop
		else
			:
		fi
	else
		while [[ $i -lt 3 ]]
		do
			printf "\nFile or Folder does NOT exist, or it's a file w/o a '*.tar.gz.gpg' extension!\n";
			sleep 1;
			touch -f ~/.endecSTDERR.txt;
			nameinput;
			if [[ -e "./$response" ]] && [[ "$response" == *.tar.gz.gpg ]]
			then
				rm -rf ~/.endecSTDERR.txt &> /dev/null;
				decreload;
				unzel 2> /dev/null;
				break
				fi
				((i++))
			done
			if cat ~/.endecSTDERR.txt 2> /dev/null | grep -i "decryption failed" &> /dev/null;
			then
				nxpassloop
			else
				if ls -la ~/ | grep -i "endecSTDERR.txt" &> /dev/null
				then
					printf "\nFile or Folder does NOT exist, or it's a file w/o a '*.tar.gz.gpg' extension\n";
					printf "\nFailed Attempt! Halt!\n";
					rm -rf ~/.endecSTDERR.txt &> /dev/null;
				else
					:
				fi
			fi
		fi

}

zipcrypt() { #final function zipping & encrypting the user-selected file/folder by combining all related previous functions

	i=1

	nameinput;
	if [[ -e "./$response" ]] && [[ "$response" != *.tar.gz.gpg ]]
	then
		newnamezipcrypt;
		promptdelete;
	else
		while [[ $i -lt 3 ]]
		do
			printf "\nFile or Folder does NOT exist or it's a file w/ a '*.tar.gz.gpg' extension\n";
			sleep 1;
			touch -f ~/.endecSTDERR.txt;
			nameinput;
			if [[ -e "./$response" ]] && [[ "$response" != *.tar.gz.gpg ]]
			then
				newnamezipcrypt;
				rm -rf ~/.endecSTDERR.txt &> /dev/null;
				promptdelete;
				break
			fi
			((i++))
			done

			if ls -la ~/ | grep -i "endecSTDERR.txt" &> /dev/null
			then
				printf "\nFile or Folder does NOT exist or it's a file w/ a '*.tar.gz.gpg' extension\n";
				printf "\nFailed Attempt! Halt!\n";
				rm -rf ~/.endecSTDERR.txt &> /dev/null;
			else
				return 0
			fi
	fi

}

	if find /usr/local/bin/ -name "endec" &>/dev/null
	then	
		case "$1" in
			"-en")
			zipcrypt && rm -rf ~/.endecSTDERR.txt &> /dev/null
			;;
			"-de")
			uncrypt && rm -rf ~/.endecSTDERR.txt &> /dev/null
			;;
			"--uninstall")
			sudo rm -rf /usr/local/bin/endec
			;;
			"--help"|"-h")
			printf "Usage:\nendec [OPTIONS]...\n\nZip a file/folder & Ecrypt it.\n\nand/or\n\nDecrypt a file/folder & Unzip it.\n \nNOTE: Run 'endec' within the Path of file/folder in question.\n \nOptions:\n\n  -en \t \t Zip & Encrypt\n \n  -de \t \t Decrypt & Unzip\n \n  --uninstall \t Uninstall (Delete 'endec' from /usr/local/bin/, permanently)\n \n  -h, --help\t Show this message\n\n\n"
			;;
			*)
			printf "\noptions: -en, -de, or -h, --help for info\n\n" 
			;;
		esac
		
	else #if it does NOT, inform the user about proper steps for installation
		printf "\nRun 'makefile' to install.\n\nType:\n\nmake\n\nand hit Enter.\n(you must be within the same dir as 'makefile' & 'endec.sh'.)\n\nInfo:\n\nmakefile \tInstalls 'gpg' & 'tar', makes endec.sh executable,\n \t \tmoves it /usr/local/bin/ to run it as command\n\n"
	fi
