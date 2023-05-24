## !/bin/bash

. ./function.sh

init
version_line=`cat CHANGELOG.md| grep -m1 '##'`
version=${version_line: -3:3}

OLDIFS=$IFS
IFS=$'\n'

for line in `cat $repository_txt`; do
    IFS=$OLDIFS
    line_array=($line)
    repository=${line_array[0]}
    
    if [ ! ${#line_array[*]} -eq 1 ]; then
        i=0
        command=""
        for l in "${line_array[@]}"; do
            if [ $i -eq 0 ]; then
                let i++
                continue
            fi

            command="${command} ${l}"
            let i++
        done
        
        git_clone $repository
        cd $repository
        $command > ../$data_dir/$repository.txt
        cd ..

        while read data; do            
            if [[ $data =~ "download" ]]; then
                data=($data)
                echo ${data[0]} >> $pickle_txt
            fi
        done < $data_dir/$repository.txt
    fi
    
    commit_hash=`git_hash_get $repository`
    echo $repository $commit_hash >> ${data_dir}/git-commit.txt
    IFS=$'\n'
done

IFS=$OLDIFS
pickle_multi_delete
pickle_search $sekitoba_use_data

load_pickle=''

while read pickle_data; do
    data_array=($pickle_data)
    python_file=${data_array[1]}
    
    if [[ ! $python_file =~ $sekitoba_use_data ]]; then
        continue
    fi
    
    load_pickle="$load_pickle `load_pickle_get $python_file`"
done < $data_dir/$pickle_info

load_pickle=($load_pickle)
for pickle_data in "${load_pickle[@]}"; do
    echo $pickle_data >> $pickle_txt
done

pickle_multi_delete
pickle_search $sekitoba_data_collect

for pickle in `cat $pickle_txt`; do
    grep_result=`cat $data_dir/$pickle_info | grep $pickle`

    if [ ! $? -eq 0 ]; then
        echo "${pickle} None" >> $data_dir/$pickle_info
    fi
done

while read data; do
    data_array=($data)
    pickle=${data_array[0]}
    if [ -f $sekitoba_data/$pickle ]; then
        cp $sekitoba_data/$pickle $sekitoba_data/$version/$pickle
    fi
done < $data_dir/$pickle_info

finish
