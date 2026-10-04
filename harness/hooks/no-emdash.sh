#!/usr/bin/env bash

f=$1
emdash=$'\xe2\x80\x94'

offender=$(grep -m 1 -F -- "$emdash") || exit 0
trimmed=${offender#"${offender%%[![:space:]]*}"}

printf 'Em-dash added in %s:\n  %s\n%s\n' "$f" "$trimmed" \
  'Use a comma, colon, parentheses, or a full stop instead.'
