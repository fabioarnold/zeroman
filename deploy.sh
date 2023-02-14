#!/bin/bash
zig build -Doptimize=ReleaseSmall
scp -r index.html img js zig-out fabioarnold.de:/var/www/fabioarnold.de/games/zeroman
