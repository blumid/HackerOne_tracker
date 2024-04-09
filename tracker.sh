#!/bin/bash

wget -O HackerOne.json -A json https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/master/data/hackerone_data.json

#after a while we must use bellow option:
#wget -i download-list.txt

main() {

	echo "!!!        at the beginnig of the script           !!!"

	result=($(jq -c '.[] as $pa | $pa.targets | {"name": $pa.handle ,"in" : [.in_scope[] | select(.asset_type == "URL")["asset_identifier"] ] , "IP" : [.in_scope[] | select(.asset_type == "CIDR")["asset_identifier"] ] , "out" : [.out_of_scope[] | select(.asset_type == "URL")["asset_identifier"] ] }' HackerOne.json | jq -c '. | select(.in[0] != null)'))

	for item in ${result[@]}; do
		(
			read -r -d '' new_in new_IP new_out name <<<"$(fetch_new_scopes $item)"
			if [[ ! -f scopes/$name/$name.in.txt ]]; then
				echo -e "$name\n"
				echo $name >>/tmp/targets.txt

				if [[ -n $name ]]; then
					mkdir -p scopes/$name
					if [[ -n $new_IP ]]; then
						echo $new_IP | tr -d '[]' | tr ',' '\n' | sort >scopes/$name/$name.CIDR.in.txt
					fi

					echo $new_in | tr -d '[]' | tr ',' '\n' | sort >scopes/$name/$name.in.txt
					echo $new_out | tr -d '[]' | tr ',' '\n' | sort >scopes/$name/$name.out.txt
				fi
				if [[ -s "scopes/$name/$name.in.txt" ]]; then
					cat "scopes/$name/$name.in.txt" | grep "*" |
						while read line; do
							recon_subdomains ${line#*.} $name
						done

				fi
			else
				exit
			fi
		) &

	done
	wait
	if [[ -s /tmp/targets.txt ]]; then
		sed -i '1s/^/HackerOne =>\n------------\n\n/' /tmp/targets.txt
		notify -silent -data /tmp/targets.txt -bulk -id block
		rm -rf /tmp/targets.txt
	fi

}

fetch_new_scopes() {

	new_in=$(echo $1 | jq -c '.in' | tr -d "\"")
	new_IP=$(echo $1 | jq -c '.IP' | tr -d "\"")
	new_out=$(echo $1 | jq -c '.out' | tr -d "\"")
	name=$(echo $1 | jq -c '.name' | tr -d "\"")

	#it doesn't matter that are there old files or no:
	#we should return new_in_scopes and new_out_scopes using echo command

	#echo `echo $new_in | anew -q old_in.txt`
	#echo `echo $new_out | anew -q old_out.txt`

	echo $new_in
	echo $new_IP
	echo $new_out
	echo $name
}

recon_subdomains() {

	#perform subfinder
	sub1=$(subfinder -d $1 -t 100 -silent)

	#perform sublist3r
	#sub2=$(sublist3r.py -d $1 -t 100 | tail -n +10)

	result_file="scopes/$2/$2.in.txt"
	printf "%s\n" "${sub1[@]}" | anew -q $result_file
	#printf "%s\n" "${sub2[@]}" | anew -q $result_file
	#echo -e $sub2 | anew -q $result_file

	#cat sub1 output2.txt | sort -u >output.txt

}

#check whcich one is up & what's their technology

#show in terminal

#save result in db

main "$@"
exit
