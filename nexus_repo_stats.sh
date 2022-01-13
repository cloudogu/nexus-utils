#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

local orientConsoleJarPath=/opt/sonatype/nexus/lib/support/nexus-orient-console.jar
local dbUser=admin
local dbPassword=admin
local repoStatsOutputPath=/tmp/nexusRepoStatsOutput.txt

java -jar "${orientConsoleJarPath}" \
  "CONNECT plocal:/var/lib/nexus/db/component "${dbUser}" "${dbPassword}"; SELECT bucket.repository_name as repo, count(*) as assetCount, sum(size) as assetSize FROM asset GROUP BY bucket;" \
  > "${repoStatsOutputPath}"

if ! grep "0 item(s) found" "${repoStatsOutputPath}" ; then
  echo "No repositories found or an error occurred:"
  tail -n1 "${repoStatsOutputPath}" # might exit 1 as well
  exit 1
fi

# cat ; remove non-stats lines ; remove ascii table art; squeeze fixed spaces into one ; remove table headers; remove empty lines; remove superfluous line | format output
cat "${repoStatsOutputPath}" | sed 's/^\([^|+]\+\)$//' | grep -v "+-" | sed 's/ //g' | grep -v asset | sed '/^[[:space:]]*$/d' | tail -n -2 | awk -F "|" '{print $3,";",$4, "assets",";",$5, "Bytes"}'
 
