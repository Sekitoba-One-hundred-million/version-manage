## !/bin/bash

. ./function.sh
OLDIFS=$IFS

rm data/pickle_info.txt
pickle_search $sekitoba_use_data
pickle_search $sekitoba_data_collect
pickle_multi_delete

uniq_create ${pickle_txt}
cp ${pickle_txt} ${pickle_txt}.instance

IFS=$'\n'
for data in `cat ${data_dir}/${pickle_info}`; do
    IFS=$OLDIFS
    data_array=($data)
    pickle=${data_array[0]}
    file_name=${data_array[1]}
    
    if [ ${file_name} == "None" ]; then
        continue
    fi

    for grep_data in `cat ${file_name} | grep -e pickle_load -e data_get`; do
        grep_sed_data=`echo ${grep_data} | sed 's/\"/ /g'`
        array=(${grep_sed_data})

        for str_data in "${array[@]}"; do
            if [[ ! ${str_data} =~ "pickle_load" && ${str_data} =~ ".pickle" ]]; then
                grep -q ${str_data} ${data_dir}/${pickle_info}

                # not found
                if [ $? -eq 1 ]; then
                    #echo ${str_data}
                    echo ${str_data} >> ${pickle_txt}.instance 
                fi
            fi
        done
    done
done

uniq_create ${pickle_txt}.instance

pickle_count=`wc -l < ${pickle_txt} | sed 's/ //g'`
pickle_instance_count=`wc -l < ${pickle_txt}.instance | sed 's/ //g'`

if [ ! ${pickle_count} = ${pickle_instance_count} ]; then
    cp ${pickle_txt}.instance ${pickle_txt}
    rm ${pickle_txt}.instance
    pickle_search $sekitoba_use_data
    pickle_search $sekitoba_data_collect
    pickle_multi_delete
fi
