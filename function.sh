## !/bin/bash

data_dir='data'
pickle_txt='pickle.txt'
repository_txt='repository.txt'
model_txt='model.txt'
pickle_info='pickle_info.txt'
sekitoba_use_data='sekitoba_use_data'
sekitoba_data_collect='sekitoba_data_collect'
sekitoba_data="/Volumes/Gilgamesh/sekitoba-data"

version_line=`cat CHANGELOG.md| grep -m1 '##'`
version=v${version_line: -4:4}

function init {
    while read line
    do
        line_array=(${line})
        repository="${line_array[0]}"
        
        if [ -d "${repository}" ]; then
            rm -rf "${repository}"
        fi
    done < "${repository_txt}"

    if [ -d "${data_dir}" ]; then
        rm -rf "${data_dir}"
    fi

    if [ -d "${sekitoba_data}/${version}" ]; then
        rm -rf "${sekitoba_data}/${version}"
    fi

    if [ -f "${pickle_txt}" ]; then
        rm "${pickle_txt}"
    fi

    touch "${pickle_txt}"
    mkdir "${sekitoba_data}/${version}"
    mkdir "${data_dir}"
}

function finish {
    while read line
    do
        line_array=(${line})
        repository="${line_array[0]}"
        
        if [ -d "${repository}" ]; then
            rm -rf "${repository}"
        fi
    done < "${repository_txt}"

    rm "${pickle_txt}"
}

function git_hash_get {
    git_url="git@github.com:Sekitoba-One-hundred-million/$1.git"
    
    if [ ! -d $1 ]; then
        git clone -q "${git_url}"
    fi
    
    cd $1
    hash_value=`git rev-parse HEAD`
    cd ..
    rm -rf $1
    return 1
}

function git_clone {
    git_url="git@github.com:Sekitoba-One-hundred-million/$1.git"
    git clone -q "${git_url}"
}

function pickle_search {
    if [ ! -d $1 ]; then
        git_clone $1
    fi

    if [ ! -f "${data_dir}/${pickle_info}" ]; then
        touch "${data_dir}/${pickle_info}"
    fi

    for pickle in `sort "${pickle_txt}" | uniq`; do
        find_check=0
        pickle_info_grep=`grep "${pickle}" "${data_dir}/${pickle_info}"`

        if [ $? -eq 0 ]; then
            check_pickle=`echo "${pickle_info_grep}" | awk -F ' ' '{ print $1 }'`

            if [ "${pickle}" == "${check_pickle}" ]; then
                continue
            fi
        fi

        for python_file in `ls $1/*.py`; do
            grep_result=`cat "${python_file}" | grep "${pickle}" | grep pickle_upload | grep -v \#`

            if [ $? -eq 0 ]; then
                grep_result=`echo "${grep_result}" | sed "s/\"/ /g" | sed "s/\'/ /g"`
                array=(${grep_result})
                find_check=0
                # grepで見つけたのが完全一致かを確認
                for str_data in "${array[@]}"; do
                    if [ "${pickle}" == "${str_data}" ]; then
                        find_check=1
                        echo "${pickle} ${python_file}" >> "${data_dir}/${pickle_info}"
                        break
                    fi
                done

                if [ "${find_check}" -eq 1 ]; then
                    break
                fi
            fi
        done
    done
}

function load_pickle_get {
    pickle_name_list=''
    python_file=$1
    for line_data in `cat "${python_file}" | grep pickle_load`; do
        line_data=`echo "${line_data}" | sed "s/\"/ /g" | sed "s/\'/ /g"`
        line_array=(${line_data})
        for str_data in "${line_array[@]}"; do
            if [[ ! $str_data =~ "pickle_load" ]] && [[ $str_data =~ ".pickle" ]]; then
                pickle_name_list="${pickle_name_list} ${str_data}"
            fi
        done
    done

    for line_data in `cat "${python_file}" | grep data_get`; do
        line_data=`echo "${line_data}" | sed "s/\"/ /g" | sed "s/\'/ /g" | sed "s/,//g"`
        line_array=(${line_data})
        #echo $line_data
        for str_data in "${line_array[@]}"; do
            if [[ $str_data =~ ".pickle" ]]; then
                pickle_name_list="${pickle_name_list} ${str_data}"
            fi
        done
    done
}

function pickle_multi_delete {
    for pickle in `sort "${pickle_txt}" | uniq`; do
        pickle=`echo "${pickle}" | sed "s/\"//g" | sed "s/\'//g" | sed "s/,//g"`
        grep -q "${pickle}" "${data_dir}/${pickle_info}"

        if [ $? -eq 0 ]; then
            continue
        fi

        echo "${pickle} None" >> "${data_dir}/${pickle_info}"
    done
    
    instance_file="${pickle_txt}.instance"
    cp "${data_dir}/${pickle_info}" "${instance_file}"
    rm "${data_dir}/${pickle_info}"
    sort "${instance_file}" | uniq >> "${data_dir}/${pickle_info}"
    rm "${instance_file}"
}

function uniq_create {
    file_name=$1
    cp "${file_name}" "${file_name}.instance"
    rm "${file_name}"
    sort "${file_name}.instance" | uniq >> "${file_name}"
    rm "${file_name}.instance"
}
