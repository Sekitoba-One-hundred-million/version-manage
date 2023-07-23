## !/bin/bash

. ./function.sh
OLDIFS=$IFS

init
version_line=`cat CHANGELOG.md| grep -m1 '##'`
version=v${version_line: -3:3}

IFS=$'\n'

# それぞれの実行とダウンロードのpickleを取得
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

# pickle作成に必要なファイルの算出
./pickle_search.sh

IFS=$'\n'

for data in `cat $data_dir/$pickle_info`; do
    IFS=$OLDIFS
    data_array=($data)
    pickle=${data_array[0]}
    
    if [ -f $sekitoba_data/$pickle ]; then
        cp $sekitoba_data/$pickle $sekitoba_data/$version/$pickle
    fi
done

finish

echo "${version} finish"
