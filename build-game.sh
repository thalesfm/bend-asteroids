#!/usr/bin/env bash
cp ./src/api.bend ./bend-game/api.bend
bend gen-hvm ./bend-game/main.bend > main.hvm
rm ./bend-game/api.bend
