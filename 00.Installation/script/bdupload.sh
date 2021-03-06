#!/bin/bash
# --------------------------------------------------------------------------------
bdinfocli_path="/etc/inexistence/02.Tools/bdinfocli.exe"
# --------------------------------------------------------------------------------
black=$(tput setaf 0); red=$(tput setaf 1); green=$(tput setaf 2); yellow=$(tput setaf 3);
blue=$(tput setaf 4); magenta=$(tput setaf 5); cyan=$(tput setaf 6); white=$(tput setaf 7);
on_red=$(tput setab 1); on_green=$(tput setab 2); on_yellow=$(tput setab 3); on_blue=$(tput setab 4);
on_magenta=$(tput setab 5); on_cyan=$(tput setab 6); on_white=$(tput setab 7); bold=$(tput bold);
dim=$(tput dim); underline=$(tput smul); reset_underline=$(tput rmul); standout=$(tput smso);
reset_standout=$(tput rmso); normal=$(tput sgr0); alert=${white}${on_red}; title=${standout};
baihuangse=${white}${on_yellow}; bailanse=${white}${on_blue}; bailvse=${white}${on_green};
baiqingse=${white}${on_cyan}; baihongse=${white}${on_red}; baizise=${white}${on_magenta};
heibaise=${black}${on_white};
shanshuo=$(tput blink); wuguangbiao=$(tput civis); guangbiao=$(tput cnorm)
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------

# 必要软件检查
function _check_install(){
app_location=$( command -v ${app_name} )
if [[ ! -e $app_location ]]; then
    #echo "${baihongse}${app_name}${normal} is missing"
    eval "${app_name}"_installed=No
    echo "${app_name} " >> tmpmissingapp
    sed -i ':t;N;s/\n//;b t' tmpmissingapp
    tmpmissingapp=$(cat tmpmissingapp)
    appmissing="Yes"
fi
}

# 安装ffmpeg
function _install_ffmpeg(){
apt-get -y install lsb-release
relno=$(lsb_release -sr | cut -d. -f1)

if [ $relno = 8 ]; then
    grep "deb http://www.deb-multimedia.org jessie main" /etc/apt/sources.list >> /dev/null || echo "deb http://www.deb-multimedia.org jessie main" >> /etc/apt/sources.list
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5C808C2B65558117
    apt-get update
    apt-get -y install deb-multimedia-keyring
    apt-get update
    apt-get -y install ffmpeg
else
    apt-get -y install ffmpeg
fi
}



# 简介与检查
function _intro() {

clear
wget --no-check-certificate -qO- https://github.com/Aniverse/inexistence/raw/master/03.Files/bluray.logo.1
echo -e "${bold}Automated Blu-ray Upload Toolkit${normal}"


if [[ $EUID != 0 ]]; then
    echo; echo "${baihongse}You need to run this script with root privileges${normal}"
    echo " Exiting..."; echo
    exit 1
fi


if [[ ! -e $bdinfocli_path ]]; then
    mkdir -p /etc/inexistence/02.Tools
    wget --no-check-certificate -qO /etc/inexistence/02.Tools/bdinfocli.exe https://raw.githubusercontent.com/Aniverse/inexistence/master/02.Tools/bdinfocli.exe
    chmod 777 /etc/inexistence/02.Tools/bdinfocli.exe
fi


for apps in ffmpeg vcs mono mktorrent convert montage identify bash getopt cut; do
    app_name=$apps; _check_install
done

rm -rf tmpmissingapp

if [[ $appmissing == "Yes" ]]; then

    echo; echo -e "Oooops, ${baihongse}${tmpmissingapp%?}${normal} is missing, without them the script can't work,"; echo
    echo -ne "${yellow}Do you want to install them?${white} [${cyan}Y${normal}]es or [N]o: "; read responce

    case $responce in
        [yY] | [yY][Ee][Ss] | "" ) installmissing=Yes ;;
        [nN] | [nN][Oo]) installmissing=No ;;
        *) installmissing=Yes ;;
    esac

    if [[ $installmissing == "Yes" ]]; then

        apt-get install -y mono-complete mktorrent imagemagick

        if [ "${ffmpeg_installed}" == "No" ]; then
            _install_ffmpeg
        fi

        if [ "${vcs_installed}" == "No" ]; then
            wget --no-check-certificate -qO /usr/local/bin/vcs https://raw.githubusercontent.com/Aniverse/inexistence/master/03.Files/app/vcs
            chmod 777 /usr/loacl/bin/vcs
        fi

    else

	    echo; echo -e "${red}Since ${tmpmissingapp%?} is missing, aborting script ...${white}"; echo
        exit 1

    fi

    clear
    wget --no-check-certificate -qO- https://github.com/Aniverse/inexistence/raw/master/03.Files/bluray.logo.1
    echo -e "${bold}Automated Blu-ray Upload Toolkit${normal}"

fi

}





# 询问路径
function _askpath() {

echo; echo -e "Note that ${blue}Ultra Blu-ray${white} is not supported yet"
echo -ne "${yellow}Input the path to your stuff: ${normal}"; read pathtostuff
echo

}


# 挂载、定义变量
function _stufftype() {

if [[ -d "${pathtostuff}" ]]; then
    stufftype=BDMV
    echo -e "${magenta}BDMV${white} detected ..."
else
    stufftype=BDISO
    echo -e "${magenta}BDISO${white} detected ..."
fi

if [[ "${stufftype}" == "BDISO" ]]; then

    bdisopath="$pathtostuff"
    bdisopathlower=$(echo "$bdisopath" | sed 's/[Ii][Ss][Oo]/iso/g')
    bdisotitle=$(basename "$bdisopathlower" .iso)
    echo
    echo -e "The Script will mount BDISO to a folder, and now you need to enter the folder name"
    echo -e "The folder name will also be your torrents' name (If you want to create a torrent)"
    echo -e "By default the script will use BDISO's title as folder's name"
    read -e -p "Input the Blu-ray name you want: ${green}" -i ${bdisotitle} file_title
    echo -ne "${white}"

elif [[ "${stufftype}" == "BDMV" ]]; then

    bdmvpath="$pathtostuff"
    bdpath="$pathtostuff"
    file_title=`basename "$bdmvpath"`

fi

file_title_clean="$(echo "$file_title" | tr '[:space:]' '.')"
file_title_clean="$(echo "$file_title_clean" | sed s'/[.]$//')"
file_title_clean="$(echo "$file_title_clean" | tr -d '(')"
file_title_clean="$(echo "$file_title_clean" | tr -d ')')"

if [[ "${stufftype}" == "BDISO" ]]; then
    mkdir -p "/etc/inexistence/06.BluRay/$file_title_clean"
    bdpath="/etc/inexistence/06.BluRay/$file_title_clean"
    mount -o loop "$bdisopath" "$bdpath" >> /dev/null 2>&1
fi

tempvar=$(find "$bdpath" -type f -print0 | xargs -0 ls -1S)
main_m2ts_path=$(echo "$tempvar" | head -n 1)
duration1=$(ffmpeg -i "$main_m2ts_path"  /dev/null 2>&1 | egrep '(Duration:)' | cut -d ' ' -f4 | cut -c1-8)
duration2=`date -u -d "1970-01-01 $duration" +%s`

mkdir -p "/etc/inexistence/04.Upload/$file_title_clean"
outputpath="/etc/inexistence/04.Upload/$file_title_clean"

echo

}


# 询问扫描BDinfo
function _askscan() {

echo -e "01) ${cyan}Auto scan the first longest playlist${white}"
echo -e "02) ${cyan}Manually select which playlist to scan${white}"
echo -e "03) ${cyan}Do not scan BDinfo${white}"
echo -ne "${yellow}Whould you like to scan BDinfo?${white} (default: ${cyan}01${white}) "; read response

case $response in
    01 | 1 | "") bdscan=auto ;;
    02 | 2) bdscan=manual ;;
    03 | 3) bdscan=no ;;
    *) bdscan=auto ;;
esac

if [ "${bdscan}" == "auto" ]; then
    echo "The script will scan the first longest playlist automaticly"
elif [ "${bdscan}" == "manual" ]; then
    echo "Auto scan disabled, you need to select the mpls manually"
else
    echo "BDinfo will not be scanned"
fi

echo

}


# 询问截图分辨率
function _askresolution() {

echo -e "01) ${cyan}1920x1080${white}"
echo -e "02) ${cyan}auto detect${white}"
echo -e "03) ${cyan}Input a specific resolution${white}"
echo -e "04) ${cyan}Do not take screenshots${white}"
echo -e "Since some BD's resolution are 1440x1080 with a 16:9 AR, I recommand specify 1920x1080"
echo -ne "${yellow}Which resolution of the screenshots you want?${white} (default ${cyan}01${white})"; read response

case $response in
    01 | 1 | "") resolution=1080p ;;
    02 | 2) resolution=auto ;;
    03 | 3) resolution=input ;;
    04 | 4) resolution=no ;;
    *) resolution=1080p ;;
esac


if [[ "${resolution}" == "1080p" ]]; then
    echo -e "The script will take 10 screenshots in 1920×1080"
elif [[ "${resolution}" == "auto" ]]; then
    echo -e "The script will take 10 screenshots in origin resolution"
elif [[ "${resolution}" == "input" ]]; then
    echo
    read -e -p "Input the screenshost' resolution you want: ${green}" -i 1280x720 fenbianlv
    echo -e "${normal}The script will take 10 screenshots in ${green}$fenbianlv${normal}"
fi

if [[ ! "${resolution}" == "no" ]]; then
    echo
    echo -ne "${yellow}Would you like to generate a thumbnail?${white} [Y]es or [${cyan}N${white}]o "
    read responce
    case $responce in
        [yY] | [yY][Ee][Ss] )  sstn=Yes ;;
        [nN] | [nN][Oo] | "" )  sstn=No ;;
        *) sstn=No ;;
    esac
fi

if [[ $sstn == Yes ]]; then
    echo -e "The script will generate a thumbnail"
else
    echo -e "The script will not generate a thumbnail"
fi

echo

}


# 询问是否制作种子
function _askmktorrent() {

echo -ne "${yellow}Would you like to create a new torrent file?${white} "

if [[ "${stufftype}" == "BDISO" ]]; then

    echo -ne "[${cyan}Y${white}]es or [N]o "
    read responce
    case $responce in
        [yY] | [yY][Ee][Ss] | "" )  newtorrent=Yes ;;
        [nN] | [nN][Oo] )  newtorrent=No ;;
        *) newtorrent=Yes ;;
    esac

else

    echo -ne "[Y]es or [${cyan}N${white}]o "
    read responce
    case $responce in
        [yY] | [yY][Ee][Ss] )  newtorrent=Yes ;;
        [nN] | [nN][Oo] | "" )  newtorrent=No ;;
        *) newtorrent=No ;;
    esac

fi


if [[ "${newtorrent}" == "Yes" ]]; then
    echo -e "The script will create a new torrent"
elif [[ "${newtorrent}" == "No" ]]; then
    echo -e "The script will not create a new torrent"
fi

echo

}


# 准备
function _preparation() {

echo "${bold}If you want to stop, Press ${on_red}Ctrl+C${normal} ${bold}; or Press ${on_green}ENTER${normal} ${bold}to start${normal}" ;read input

clear
starttime=$(date +%s)
echo -e "Work start!"
echo

}


# 获取BD info
function _getinfo() {

if [[ "${bdscan}" == "auto" ]]; then
    echo -ne '1\n' | mono "${bdinfocli_path}" "${bdpath}" "${outputpath}"
elif [[ "${bdscan}" == "manual" ]]; then
    mono "${bdinfocli_path}" "${bdpath}" "${outputpath}"
fi

echo;echo

if [[ ! "${bdscan}" == "no" ]]; then
    sed -n '/QUICK SUMMARY/,//p' "${outputpath}/BDINFO.${file_title}.txt" > temptext
    count=`wc -l temptext | awk '{print $1-1}' `
    head -n $count temptext > "${outputpath}/bdinfo.quick.summary.txt"
    rm temptext

    sed -n '/DISC INFO/,/FILES/p' "${outputpath}/BDINFO.${file_title}.txt" > temptext
    count=`wc -l temptext | awk '{print $1-2}' `
    head -n $count temptext > "${outputpath}/bdinfo.main.summary.txt"
    rm temptext
fi

mv "${outputpath}/BDINFO.${file_title}.txt" "${outputpath}/bdinfo.txt"

}


# 获取截图
function _takescreenshots() {

# 确定时间间隔
if [[ "${duration2}" -ge 3600 ]]; then
    timestampsetting=166
elif [[ "${duration2}" -ge 1500 && "${duration2}" -lt 3600 ]]; then
    timestampsetting=66
elif [[ "${duration2}" -ge 600 && "${duration2}" -lt 1500 ]]; then
    timestampsetting=22
elif [[ "${duration2}" -lt 600 ]]; then
    timestampsetting=5
fi


# 截图
if [[ "${resolution}" == "1080p" ]] || [[ "${resolution}" == "input" ]]; then

    if [[ "${resolution}" == "1080p" ]]; then
        fenbianlv=1920x1080
    fi

    for c in {01..10}
        do
        i=`expr $i + $timestampsetting`
        timestamp=`date -u -d @$i +%H:%M:%S`
        ffmpeg -y -ss $timestamp -i "$main_m2ts_path" -vframes 1 -s $fenbianlv "${outputpath}/Screenshot${c}.png" >> /dev/null 2>&1
        echo Writing Screenshot$c.png from timestamp $timestamp
    done

elif [[ "${resolution}" == "auto" ]]; then

    for c in {01..10}
        do
        i=`expr $i + $timestampsetting`
        timestamp=`date -u -d @$i +%H:%M:%S`
        ffmpeg -y -ss $timestamp -i "$main_m2ts_path" -vframes 1 "${outputpath}/Screenshot${c}.png" >> /dev/null 2>&1
        echo -e Writing Screenshot$c.png from timestamp $timestamp
    done

fi

# 缩略图
if [[ $sstn == Yes ]]; then
    vcs "${main_m2ts_path}" -U0 -n 24 -c 4 -H200 -a 16/9 -o "${outputpath}/${file_title_clean}-thumbs.png"
fi


}





# 制作种子
function _mktorrent() {

if [[ "${newtorrent}" == "Yes" ]]; then
    mktorrent -v -p -l 24 -a "" -o "/etc/inexistence/04.Upload/${file_title_clean}/${file_title_clean}.torrent" "$bdpath"
fi

}





# 结尾
function _end() {

if [[ $stufftype == "BDISO" ]]; then
    umount "$bdisopath"
fi

endtime=$(date +%s) 
timeused=$(( $endtime - $starttime ))

clear
echo -e "${bold}Done. Files created in ${yellow}\"${outputpath}\"${normal}"
if [[ $timeused -gt 60 && $timeused -lt 3600 ]]; then
    timeusedmin=$(expr $timeused / 60)
    timeusedsec=$(expr $timeused % 60)
    echo -e "${bold}Time used: ${timeusedmin} min ${timeusedsec} sec${normal}"
elif [[ $timeused -ge 3600 ]]; then
    timeusedhour=$(expr $timeused / 3600)
    timeusedmin=$(expr $(expr $timeused % 3600) / 60)
    timeusedsec=$(expr $timeused % 60)
    echo -e "}Time used: ${timeusedhour} hour ${timeusedmin} min ${timeusedsec} sec${normal}"
else
   echo -e "${bold}}Time used: ${timeused} sec${normal}"
fi
echo

}






# 结构
_intro
_askpath
_stufftype
_askscan
_askresolution
_askmktorrent

_preparation
_getinfo
_takescreenshots
_mktorrent
_end
