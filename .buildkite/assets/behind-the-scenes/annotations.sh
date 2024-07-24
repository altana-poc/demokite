#!/bin/bash

set -euo pipefail

export TITLE=":pencil2: You generated some annotations! :sparkles:"
export SUBTITLE="<p>Check out the examples below to see what you can do using annotations.</p>"

export DETAILS=$(cat <<EOF
<p>
  You selected the <strong>:memo: Create some annotations</strong> option in the <strong>:thinking_face: What now?</strong> block step.

  This set build <a target="_blank" href="https://buildkite.com/docs/agent/v3/cli-meta-data">meta-data</a> (specifically, a key called <code>"choice"</code>) with a value of <code>"annotations"</code>.

  The <strong>:robot_face: Process Input</strong> step read the meta-data using a <code>buildkite-agent meta-data get "choice"</code> command, and determined that because the selected option was <code>"annotations"</code> that it should run a file called <code>annotations.sh</code>.

  In <code>annotations.sh</code>, we used the <code>buildkite-agent annotate</code> <a target="_blank" href="https://buildkite.com/docs/agent/v3/cli-annotate">CLI command</a> to generate the annotations you see on this build.
</p>
EOF
)
