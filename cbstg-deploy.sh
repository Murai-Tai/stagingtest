#!/bin/bash
##
## Name:        deploy.sh
## Version:     1.0.1
## Auther:      saiga@cubit.jp
## Site:        staging.cubit.ne.jp
## Modify:      2021/04/17

### Usage, Information, Alert, Error etc..
function USAGE() {
  echo -e "${VAR_BASH_NOTICE}usage:${VAR_BASH_RST}"
  echo -e "`basename $0` ${VAR_BASH_BOLD}[PROJECT] stg-git     ${VAR_BASH_RST} // ${VAR_BASH_ULINE} Exec git command at STG${VAR_BASH_RST}"
  echo -e "`basename $0` ${VAR_BASH_BOLD}[PROJECT] stg-test    ${VAR_BASH_RST} // ${VAR_BASH_ULINE} Exec dry-run to STG${VAR_BASH_RST}"
  echo -e "`basename $0` ${VAR_BASH_BOLD}[PROJECT] stg-deploy  ${VAR_BASH_RST} // ${VAR_BASH_ULINE} Exec deploy  to STG${VAR_BASH_RST}"
  echo -e "`basename $0` ${VAR_BASH_BOLD}[PROJECT] prod-test   ${VAR_BASH_RST} // ${VAR_BASH_ULINE} Exec dry-run to PROD${VAR_BASH_RST}"
  echo -e "`basename $0` ${VAR_BASH_BOLD}[PROJECT] prod-deploy ${VAR_BASH_RST} // ${VAR_BASH_ULINE} Exec deploy  to PROD${VAR_BASH_RST}"
}


### Init Variable bash style
VAR_BASH_ESC=$(printf '\033');         ## Escape
VAR_BASH_RST="${VAR_BASH_ESC}[0;39m";  ## Reset
VAR_BASH_ERR="${VAR_BASH_ESC}[31m";    ## Color Red
VAR_BASH_INFO="${VAR_BASH_ESC}[32m";   ## Color Green
VAR_BASH_NOTICE="${VAR_BASH_ESC}[33m"; ## COlor Yellow
VAR_BASH_BOLD="${VAR_BASH_ESC}[1m";    ## Style Bold
VAR_BASH_ULINE="${VAR_BASH_ESC}[4m";   ## Style Underline


### Set configfile value
DIR_WORKING='/home/cb-user/WorkSpace';
DIR_PROJECT="${DIR_WORKING}/$1";

FILE_PROJECTINI='.project.ini';
FILE_EXCLUDE='.sync-exclude.ini';
FILE_EXCLUDE_STG='.sync-exclude-stg.ini';
FILE_RSYNC_ADD_OPTION='.sync-add-option.ini';
FILE_RSYNC_ADD_OPTION_STG='.sync-add-option-stg.ini';

### Check arguments
if [ $# -lt 1 ]; then
  USAGE;
  exit 0;
elif [ $# -lt 2 ]; then
  echo -e "${VAR_BASH_ERR}`basename $0` [PROJECT] [MODE]${VAR_BASH_RST} // ${VAR_BASH_ULINE} You need to specify the [PRPJECT] [MODE] and to execute.${VAR_BASH_RST}";
  exit 0;
fi


### Check project directory
if [[ -e ${DIR_PROJECT} ]]; then
  ### Load config
  if [[ -e ${DIR_PROJECT}/${FILE_PROJECTINI} ]]; then
    . ${DIR_PROJECT}/${FILE_PROJECTINI};
  else
    echo -e "${VAR_BASH_ERR}The specified project ${VAR_BASH_ULINE}($1)${VAR_BASH_RST}${VAR_BASH_ERR} or configuration file ${VAR_BASH_ULINE}(${FILE_PROJECTINI})${VAR_BASH_RST}${VAR_BASH_ERR} does not exist.${VAR_BASH_RST}";
    exit 0;
  fi
else
  echo -e "${VAR_BASH_ERR}The specified project name did not exist.${VAR_BASH_RST}";
  exit 0;
fi


## Rsync command setting
CMD_RSYNC_OPT_COMMON='-u -rlOtcv --omit-dir-times --exclude-from=';
CMD_RSYNC_OPTION="${CMD_RSYNC_OPT_COMMON}${DIR_PROJECT}/${FILE_EXCLUDE}";
CMD_RSYNC_OPTION_ADD='';
CMD_RSYNC_OPTION_ADD_STG='';


if [[ -e ${DIR_PROJECT}/${FILE_EXCLUDE_STG} ]]; then
  CMD_RSYNC_OPTION_STG="${CMD_RSYNC_OPT_COMMON}${DIR_PROJECT}/${FILE_EXCLUDE_STG}";
else
  CMD_RSYNC_OPTION_STG=${CMD_RSYNC_OPTION};
fi
if [[ -e ${DIR_PROJECT}/${FILE_RSYNC_ADD_OPTION} ]]; then
  CMD_RSYNC_OPTION_ADD=`cat ${DIR_PROJECT}/${FILE_RSYNC_ADD_OPTION}`
fi
if [[ -e ${DIR_PROJECT}/${FILE_RSYNC_ADD_OPTION_STG} ]]; then
  CMD_RSYNC_OPTION_ADD_STG=`cat ${DIR_PROJECT}/${FILE_RSYNC_ADD_OPTION_STG}`
else
  CMD_RSYNC_OPTION_ADD_STG=${CMD_RSYNC_OPTION_ADD};
fi


## Git command setting
DIR_GIT_WORKING="${DIR_PROJECT}/Git/${DIR_GIT_REPONAME}";


## SSH command setting
CMD_SSH_OPT='-i /home/cb-user/.ssh/cb-user-common_ecdsa';



### Main
case "$2" in

    "stg-git" )
      echo -e "${VAR_BASH_INFO}[${VAR_SV_STG}]: run git command.${VAR_BASH_RST}"
      (
        cd ${DIR_GIT_WORKING};
        git pull origin ${DIR_GIT_BLANCH};
      )
      echo -e "${VAR_BASH_INFO}[${VAR_SV_STG}]: git pull finish.${VAR_BASH_RST}"
      ;;

    "stg-test" )
      echo -e "${VAR_BASH_INFO}[${VAR_SV_STG}]: exec rsync dry-run.${VAR_BASH_RST}"
      (
        rsync -n $(eval echo ${CMD_RSYNC_OPTION_STG}) ${CMD_RSYNC_OPTION_ADD_STG} ${DIR_GIT_WORKING}/${DIR_GIT_SYNCROOT}/ ${DIR_HTTPROOT_STG}/
      )
      echo -e "${VAR_BASH_INFO}[${VAR_SV_STG}]: dry-run finish.${VAR_BASH_RST}";
      ;;

    "stg-deploy" )
      echo -e "${VAR_BASH_INFO}[${VAR_SV_STG}]: exec rsync.${VAR_BASH_RST}"
      (
        rsync $(eval echo ${CMD_RSYNC_OPTION_STG}) ${CMD_RSYNC_OPTION_ADD_STG} ${DIR_GIT_WORKING}/${DIR_GIT_SYNCROOT}/ ${DIR_HTTPROOT_STG}/
      )
      echo -e "${VAR_BASH_INFO}[${VAR_SV_STG}]: deploy finish.${VAR_BASH_RST}";
      ;;

    "prod-test" )
      echo -e "${VAR_BASH_INFO}[${ARRAY_SV_PROD[0]}]: exec rsync dry-run.${VAR_BASH_RST}"
      (
        rsync -n $(eval echo ${CMD_RSYNC_OPTION}) ${CMD_RSYNC_OPTION_ADD} -e "ssh ${CMD_SSH_OPT}" ${DIR_HTTPROOT_STG}/ ${ARRAY_SV_PROD[0]}:${DIR_HTTPROOT_PROD}/
      )
      echo -e "${VAR_BASH_INFO}[${ARRAY_SV_PROD[0]}]: deploy finish.${VAR_BASH_RST}";
      ;;

    "prod-deploy" )
      for (( i = 0; i < ${#ARRAY_SV_PROD[*]}; i++ ))
      {
        echo -e "${VAR_BASH_INFO}[${ARRAY_SV_PROD[i]}]: exec rsync.${VAR_BASH_RST}"
        (
          rsync $(eval echo ${CMD_RSYNC_OPTION}) ${CMD_RSYNC_OPTION_ADD} -e "ssh ${CMD_SSH_OPT}" ${DIR_HTTPROOT_STG}/ ${ARRAY_SV_PROD[i]}:${DIR_HTTPROOT_PROD}/
        )
        echo -e "${VAR_BASH_INFO}[${ARRAY_SV_PROD[i]}]: deploy finish.${VAR_BASH_RST}";
      }
      ;;

    * )
      USAGE
      exit 0;
      ;;
esac


exit 1;
