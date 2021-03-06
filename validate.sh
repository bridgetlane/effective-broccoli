#/usr/bin/env bash

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  echo -e "---> only validate changelog on PRs"
  exit 0
fi

# verify CHANGELOG.md exists
echo "---> Checking for CHANGELOG.md"
if [[ ! -f "CHANGELOG.md"  ]]
then
    echo -e "CHANGELOG.md does not exist? Weird..."
    exit 1
fi


# verify CHANGELOG.md has a version that has been updated
echo "---> Checking for update to version in CHANGELOG.md"
version_line=`git diff master..${TRAVIS_PULL_REQUEST_SHA} CHANGELOG.md | grep '^+# '`

if [[ -z "${version_line}"  ]]; then
    echo -e "CHANGELOG.md must have an updated version number."
    exit 1
fi

# check that the version number provided is properly formatted
echo "---> Checking for properly formatted version in CHANGELOG.md"
version_num=`echo ${version_line} | grep -Eo [0-9].*[0-9]*.[0-9]*`
if [[ -z "${version_num}"  ]]; then
    echo -e "CHANGELOG.md must have a properly formatted version number."
    exit 1
fi

# check that the version number was actually increased
echo "---> Checking that the version number was incremented"

# split branch version into an array
IFS='.' eval 'branch_version_split=($version_num)'
git checkout master || { echo 'FAIL: error checking out the master branch' ; exit 1; }
# split master version into an array
master_version_num=`grep -m1 '^#' CHANGELOG.md | grep -Eo [0-9].*[0-9]*.[0-9]*`
IFS='.' eval 'master_version_split=($master_version_num)'
git checkout $BRANCH_NAME || { echo 'FAIL: error checking back out the current branch ' ; exit 1; }

# check major
if [ ${branch_version_split[0]} -eq ${master_version_split[0]} ];then
    # check minor
    if [ ${branch_version_split[1]} -eq ${master_version_split[1]} ];then
      # check patch
      if [ ${branch_version_split[2]} -eq ${master_version_split[2]} ];then
        echo -e "CHANGELOG.md version must be incremented. master version: $master_version_num, $BRANCH_NAME version: $version_num"
        exit 1
      elif [ ${branch_version_split[2]} -lt ${master_version_split[2]} ];then
        echo -e "CHANGELOG.md version must be incremented. master version: $master_version_num, $BRANCH_NAME version: $version_num"
        exit 1
      fi
    elif [ ${branch_version_split[1]} -lt ${master_version_split[1]} ];then
      echo -e "CHANGELOG.md version must be incremented. master version: $master_version_num, $BRANCH_NAME version: $version_num"
      exit 1
    fi
elif [ ${branch_version_split[0]} -lt ${master_version_split[0]} ];then
  echo -e "CHANGELOG.md version must be incremented. master version: $master_version_num, $BRANCH_NAME version: $version_num"
  exit 1
fi
