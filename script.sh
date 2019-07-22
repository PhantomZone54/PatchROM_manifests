#!/bin/bash

# Authors - 
#   Neil "regalstreak" Agarwal,
#   Harsh "MSF Jarvis" Shandilya,
#   Tarang "DigiGoon" Kagathara
# -----------------------------------------------------
# Modified by - Rokib Hasan Sagar @rokibhasansagar
# -----------------------------------------------------

# Definitions
DIR=$(pwd)
echo -en "Current directory is -- " && echo $DIR

PatchCode=$1
manifest_src=$2

echo -e "Making Update and Installing Apps"
sudo apt-get -qq update -y && sudo apt-get -qq upgrade -y
sudo apt-get -qq install tar wput -y

echo -e "ReEnable PATH and Set Repo & GHR"
mkdir ~/bin ; echo ~/bin || echo "bin folder creation error"
sudo curl --create-dirs -L -o /usr/local/bin/repo -O -L https://github.com/akhilnarang/repo/raw/master/repo
sudo cp .circleci/ghr ~/bin/ghr
sudo chmod a+x /usr/local/bin/repo
PATH=~/bin:/usr/local/bin:$PATH

echo -e "Github Authorization"
git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --system core.longpaths true || echo -e "core.lognpaths setting error"
git config --global color.ui true

echo -e "Main Function Starts HERE"
cd $DIR; mkdir $PatchCode; cd $PatchCode

echo -e "Initialize the Repo to Fetch the Data"
repo init -q -u $RepoLink -m $manifest_src --depth 1

echo -e "Syncing it up"
time repo sync -c -f -q --force-sync --no-clone-bundle --no-tags -j32
echo -e "\nSource Syncing done\n"

echo -en "The total size of the .repo folder is ---  "
du -sh .repo/ | awk '{print $1}'

mkdir -p ~/project/files/
export XZ_OPT=-9e

echo -e "Compressing files --- "
echo -e "Please be patient, this will take time"

time tar -cJf ~/project/files/$PatchCode-repofiles-$(date +%Y%m%d).tar.xz .repo

rm -rf .repo/
find . | grep .git | xargs rm -rf

echo -en "The total size of the checked-out files is ---  " && du -sh ../$PatchCode

time tar -cJf ~/project/files/$PatchCode-files-$(date +%Y%m%d).tar.xz *

echo -e "Final Compressed size of all the consolidated as-well-as checked-out files are --- "
du -sh ~/project/files/*

echo -e "Compression Done"

cd ~/project/files

echo -e "Taking MD5 Hash"
md5sum $PatchCode-repofiles-* > $PatchCode-repofiles-$(date +%Y%m%d).md5sum
cat $PatchCode-repofiles-*.md5sum
md5sum $PatchCode-files-* > $PatchCode-files-$(date +%Y%m%d).md5sum
cat $PatchCode-files-*.md5sum

tar -tJf $PatchCode-repofiles-*.tar.xz | awk '{print $6}' >> $PatchCode-repofiles-$(date +%Y%m%d).list
tar -tJf $PatchCode-files-*.tar.xz | awk '{print $6}' >> $PatchCode-files-$(date +%Y%m%d).list

cd $DIR && rm -rf $PatchCode

cd ~/project/files/

echo -e "Upload the Package to AFH"
for file in $PatchCode-*; do wput $file ftp://"$FTPUser":"$FTPPass"@"$FTPHost"//$PatchCode-Packages/ ; done

echo -e "Upload the Package to transfer.sh"
for file in $PatchCode-*; do curl --upload-file $file https://transfer.sh/ && echo '' ; done

echo -e "GitHub Release"
cd ~/project/
ghr -u $GitOrgName -t $GITHUB_TOKEN -b 'Releasing The Necessary File Package for PatchROM' $PatchCode ~/project/files/

echo -e "\nCongratulations! Job Done!"
