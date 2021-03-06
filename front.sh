global_path="${JENKINS_HOME}/workspace/${JOB_NAME}/"
cat ${global_path}/deploy_${JOB_NAME}.configure | grep -v ^'#' | sed -e '/^$/d' >  ${global_path}/deploy_${JOB_NAME}.config

while read vri ;do
        export "$vri" 
done < ${global_path}/deploy_${JOB_NAME}.config

if [ $? -eq 0 ];then rm -f ${global_path}/deploy_${JOB_NAME}.configure;fi


#指定war包的名称 
#War_name=Role-Center
#确认执行操作( update or rollback or stop )
#confirm=update
#确认回滚版本号(可选)
#version_number=1
#目标发布主机
#Host=10.133.77.35

#==================
# define configure
#==================
remote_user=appuser
ssh_port=22
script_path=$(ls -d ~/.deploy_scripts/init_deploy.sh)
agent_dir=/tmp/.jenkins

Deploy_config () {
cat > ${JENKINS_HOME}/workspace/${JOB_NAME}/deploy.conf <<EOT
war_name=${War_name}
confirm_action=${confirm}
Rollback_version=${version_number}
JOB_HOME=${JOB_NAME}
Soft=unzip nfs-utils rpcbind

#tomcat variable
Agent_dir=${agent_dir}
tomcat_user=appuser
init_app_path=/app/webapps/releases
init_app=/app/webapps
war_bak_path=/app/war_bak

# nfs configure
#=============
nfs_ip=10.133.115.244
nfs_dir=/app/jenkins_data/workspace
war_data=/srv
# global variable
#=============
JAVA_HOME=/usr/local/jdk
TOMCAT_HOME=/usr/local/tomcat
TOMCAT_LOG_PATH=/app/logs/tomcat
EOT
cp ${script_path} ${JENKINS_HOME}/workspace/${JOB_NAME}/

}
echo -e "\n\n\n\n${USER}\n\n\n\n"
Cmd () {
for IP in ${Host};do
send_source="${JENKINS_HOME}/workspace/${JOB_NAME}"
send_dest="${remote_user}@${IP}:${agent_dir}"
# init
ssh -tt -o StrictHostKeyChecking=no -p ${ssh_port} ${remote_user}@${IP} <<EOF
mkdir ${agent_dir} &>/dev/null
sudo rm -rf ${agent_dir}/${JOB_NAME}
exit
EOF
# data transmission
scp -r -P  ${ssh_port}  ${send_source} ${send_dest}

ssh -tt -o StrictHostKeyChecking=no -p ${ssh_port} ${remote_user}@${IP} <<EOF
cp ${agent_dir}/${JOB_NAME}/deploy.conf ${agent_dir}/
exit
EOF
done
}

echo -e "\n\n\t--->\t$USER\t<---\t\n\n"
Deploy_config
Cmd
