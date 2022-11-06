#!/bin/bash
zig build -Drelease-small=true
scp -r index.html img js zig-out fabioarnold.de:/var/www/fabioarnold.de/games/zeroman
