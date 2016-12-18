PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

###########################################################################################################################################
#                                                          Bash function collection                                                       #
#                                               Author: Nguyen Thanh Son <thanhson.rf@gmail.com>                                          #
###########################################################################################################################################

#EXPORT_FUNCTION=`grep -iEoe "^function\s+[^(,{]+" $0 | awk '{print "export -f " $2}'`
#bash -c "$EXPORT_FUNCTION"

###########################################################################################################################################



###########################################################################################################################################
#                                                                  MOUNT UTILS                                                            #
###########################################################################################################################################

function mount_ssh(){
   which sshfs || sudo apt-get install sshfs
   [[ $1 ]] || { echo "Use: $FUNCNAME ssh_serve_address  mount_path"; return 1;  }
   mkdir -p $2
   [[ $1 =~ ([^@]+): ]] && SSH_SERVER_ADD=${BASH_REMATCH[1]} || SSH_SERVER_ADD=''
   
   runcmdbgr "while ! nc -z  $SSH_SERVER_ADD 22 2>/dev/null; do mount -l | grep $2 && fusermount -u $2; sleep 1; done; sshfs $1 $2  -C -o \
   allow_other,sshfs_sync,ServerAliveInterval=15,ServerAliveCountMax=3,dev" 1
}

#                                                                END MOUNT UTILS                                                          #
###########################################################################################################################################



###########################################################################################################################################
#                                                              PARTITION UTILS                                                            #
###########################################################################################################################################

function par_get_badblock(){
   [[ $1 ]] || { echo "Use: $FUNCNAME partition blocksize outputfile"; return 1;  }
   runcmdbgr "badblocks  -c 65536 -wsv -t 0xa5 -o $3 -b $2 $1" 0
}

function par_del_badblock(){
   [[ $1 ]] || { echo "Use: $FUNCNAME partition blocksize input_bad_block_file partition_type"; return 1;  }
   runcmdbgr "mkfs.$4 -b $2 -l $3 $1" 0
   #runcmdbgr "e2fsck -B $2 -l $3"  $1
}

#                                                            END PARTITION UTILS                                                          #
###########################################################################################################################################


###########################################################################################################################################
#                                                             FILEMANAGER UTILS                                                           #
###########################################################################################################################################
function file_lss() {
   [[ $1 ]] || { echo "Use: $FUNCNAME path_dir  depth_dir"; return 1;  }
   [ -n $2 ] && MAX_DEPTH=$2 || MAX_DEPTH=1
   echo Listing ...
   time {
   du -b --max-depth=$MAX_DEPTH "$1" | awk '
BEGIN{i=0;}
{
   line[i] = $2
   size[i] = $1
   i++;
}
END{
    for (i = 0; i < NR; ++i)
    {
        for (j = i + 1; j < NR; ++j)
        {
            if (size[i] > size[j])
            {
                a =  size[i];
                size[i] = size[j];
                size[j] = a;
                
                a =  line[i];
                line[i] = line[j];
                line[j] = a;
                
            }
        }
    }
    for (i = 0; i < NR; ++i)
    {
        if(size[i] < 1024)
           size[i]=size[i]"\tB"
        else if(size[i] < (1024*1024))
           size[i]=size[i]/(1024)"\tK"
        else if(size[i] < (1024*1024*1024))
           size[i]=size[i]/(1024*1024)"\tM"
        else size[i]=size[i]/(1024*1024*1024)"\tG"
        print size[i], "\t",line[i]
    }
}
'
}
}

function file_dir_install(){
    [[ $1 ]] || { echo "Use: $FUNCNAME path_root_dir_need"; return 1;  }
    ROOT_DIR=`realpath $1`
    mkdir -p ${ROOT_DIR}/documents
    mkdir -p ${ROOT_DIR}/music
    mkdir -p ${ROOT_DIR}/pictures
    mkdir -p ${ROOT_DIR}/videos
    mkdir -p ${ROOT_DIR}/work
    mkdir -p ${ROOT_DIR}/software
    mkdir -p ${ROOT_DIR}/tmp
}

function file_get_tree(){
   [[ $1 ]] || { echo "Use: $FUNCNAME path_root_dir_need_get_tree"; return 1; }
   ROOT_DIR=`realpath $1`
   [[ $2 ]] && MAX_DEPTH="-maxdepth $2" || MAX_DEPTH=
   find $ROOT_DIR $MAX_DEPTH -print | sed -e "s;$ROOT_DIR;\.;g;s;[^/]*\/;|__;g;s;__|; |;g"
}
#                                                           ENDFILEMANAGER UTILS
#######################################################################dest####################################################################



###########################################################################################################################################
#                                                              BACKUP, COPY, ARCHIVE UTILS
###########################################################################################################################################
function bca_get_config_ehomevn(){
   sudo scp root@ehomevn.ddns.net:`realpath $1`  `realpath $1`
   . /etc/bash.bashrc.sonnt 
}


function bca_rsyncfile(){
    [[ $1 ]] || { echo "Use: $FUNCNAME path_file_or_dir_on_server  path_dir_on_local_to_store"; return 1;  }
    rsync -avz root@ehomevn.ddns.net:`realpath $1` `realpath $2`
}


function extract(){
 if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract ."
 else
if [ -f $1 ] ; then
        # NAME=${1%.*}
        # mkdir $NAME && cd $NAME
        case $1 in
          *.tar.bz2) tar xvjf ../$1 ;;
          *.tar.gz) tar xvzf ../$1 ;;
          *.tar.xz) tar xvJf ../$1 ;;
          *.lzma) unlzma ../$1 ;;
          *.bz2) bunzip2 ../$1 ;;
          *.rar) unrar x -ad ../$1 ;;
          *.gz) gunzip ../$1 ;;
          *.tar) tar xvf ../$1 ;;
          *.tbz2) tar xvjf ../$1 ;;
          *.tgz) tar xvzf ../$1 ;;
          *.zip) unzip ../$1 ;;
          *.Z) uncompress ../$1 ;;
          *.7z) 7z x ../$1 ;;
          *.xz) unxz ../$1 ;;
          *.exe) cabextract ../$1 ;;
          *) echo "extract: '$1' - unknown archive method" ;;
        esac
else
echo "$1 - file does not exist"
    fi
fi
}


function getdate(){
   date +'%Y_%m_%d___%H_%M_%S'
}


function gzipdir(){
   cur_dir=$(dirname `pwd`/.)
   [[ $1 ]] || { echo "Use: $FUNCNAME source_dir_need_zip des_dir_to_store flagtime"; return 1; }
    time_zip=''
    [[ $3 ]] && time_zip=_`getdate`
    tar -C `dirname $1` -czpf "`realpath $2`/`basename $1`${time_zip}.tar.gz" `basename $1`
}


function gunzipdir(){
   cur_dir=$(dirname `pwd`/.)
   [[ $1 ]] || { echo "Use: $FUNCNAME zipfile_to_extrac path_dir_to_store"; return 1; }
    path_dir_to_store=""
    [[ $2 ]] && path_dir_to_store=-C`realpath  $2`
    tar -xzpf "`realpath $1`" ${path_dir_to_store}
}


function bzipdir(){
   cur_dir=$(dirname `pwd`/.)
   [[ $1 ]] || { echo "Use: $FUNCNAME source_dir_need_zip des_dir_to_store flagtime"; return 1; }
    time_zip=''
    [[ $3 ]] && time_zip=_`getdate`
    tar  -C `dirname $1`  -cjpf "`realpath $2`/`basename $1`${time_zip}.tar.bzip2" `basename $1`
}


function bunzipdir(){
   cur_dir=$(dirname `pwd`/.)
   [[ $1 ]] || { echo "Use: $FUNCNAME zipfile_to_extrac path_dir_to_store"; return 1; }
    path_dir_to_store=''
    [[ $2 ]] && path_dir_to_store=-C `realpath $2`
    tar -xjpf "`realpath $1`" ${path_dir_to_store}
}


function backupsys(){
   [[ $1 ]] || { echo "Use: $FUNCNAME sys_path path_need_backup path_store_backup"; return 1; }
   [ -d "$2" ]  || mkdir -p "$2"
   ROOT_DIR=`realpath $1`
   ROOT_DIR_HAS_SLASH="$ROOT_DIR"
   [ $ROOT_DIR == / ] && ROOT_DIR= || ROOT_DIR_HAS_SLASH=${ROOT_DIR_HAS_SLASH}/
   CUS_EXCLUDE="$3,"
   [[ $3 ]] || CUS_EXCLUDE=''
   BACKUP_DIR=`realpath $2`_prev
   [ -d $BACKUP_DIR ] || mkdir -p $BACKUP_DIR
   echo "Syncing..."
   time {
   rsync -xaXASH --backup --backup-dir=$BACKUP_DIR --info=progress2  --delete --delete-excluded --exclude={$CUS_EXCLUDE"${ROOT_DIR}/swapfile","${ROOT_DIR}/dev/*","${ROOT_DIR}/proc/*","${ROOT_DIR}/sys/*","${ROOT_DIR}/tmp/*","${ROOT_DIR}/run/*","${ROOT_DIR}/mnt/*","${ROOT_DIR}/media/*","lost+found/","${ROOT_DIR}/home/*/.gvfs",\
"${ROOT_DIR}/home/*/.thumbnails/*","${ROOT_DIR}/home/*/.local/share/Trash/*","${ROOT_DIR}/home/*/.cache/mozilla/*","${ROOT_DIR}/home/*/.cache/chromium/*","`realpath $2`"} "$ROOT_DIR_HAS_SLASH"  "$2"
   }
}


function compress_partition(){
   [[ $1 ]] || { echo "Use: $FUNCNAME path_dev__need_backup path_to_store_gzimage_backup"; return 1; }
    dd if="$1" bs=32M | gzip -c > "$2/`basename $1`.img.gz"
}


function unpacking_partition(){
   [[ $1 ]] || { echo "Use: $FUNCNAME gzimage_file path_to_dev_need_restore"; return 1; }
    gzip -cd < "$1" | dd of="$2" bs=32M
}


function chrootsys(){
   [[ $1 ]] || { echo "Use: $FUNCNAME path_new_root"; return 1; }
   new_root_path=`realpath $1` 
   for i in /dev /sys /proc /boot ; do mount --bind $i $new_root_path/$i; done 
   chroot $new_root_path
}
   


function unchrootsys(){
   [[ $1 ]] || { echo "Use: $FUNCNAME path_new_root"; return 1; }
   new_root_path=`realpath $1`
   for i in /dev /sys /proc /boot ; do umount  $new_root_path/$i; done
}
#                                                          END BACKUP, ARCHIVE, COPY UTILS
###########################################################################################################################################



###########################################################################################################################################
#                                                                 MYSQL UTILS
###########################################################################################################################################

function mysql_reset_pass_admin(){
   [[ $1 ]] || { echo "Use: $FUNCNAME addmin_name new_pass"; return 1; }
   service mysql stop && \
   mysqld_safe --skip-grant-tables
   mysql -u root mysql -e "use mysql;
update user set password=PASSWORD('$2') where user='$1'; flush privileges;"
#   service mysql start
}


function mysql_reset_pass_user_nomal(){
   [[ $1 ]] || { echo "Use: $FUNCNAME addmin_name user_name new_pass"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u$1 $admin_pass -e "use mysql;
update user set password=PASSWORD('$3') where user='$2';flush privileges;"
}


#update pass joomla pass:admin
function mysql_update_pass_joomla(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user db_name_joomla user_need_change_pass newpass"; return 1; }
   echo -n "List all user in database:\n"
#   mysql -u"$1" -p -e "use $2;function mysql_create_user()
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user new_user_name pass_of_user domain"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "CREATE USER '$2'@'localhost' IDENTIFIED BY '$3';
   flush privileges;"
}


#delete user
function mysql_dell_user(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user name_user_need_dell domain"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   
   mysql -u"$1" "$admin_pass" -e "drop user '$2'@'localhost';
   flush privileges;";
}


#create database
function mysql_create_db(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user new_database_name"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "create database $2;
   flush privileges;";
}

function mysql_changehost(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user user_name_to_change_host"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
      mysql -u"$1" "$admin_pass" -e "
UPDATE mysql.user SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.db SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.tables_priv SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.columns_priv SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.procs_priv SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.proxies_priv SET Host='%' WHERE Host='localhost' AND User='$2';
flush privileges;
"
}
#add grand database
function mysql_gran_basic_perm_db(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  db_name  user_of_db  pass_gran domain"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   [[ $5 ]] && domain="$5" || domain=localhost
   mysql -u"$1" "$admin_pass" -e "GRANT ALL PRIVILEGES ON *.* to 'root'@'$domain'";
   mysql -u"$1" "$admin_pass" -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES,LOCK TABLES ON $2.* to '$3'@'$domain' IDENTIFIED BY '$4';
flush privileges;"
}


function mysql_gran_full_perm_db(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user db_name user_of_db pass_gran"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $5 ]] && domain="$5" || domain='localhost'
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "GRANT ALL PRIVILEGES ON '$2'.* TO '$3'@'$domain' IDENTIFIED BY '$4';"
}


#show gran for user
function mysql_show_grant_for_user(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  user_need_show_perm domain"; return 1; }
   echo "Type pass $1 user mysql"
   [[ $3 ]] && domain="$3" || domain='localhost'
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "SHOW GRANTS FOR  '$2'@'$domain';"
}


#show detail database
function mysql_show_db_detail(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  db_name hostsql"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   [[ $3 ]] && hostsql=-h$3
   
   x=`mysql -u"$1" "$admin_pass" -e "use $2; show tables;" | awk '{print $1}' | grep -iEve Tables_in[^\s]+` 
   for i in $x; do echo $i;
       echo -e "\nList all fields of table $i"
       mysql -u"$1" "$admin_pass" $hostsql -e "use $2; DESCRIBE $i;" 2>/dev/null       
       [[ $3 ]] && { echo -e "\nList all fields data in of table $i"; mysql -u"$1" "$admin_pass" -e "use $2;  SELECT * FROM $i;" 2>/dev/null; }
   done
}


function mysql_show_users_acess_to_db(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  db_name hostsql"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $3 ]] && hostsql=-h$3
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" $hostsql -e "SELECT * FROM mysql.db WHERE Db = '$2';"
}


function mysql_backup_full(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  full_path_name_file_backup timeflag"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   time_bk=''
   [[ $3 ]] && time_bk=_`getdate`
   mysqldump -u$1 $admin_pass --all-databases | gzip  > $2${time_bk}.sql.gz
}


function mysql_backup_one(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  name_database_backup path_store_file timeflag"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   [[ $4 ]] && time_bk=_`getdate`
   mysqldump -u$1 $admin_pass $2 | gzip > $3/$2${time_bk}.sql.gz
}


function mysql_restore_full(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  full_path_name_file_backup zipflag"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   [[ $3 ]] && gunzip -c $2 | mysql -u$1 $admin_pass  ||   mysql -u$1 $admin_pass < $2
}


function mysql_restore_one(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  database_name  full_path_name_file_backup zipflag"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "create database IF NOT EXISTS $2;"
   [[ $4 ]] && gunzip -c $3 | mysql -u$1 $admin_pass --one-database  $2 ||  mysql -u$1 $admin_pass --one-database  $2 < $3
}


#show all users
function mysql_show_all_users (){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user hostsql"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $2 ]] && hostsql=-h$2
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" $admin_pass $hostsql -e "SELECT User,Host,password FROM mysql.user";
}


#show all databaes
function mysql_show_all_dbs (){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user hostsql"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $2 ]] && hostsql=-h$2
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" $admin_pass $hostsql -e "show databases;";
}


#create user
function mysql_create_user(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user new_user_name pass_of_user domain"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "CREATE USER '$2'@'$4' IDENTIFIED BY '$3';
   flush privileges;"
}


#delete user
function mysql_dell_user(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user name_user_need_dell domain"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $3 ]] && domain=$3 || domain='localhost'
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "drop user '$2'@'$domain';
   flush privileges;";
}


#create database
function mysql_create_db(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user new_database_name"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "create database $2;
   flush privileges;";
}

function mysql_changehost(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user user_name_to_change_host"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
      mysql -u"$1" "$admin_pass" -e "
UPDATE mysql.user SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.db SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.tables_priv SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.columns_priv SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.procs_priv SET Host='%' WHERE Host='localhost' AND User='$2';
UPDATE mysql.proxies_priv SET Host='%' WHERE Host='localhost' AND User='$2';
flush privileges;
"
}
#add grand database
function mysql_gran_basic_perm_db(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  db_name  user_of_db  pass_gran domain"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $5 ]]  && domain="$5" || domain='localhost'
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "GRANT ALL PRIVILEGES ON *.* to 'root'@'$domain'";
   mysql -u"$1" "$admin_pass" -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES,LOCK TABLES ON $2.* to '$3'@'$domain' IDENTIFIED BY '$4';
flush privileges;"
}


function mysql_gran_full_perm_db(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user db_name user_of_db pass_gran"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "GRANT ALL PRIVILEGES ON '$2'.* TO '$3'@localhost IDENTIFIED BY '$4';"
}


#show gran for user
function mysql_show_grant_for_user(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  user_need_show_perm domain"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "SHOW GRANTS FOR  '$2'@'$3';"
}


#show detail database
function mysql_show_db_detail(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  db_name"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   
   x=`mysql -u"$1" "$admin_pass" -e "use $2; show tables;" | awk '{print $1}' | grep -iEve Tables_in[^\s]+` 
   for i in $x; do echo $i;
       echo -e "\nList all fields of table $i"
       mysql -u"$1" "$admin_pass" -e "use $2; DESCRIBE $i;" 2>/dev/null       
       [[ $3 ]] && { echo -e "\nList all fields data in of table $i"; mysql -u"$1" "$admin_pass" -e "use $2;  SELECT * FROM $i;" 2>/dev/null; }
   done
}


function mysql_show_users_acess_to_db(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  db_name"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "SELECT * FROM mysql.db WHERE Db = '$2';"
}


function mysql_backup_full(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  full_path_name_file_backup timeflag"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   time_bk=''
   [[ $3 ]] && time_bk=_`getdate`
   mysqldump -u$1 $admin_pass --all-databases | gzip  > $2${time_bk}.sql.gz
}


function mysql_backup_one(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  name_database_backup path_store_file timeflag"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   [[ $4 ]] && time_bk=_`getdate`
   mysqldump -u$1 "$admin_pass" $2 | gzip > $3/$2${time_bk}.sql.gz
}


function mysql_restore_full(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  full_path_name_file_backup zipflag"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   [[ $3 ]] && gunzip -c $2 | mysql -u$1 $admin_pass  ||   mysql -u$1 $admin_pass < $2
}


function mysql_restore_one(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user  database_name  full_path_name_file_backup zipflag"; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   mysql -u"$1" "$admin_pass" -e "create database IF NOT EXISTS $2;"
   [[ $4 ]] && gunzip -c $3 | mysql -u$1 $admin_pass --one-database  $2 ||  mysql -u$1 $admin_pass --one-database  $2 < $3
}
#                                                               END MYSQL UTILS
###########################################################################################################################################



###########################################################################################################################################
#                                                                 GIT UTILS
###########################################################################################################################################
#                                                                END GIT UTILS
###########################################################################################################################################



###########################################################################################################################################
#                                                                   DISPLAY
###########################################################################################################################################
#$1 resolution $2 monitor $3 apply now(1) or add only (0) $4 pos
function add_resolution (){
    [ -z $4 ] || 
    local listmonitor="`xrandr  --query | grep -P "normal" | grep -Po '^[A-Z][^ ]+'`"
    echo -e "List all monitor:\n$listmonitor";
    
    echo $1 | grep -P ' *[[:digit:]]+ +[[:digit:]]+ +[[:digit:]]+ *' >/dev/null || { echo Error format resolution; return 1; } 
    local modeline=`cvt $1 | grep -i "modeline" |  grep -Po "\".+$"` ||  { echo "Error cvt $1"; return 1; }
    local monitor=`echo $listmonitor | grep -Pio "[^ ]*$2[^ ]*"`   
    xrandr  -q
    local mode=`echo $modeline | grep -Eo '".+"'`
    mode=${mode//\"/}
    { xrandr  -q | grep -F $mode; } || xrandr  --newmode ${modeline//\"/} ||  { echo "Error xrandr  --newmode ${modeline}"; return 1; }
    echo "New mode sucsess"
    xrandr  --addmode $monitor ${mode} ||  { echo "Error xrandr  --addmode $monitor ${mode//\"/}"; return 1; }
    echo "Added mode $mode to $monitor"
    [ $4 ] || POS="--$4"
    (($3 == 1)) && xrandr  --output $monitor $POS  --mode $mode && echo "Curren mode of $monitor is $mode"
    xrandr  -q
}
#                                                                 END DISPLAY
###########################################################################################################################################



###########################################################################################################################################
#                                                                   PERMISSION
###########################################################################################################################################
function chmodwebdir(){
   [ $1 == "-help" ] || [ $1 == "-h" ] && echo "Usage: ./chmodwebdir dirneedchange owner"
   echo "Changing dirs to 775 g/u $2:$2"
   time find $1 -type d -exec chmod 755 {} \;
   echo "Changing filess to 644  g/u $2:$2"
   time find $1 -type f -exec chmod 644 {} \;
   [ -n $2 ] && id -u $2  && chown $2:$2 -R $1 && echo "Success change $1 to user:group of $2:$2" || echo false to change owner:groupowner;
}


function perm_setfacl(){
    [[ $1 ]] || { echo "Use: $FUNCNAME path_dir_need_change_acl groupname"; return 1; }
    echo "Changing..."
    time {
    find $1 -type d -exec setfacl -dm g:$2:rwx {} \;
    find $1 -type d -exec setfacl -m g:$2:rwx {} \;
    find $1 -type f -exec setfacl -m g:$2:rw {} \;
    }
}

function perm_removefacl(){
    [[ $1 ]] || { echo "Use: $FUNCNAME path_dir_need_remove_acl groupname"; return 1; }
    echo "Changing..."
    time {
    find $1 -type d -exec setfacl -x g:$2 {} \;
    find $1 -type f -exec setfacl -x g:$2 {} \;
    }
}

function perm_removeallfacl(){
    [[ $1 ]] || { echo "Use: $FUNCNAME path_dir_need_remove_all_acl "; return 1; }
    echo "Changing..."
    time {
    setfacl -Rb $1
    }
}

function perm_change_uid(){
    [[ $1 ]] || { echo "Use: $FUNCNAME username_need_change new_uid "; return 1; }
    echo "Changing..."
    old_uid=`id $1 | grep -oEe "uid=[0-9]+" | grep -oEe "[0-9]+"` || return 0
    [[ $old_uid == $2 ]] && return 0
    time {
        usermod -u $2 $1
        find / ! -path "/proc/*" ! -path "/var/run/*" ! -path "/dev/*" -user $old_uid -exec chown -h $2 {} \;        
    }
    return 0
}

function perm_change_gid(){
    [[ $1 ]] || { echo "Use: $FUNCNAME group_need_change new_gid "; return 1; }
    echo "Changing..."
    old_gid=`id $1 | grep -oEe "gid=[0-9]+" | grep -oEe "[0-9]+"` || return 0
    [[ $old_gid == $2 ]] && return 0
    time {
        groupmod -g $2 $1
        find / ! -path "/proc/*" ! -path "/var/run/*" ! -path "/dev/*" -group $old_gid -exec chgrp -h $1 {} \;
    }
    return 0
}

function perm_change_ugid(){
    [[ $1 ]] || { echo "Use: $FUNCNAME ugid_need_change new_ugid "; return 1; }
    perm_change_uid $1 $2
    perm_change_gid $1 $2
}

function perm_get_home(){
   [[ $1 ]] || { echo "Use: $FUNCNAME user"; return 1; }
   echo $(getent passwd $1 )| cut -d : -f 6
}

#                                                                END PERMISSION
###########################################################################################################################################



###########################################################################################################################################
#                                                                   MESSEGER
###########################################################################################################################################
function sendmess2hang(){
   [[ $1 ]] || { echo "Use: $FUNCNAME mail_to_send  mess"; return 1; }
   ping -c1 -W3 google.com &>/dev/null || return 1
   echo -e "$2" | /usr/bin/sendxmpp -t -u zenercrystal -p emyeutoi -o gmail.com ${1%@*}
}
#                                                                 END MESSEGER
###########################################################################################################################################



###########################################################################################################################################
#                                                                   EDIT FILE
###########################################################################################################################################


function put_a_line_to_file_if_do_not_exsit (){
   [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] && { echo "Use: $FUNCNAME 'text regx to search' 'text use for replace' 'path to file'"; return 1; }
   [ -f "$3" ] || { echo "Can not found file $3"; return 1; }
   ! /bin/grep -E "$1" "$3" && echo "$2" >> "$3" || /bin/sed -i -r -e "s~$1~$2~g" "$3" 
}

alias efile_change_substring_of_line='put_a_line_to_file_if_do_not_exsit'

function efile_insert_at_line (){
   [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] && { echo "Use: $FUNCNAME 'line_to_insert_before' 'content_insering_line' 'path _of_file'"; return 1; }
   [ -f "$3" ] || { echo "Can not found file $3"; return 1; }
   /bin/sed -i -r -e "$1i$2" "$3" 
}

function efile_insert_before_line_has_string (){
   [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] && { echo "Use: $FUNCNAME 'text_2_search' 'content_insering_line' 'path _of_file'"; return 1; }
   [ -f "$3" ] || { echo "Can not found file $3"; return 1; }
   /bin/sed -i -r -e "/$1/i$2" "$3" 
}

function efile_insert_after_line_has_string (){
   [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] && { echo "Use: $FUNCNAME 'text_2_search' 'content_insering_line' 'path _of_file'"; return 1; }
   [ -f "$3" ] || { echo "Can not found file $3"; return 1; }
   /bin/sed -i -r -e "/$1/a$2" "$3" 
}

function efile_change_line_has_string (){
   [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] && { echo "Use: $FUNCNAME 'text_2_search' 'content_insering_line' 'path _of_file'"; return 1; }
   [ -f "$3" ] || { echo "Can not found file $3"; return 1; }
   /bin/sed -i -r -e "/$1/c$2" "$3" 
}

#                                                                 END EDIT FILE
###########################################################################################################################################

###########################################################################################################################################
#                                                                   OWNCLOUD
###########################################################################################################################################
function occ_scan(){
 sudo -uwww-data php -f ${OWNCLOUD_PATH}/occ files:scan --path="/${1}/files/$2"
}

function occ_cmd(){
 sudo -uwww-data php -f ${OWNCLOUD_PATH}/occ $1
}

function occ_delllock(){
   [[ $1 ]] || { echo "Use: $FUNCNAME admin_user "; return 1; }
   echo "Type pass $1 user mysql"
   read -s admin_pass
   [[ $admin_pass ]] && admin_pass=-p$admin_pass
   sed -r "s/.*maintenance.*/  maintenance' => true,/g" ${OWNCLOUD_PATH}/config/config.php
   mysql -u"$1" $admin_pass  -e "use owncloud; delete from oc_file_locks where 1;";
   sed -r "s/.*maintenance.*/  'maintenance' => false,/g" ${OWNCLOUD_PATH}/config/config.php
}
#                                                                 END OWNCLOUD
###########################################################################################################################################



###########################################################################################################################################
#                                                                   NETWORK
###########################################################################################################################################
function getwanip (){
   dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null || curl -s  ifconfig.me 2>/dev/null || dig +short ehomevn.ddns 2>/dev/null
}

function nets (){
   clear;
   netstat -pantu | grep -ie "$1"   
}

function net_getlanips (){
    [[ $1 ]] || { echo "Use: $FUNCNAME interface_name"; return 1; }
    [[ $1 =~ ([0-9]+\.){3}[0-9]+ ]] && SUPNET=$1 || SUPNET=`ip -o -f inet addr show $1 | awk '/scope global/ {print $4}'`
   nmap -sP $SUPNET 2>/dev/null | awk '{
      if(match($0,/([0-9]+\.){3}[0-9]+/)){
        printf "%s",substr($0, RSTART, RLENGTH);
        if(match($0,/for\s+\(/)){
          domain=$5
        };
      };
      if(match($0,/([0-F]+:){5}[0-F]+/)){
        MAC_ADD=substr($0, RSTART, RLENGTH);
        if(match($0,/\(.+/)){
          vendo=$5
        };
        printf "\t%s\t%s\t%s\n", MAC_ADD, domain,  substr($0, RSTART, RLENGTH);
      };
   }END{print ""}'
} 
alias getlanips='net_getlanips'

function net_getmask (){
    [[ $1 ]] || { echo "Use: $FUNCNAME interface_name"; return 1; }
    ip -o -f inet addr show $1 | awk '/scope/ {print $4}'
}


function net_waitnet(){
    [[ $1 ]] || { echo "Use: $FUNCNAME timeout"; return 1; }
    timeout ${1} bash -c "while ! ping -c 1 -W 1 google.com.vn; do sleep 1; done;" &>/dev/null
}
alias waitnet='net_waitnet'

function net_get_dest_mac(){
   NEXT_MAC=$(nmap -sP $1 2>/dev/null | grep -iEoe "([0-F]+:){5}[0-F]+") && { echo $NEXT_MAC; return 0; } 2>/dev/null
   IP_TO_CHECK=$(traceroute -m 3 ehomevn.ddns.net | grep -ioEe " [1-2]  ([0-9]+\.){3}[0-9]+" | awk '{
         if(match($0,/^ 1/)){print $2; HASMAX=1;} else {
            if(HASMAX==0){print $2;}         
          }
      }
   ') 2>/dev/null
   NEXT_MAC=$(nmap -sP $IP_TO_CHECK | grep -iEoe "([0-F]+:){5}[0-F]+") && { echo $NEXT_MAC; return 0; }
}
#                                                                 END NETWORK
###########################################################################################################################################



###########################################################################################################################################
#                                                                  BASH UTILS
###########################################################################################################################################
function set_var (){
   [[ $1 ]] || { echo "Use: $FUNCNAME  variable_name new_value_variable path_file_store_variable"; return 1; }
   put_a_line_to_file_if_do_not_exsit ".*$1.*" "$1=$2" "$3"
   sed -i -e '$a\'  "$3"
}


function runcmdbgr(){
    [[ $1 ]] || { echo -e "Use: $FUNCNAME \"list_command\" time_interval\nNeed ; at end of list_command"; return 1; }
    { [[ $2 == 0 ]] || [[ -z $2 ]]; } && SLEEP_S='break' || SLEEP_S="sleep $2"
    CMD="$1"
    CMD=${CMD%"${CMD##*[![:space:]]}"}
    CMD=${CMD%;}
    echo "export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin;\
    while ((1)); do { $CMD; } & LAST_PID=\$!; $SLEEP_S; [[ \$LAST_PID =~ ^[0-9]+ ]] && while [ -d /proc/\$LAST_PID ]; do sleep 1; done; done;" |  nohup bash >/dev/null 2>&1 &
    echo -e "\nPID runing backround: $!";
}
#                                                                END  BASH UTILS
###########################################################################################################################################

function cl_kswap(){
   ## run as cron, thus no $PATH, thus need to define all absolute paths
   top=$(top -bn1 -o \%CPU -u0 | grep -m2 -E "%CPU|kswapd0")

   IFS='
   '
   set -f

   i=0

   for line in $top
   do
         #echo $i $line

         if ! (( i++ ))
         then
               pos=${line%%%CPU*}
               pos=${#pos}
               #echo $pos
         else
               cpu=${line:(($pos-1)):3}
               cpu=${cpu// /}
               #echo $cpu
         fi

   done

   [[ -n $cpu ]] && \
   (( $cpu >= 90 )) \
   && echo 1 > /proc/sys/vm/drop_caches \
   && echo "$$ $0: cache dropped (kswapd0 %CPU=$cpu)" >&2 \
   && return 1
   return 0
}


###########################################################################################################################################
#                                                              PROCESS MANAGER
###########################################################################################################################################
function pgrepe (){
   clear
   ps aux | grep -iEe "$1"
}
#                                                             END PROCESS MANAGER
###########################################################################################################################################



###########################################################################################################################################
#                                                                   DOCKER
###########################################################################################################################################
function docker_bash (){
   [[ $1 ]] || { echo "Use: $FUNCNAME container_name"; return 1; }
   docker exec -it $1 /bin/bash
}

function docker_exec (){
   [[ $1 ]] || { echo "Use: $FUNCNAME container_name command"; return 1; }
   docker exec -it "$1" "$2"
}

function docker_run(){
   [[ $1 ]] || { echo "Use: $FUNCNAME container_name host_name netname ip"; return 1; }
   docker ps -a | grep $2 || docker run \
   --name $2 \
   -h$2\
   --restart always \
   --network $3\
   --ip $4\
   -it\
   $1
}

function docker_remove_all_untag (){
   docker rmi $(docker images | grep "<none>" | awk '{print $3}')
}

function docker_commit (){
   [[ $1 ]] || { echo "Use: $FUNCNAME container_name repository"; return 1; }
   docker commit -a"sonnt <thanhson.rf@gmail.com>" $1 $2
}

function docker_stop_all_container(){
   for i in `docker ps | cut -d' ' -f1  | grep -ve CONTAINER`;do docker stop $i ;done
}

function docker_remove_all_container(){
   docker_stop_all_container
   for i in `docker ps -a | cut -d' ' -f1  | grep -ve CONTAINER`;do docker rm -fv $i ;done
}

function docker_remove_all_images(){
   docker_remove_all_container
   for i in `docker images | awk '{print $3}' | grep -ve IMAGE`;do docker rmi -f $i ;done
   service docker stop
#   rm -rf /var/lib/docker/*
#   rm -rf /var/lib/docker/aufs/diff/*
#   rm -rf /var/lib/docker/aufs/layers/*
#   rm -rf /var/lib/docker/aufs/mnt/*
   service docker start
}

function docker_reinstall(){
   service docker stop
   apt-get remove  -y --purge docker-engine
   rm -rf /var/lib/docker/aufs/*
   apt-get install -y docker-engine
}
#                                                                   END DOCKER
###########################################################################################################################################



###########################################################################################################################################
#                                                                      SSL
###########################################################################################################################################
function ssl_gen(){
   [[ $1 ]] || { echo "Use: $FUNCNAME path_store  name_output domain country state locality organization organizationalunit email opcoma
Description Options:
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:New York
Locality Name (eg, city) []:New York City
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Your Company
Organizational Unit Name (eg, section) []:Department of Kittens
Common Name (e.g. server FQDN or YOUR name) []:your_domain.com
Email Address []:your_email@domain.com"; return 1; }
   which expect || { echo install expect before run $FUNCNAME; return 1; }
   PATH_STORE="`realpath $1`"
   name_output="$2"
   domain="$3"
   commonname="$domain"
   country="$4"
   state="$5"
   locality="$6"
   organization="$7"
   organizationalunit="$8"
   email="$9"
   opcomna="${10}"
   #Create the server private key
   openssl genrsa -out ${PATH_STORE}/${name_output}.key 2048
   
   # Create the certificate signing request (CSR)
   expect -c "
   spawn openssl req -new -key ${PATH_STORE}/${name_output}.key -out ${PATH_STORE}/${name_output}.csr
   expect \":\"
   send \"$country\n\"
   
   expect \":\"
   send \"$state\n\"
   
   expect \":\"
   send \"$locality\n\"
   
   expect \":\"
   send \"$organization\n\"

   expect \":\"
   send \"$organizationalunit\n\"                          

   expect \":\"
   send \"$commonname\n\"

   expect \":\"
   send \"$email\n\"     

   expect \":\"
   send  \"\n\"

   expect \":\"
   send \"$opcomna\n\"
   interact;   
   "

   #Sign the certificate using the private key and CSR
   openssl x509 -req -days 36500 -in ${PATH_STORE}/${name_output}.csr -signkey ${PATH_STORE}/${name_output}.key -out ${PATH_STORE}/${name_output}.crt

   #Strengthening the server security
   openssl dhparam -out dhparam.pem 2048  
   cat ${PATH_STORE}/${name_output}.key > ${PATH_STORE}/${name_output}.pem
   cat ${PATH_STORE}/${name_output}.crt >> ${PATH_STORE}/${name_output}.pem
   chmod 400 ${PATH_STORE}/${name_output}.key
}

function ssl_selfcert_apache(){
   [[ $1 ]] || { echo "Use: $FUNCNAME path_store  name_output domain country state locality organization organizationalunit email opcoma
Description Options:
Country Name (2 letter code) [AU]:US
State or Province Name (full name) [Some-State]:New York
Locality Name (eg, city) []:New York City
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Your Company
Organizational Unit Name (eg, section) []:Department of Kittens
Common Name (e.g. server FQDN or YOUR name) []:your_domain.com
Email Address []:your_email@domain.com"; return 1; }
   which expect || { echo install expect before run $FUNCNAME; return 1; }
   PATH_STORE="`realpath $1`"
   name_output="$2"
   domain="$3"
   commonname="$domain"
   country="$4"
   state="$5"
   locality="$6"
   organization="$7"
   organizationalunit="$8"
   email="$9"
   opcomna="${10}"

   expect -c "
   spawn openssl req -x509 -nodes -days 36500 -newkey rsa:2048 -keyout ${PATH_STORE}/${name_output}.key -out ${PATH_STORE}/${name_output}.crt
   expect \":\"
   send \"$country\n\"
   
   expect \":\"
   send \"$state\n\"
   
   expect \":\"
   send \"$locality\n\"
   
   expect \":\"
   send \"$organization\n\"

   expect \":\"
   send \"$organizationalunit\n\"                          

   expect \":\"
   send \"$commonname\n\"

   expect \":\"
   send \"$email\n\"
   
   interact;   
   "
}
#                                                                    END SSL
###########################################################################################################################################

###########################################################################################################################################
#                                                                     EXPECT
###########################################################################################################################################

function expect_auto_type {
    [[ $1 ]] || { echo "Use: $FUNCNAME timeout command expect text2send"; return 1; }
    exsend=''
    for ((i = $# - 1; i >= 3; i -= 2)); do ((j = i + 1));  [[ $exsend ]] && oldexsend="$exsend" || oldexsend='' ; exsend="\nexpect {\n \"${!i}\"\n send \"${!j}\\r\"\n $oldexsend\n}";done
    echo -e --$exsend--
    exsend=`echo -e $exsend`
    expect -c "
        set timeout $1
        spawn $2
        $exsend
        interact;
    "
    #history -c && history -w
}

function expect_wait {
    [[ $1 ]] || { echo "Use: $FUNCNAME timeout expect text2send"; return 1; }
    expect -c "
        set timeout $1
        expect {
           \"$2\" {
              send \"$3\r\"
           }
        }
        interact;
    "
    #history -c && history -w
}

#                                                                    END EXPECT
###########################################################################################################################################

function progressbar {
    [[ $1 ]] || { echo "Use: $FUNCNAME current total"; return 1; }
    total_seg=50
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*$total_seg)/100
    let _left=$total_seg-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%";
    [[ $3 ]] && echo ""
}
