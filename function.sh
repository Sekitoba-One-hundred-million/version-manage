## !/bin/bash

data_dir='data'
pickle_txt='pickle.txt'
repository_txt='repository.txt'
pickle_info='pickle_info.txt'
sekitoba_use_data='sekitoba_use_data'
sekitoba_data_collect='sekitoba_data_collect'
sekitoba_data="/Volumes/Gilgamesh/sekitoba-data"

version_line=`cat CHANGELOG.md| grep -m1 '##'`
version=${version_line: -3:3}

function init {
    while read line
    do
        line_array=($line)
        repository=${line_array[0]}
        
        if [ -d $repository ]; then
            rm -rf $repository
        fi
    done < $repository_txt

    if [ -d $data_dir ]; then
        rm -rf $data_dir
    fi

    if [ -d $sekitoba_data/$version ]; then
        rm -rf $sekitoba_data/$version
    fi

    if [ -f $pickle_txt ]; then
        rm $pickle_txt
    fi

    touch $pickle_txt
    mkdir $sekitoba_data/$version
    mkdir $data_dir
}

function finish {
    while read line
    do
        line_array=($line)
        repository=${line_array[0]}
        
        if [ -d $repository ]; then
            rm -rf $repository
        fi
    done < $repository_txt

    rm $pickle_txt
}

function git_hash_get {
    git_url="git@github.com:Sekitoba-One-hundred-million/$1.git"
    
    if [ ! -d $1 ]; then
        git clone -q $git_url
    fi
    
    cd $1
    hash_value=`git rev-parse HEAD`
    cd ..
    rm -rf $1
    echo $hash_value
    return 1
}

function git_clone {
    git_url="git@github.com:Sekitoba-One-hundred-million/$1.git"
    git clone -q $git_url
}

function pickle_search {
    if [ ! -d $1 ]; then
        git_clone $1
    fi

    if [ ! -f $data_dir/$pickle_info ]; then
        touch $data_dir/$pickle_info
    fi

    for pickle in `cat $pickle_txt`; do
        gr=`cat $data_dir/$pickle_info | grep $pickle`

        if [ $? -eq 0 ]; then
            continue
        fi
        
        for python_file in `ls $1/*.py`; do
            grep_result=`cat ${python_file} | grep ${pickle} | grep pickle_upload`
            #echo $python_file $pickle
            if [ $? -eq 0 ]; then
                grep_result=`echo $grep_result | sed 's/\"/ /g'`
                str_array=($grep_result)
                for str_data in "${str_array[@]}"; do
                    if [[ $pickle == $str_data ]]; then
                        echo $pickle $python_file >> $data_dir/$pickle_info
                    fi
                done
            fi
        done
    done
}

function load_pickle_get {
    pickle_name_list=''
    python_file=$1
    for line_data in `cat $python_file | grep pickle_load`; do
        line_data=`echo $line_data | sed 's/\"/ /g'`
        line_array=($line_data)
        #echo $line_data
        for str_data in "${line_array[@]}"; do
            if [[ ! $str_data =~ "pickle_load" ]] && [[ $str_data =~ ".pickle" ]]; then
                pickle_name_list="${pickle_name_list} $str_data"
                #echo $str_data
            fi
        done
    done

    for line_data in `cat $python_file | grep data_get`; do
        line_data=`echo $line_data | sed 's/\"/ /g'`
        line_array=($line_data)
        #echo $line_data
        for str_data in "${line_array[@]}"; do
            if [[ $str_data =~ ".pickle" ]]; then
                pickle_name_list="${pickle_name_list} $str_data"
            fi
        done
    done
}

function pickle_multi_delete {
    instance_file=$pickle_txt.instance
    cp $pickle_txt $instance_file
    rm $pickle_txt
    touch $pickle_txt

    for pickle in `cat $instance_file`; do
        grep_result=`cat $pickle_txt | grep $pickle`
        
        if [ ! $? -eq 0 ]; then
            echo $pickle >> $pickle_txt
        fi
    done

    rm $instance_file
}

