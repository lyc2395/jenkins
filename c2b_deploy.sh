#! /bin/bash
DATE=`date +%F_%H-%M-%S`


if [ $# -lt 7 ];then
        echo -e "\n-------------------------------------------------\n\n\t-- Usage:  ${0} Job_name project_name http_num\n\n -$'1' Jenkins项目名称\n -$'2' jar包简称(不包括版本号及时间戳)\n -$'3' spark Class\n -$'4' driver-memory\n -$'5' executor memory\n -$'6' executor core\n\n-------------------------------------------------" && exit
fi

#===============
#  nfs 挂载
#===============
nfs_ip='10.133.115.244'  # 可能需要修改
nfs_dir='/app/public'  # 可能需要修改
jar_data="/srv" # 可能需要修改
jar_bak_path='/app/jar_bak' # 可能需要修改
	nfs_judge=`rpm -qa | grep nfs-utils &>/dev/null && rpm -qa | grep rpcbind &>/dev/null && echo 1 || echo 0`
	if [ ${nfs_judge} -eq 0 ];then yum install -y nfs-utils rpcbind || exit;fi
	mount -t nfs ${nfs_ip}:${nfs_dir} ${jar_data}


#======================================
# 定义最新jar包存储目录及jar包名称获取
#======================================
job_name="${1}"
# 获取项目名称
jar_name="${2}"
Class="${3}"
driver="${4}"
memory="${5}"
core="${6}"

jar_path="${jar_data}/${job_name}"
jar_all_name=`cd  ${jar_path};ls -1t *.jar | head -n1`
jar_version=`echo ${jar_all_name} | awk -F '.jar' '{print $1}'`
jar_job_dir='/app/jar-pkg-last'

[[ -d ${jar_data} ]] || mkdir -p ${jar_data}
[[ -d ${jar_bak_path} ]] || mkdir -p ${jar_bak_path}
[[ -d ${jar_job_dir} ]] || mkdir -p ${jar_job_dir}
[[ -f ${jar_path}/${jar_all_name} ]] || echo -e "\n\n*****\t${jar_all_name}:   No such file or directory\t******\n\n"
[[ -f ${jar_path}/${jar_all_name} ]]  || exit

#再次声明旧文件备份目录
backup_dir=${jar_bak_path}
# 最新的备份文件保留几份
files=10
#   备份
#=========
Clean_backups () {
	cd ${backup_dir}; Total=$(ls | wc -l) ;Num=$((${Total} - ${files}))
	echo -e "\n\n====::))\t当前${backup_dir}下共计${Total}个备份文件\t((::====\n\n"
	if [ ${Num} -gt 0 ];then
		echo -e "\n\n******\t开始清理备份文件\t******\n\n"
		for file in $(cd ${backup_dir}; ls -1t | tail -n ${Num});do echo -e "\n---\t${file} is deleted\t---\n";rm $file;done
	else 
		echo -e "\n\n----\t${backup_dir}下备份文件数量小于${files}个,将不再进行清理...\t----\n\n"
	fi
}

#===================
#  jar包备份
#===================
jar_backup () {
	judge=`ls ${jar_job_dir}/${jar_name}*.jar | wc -l` 
	if [ ${judge} -gt 0 ];then
		old_jar_name=`cd ${jar_job_dir}; ls ${jar_name}*.jar | awk -F '.jar' '{print $1}'`
	cd ${jar_job_dir}; tar zcf ${old_jar_name}.bak${DATE}.tgz   ./${old_jar_name}*
	if [ $? -eq 0 ]
	then 
		cd ${jar_job_dir}; mv ${old_jar_name}.bak${DATE}.tgz ${jar_bak_path};
		cd ${jar_job_dir}; rm -rf ./${old_jar_name}* && echo -e "\n\n---------->\t${DATE}\t<-------\n==::))\t${old_jar_name}备份成功...\t((::==";
	else 
		echo -e "\n\n\n******\t ${old_jar_name} is backup Failed.....\t****\n\n"
	fi
else
	echo -e "\n\n\n********\t\t${jar_name}相关版本jar包不存在,不再执行数据备份....\t\t*********\n\n\n";
fi
}
#================
# jar包分发
#================

jar_submit () {	
ansible_user='c2b'	
	cp -a ${jar_path}/${jar_all_name} ${jar_job_dir} && echo -e "\n\t最新jar包为:$(ls ${jar_job_dir}/${jar_all_name} || exit)\n\n"
	echo -e "\n\n\t-------->$(date +%F_%H:%M:%S)\t正在执行:\tspark2-submit --class ${Class} --master yarn --driver-memory ${driver} --executor-memory ${memory} --executor-cores ${core}  ${jar_all_name} \n\n"
	chown -R ${ansible_user}:${ansible_user} ${jar_job_dir}
	cd ${jar_job_dir};sudo -u c2b spark2-submit --class ${Class} --master yarn --driver-memory ${driver} --executor-memory ${memory} --executor-cores ${core}  ${jar_all_name} && echo -e "\n\n\t-----> $(date +%F_%H:%M:%S) spark2-submit:\t执行成功\n\n"|| echo -e "\n\n\t-----> $(date +%F_%H:%M:%S) spark2-submit:\t执行失败\n\n"
}




