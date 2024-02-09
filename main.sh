## !/bin/bash
state='test'
core=3

while getopts s-: opt; do
    optarg="${!OPTIND}"
    [[ "${opt}" = - ]] && opt="-${OPTARG}"
    
    case ${opt} in
        s|-state)
            state="${optarg}"
            shift
            ;;
        c|-core)
            core="${optarg}"
            shift
            ;;
    esac
done

. ./function.sh
OLDIFS=$IFS

init

IFS=$'\n'

# それぞれの実行とダウンロードのpickleを取得
for line in `cat "${repository_txt}"`; do
    IFS=$OLDIFS
    line_array=(${line})
    repository=${line_array[0]}
    
    if [ ! ${#line_array[*]} -eq 1 ]; then
        i=0
        command=''
        for l in "${line_array[@]}"; do
            if [ $i -eq 0 ]; then
                let i++
                continue
            fi

            command="${command} ${l}"
            let i++
        done

        command+=" --core ${core}"
        echo "start ${repository}"
        git_clone "${repository}"
        cd "${repository}"
        ${command} > "../${data_dir}/${repository}.txt"
        cd ..

        while read data; do
            if [[ "${data}" =~ 'download' ]]; then
                data=(${data})
                echo "${data[0]}" >> "${pickle_txt}"
            fi
        done < "${data_dir}/${repository}.txt"
    fi
    
    commit_hash=`git_hash_get $repository`
    echo "${repository} ${commit_hash}" >> "${data_dir}/git-commit.txt"
    IFS=$'\n'
done

# pickle作成に必要なファイルの算出
./pickle_search.sh

for prod_data in `cat "${prod_data_txt}"`; do
    echo "${prod_data} None" >> "${data_dir}/${pickle_info}"
done

IFS=$'\n'
for data in `cat "${data_dir}/${pickle_info}"`; do
    IFS="${OLDIFS}"
    data_array=(${data})
    pickle="${data_array[0]}"
    
    if [ -f "${sekitoba_data}/${pickle}" ]; then
        cp "${sekitoba_data}/${pickle}" "${sekitoba_data}/${version}/${pickle}"
    fi
done

if [ "${state}" == 'prod' ]; then
    cp -r "${sekitoba_data}/${version}"  "${sekitoba_data}/prod"
fi

finish

echo "${version} finish"
