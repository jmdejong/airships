#!/bin/bash
cd "`dirname "$0"`/.."

godot --export-debug --headless Web exports/web/index.html

sed --in-place 's/if (!Features.isSecureContext())/if (false)/g' "`dirname "$0"`/../exports/web/index.js"
sed --in-place 's/ctx.audioWorklet.addModule(path)/null/g' "`dirname "$0"`/../exports/web/index.js"
sed --in-place 's/await GodotAudio.audioPositionWorkletPromise;//g' "`dirname "$0"`/../exports/web/index.js"
