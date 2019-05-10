#!/usr/bin/env bash
set -euo pipefail

exec /run/current-system/sw/bin/rspamc -h /run/rspamd/worker-controller.socket learn_spam
