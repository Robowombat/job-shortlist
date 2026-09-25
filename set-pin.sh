#!/bin/bash
# Set a new dashboard PIN (hash only is stored in the HTML).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -ge 1 ]]; then
  PIN="$1"
else
  read -r -s -p "New PIN: " PIN
  echo
  read -r -s -p "Confirm PIN: " PIN2
  echo
  if [[ "$PIN" != "$PIN2" ]]; then
    echo "PINs do not match." >&2
    exit 1
  fi
fi

if [[ -z "${PIN// }" ]]; then
  echo "PIN cannot be empty." >&2
  exit 1
fi

HASH=$(PIN="$PIN" python3 - <<'PY'
import hashlib, os
print(hashlib.sha256(os.environ["PIN"].encode()).hexdigest())
PY
)

update_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  python3 - <<PY
from pathlib import Path
import re
path = Path("$file")
text = path.read_text()
new = re.sub(
    r'(const PIN_HASH =\s*\n\s*")[a-f0-9]{64}(")',
    r'\g<1>$HASH\g<2>',
    text,
    count=1,
)
if new == text:
    raise SystemExit(f"PIN_HASH not found in {path}")
path.write_text(new)
print(f"Updated {path}")
PY
}

update_file "$ROOT/index.html"
update_file "$ROOT/dashboard.html"

# Keep CV portfolio copy in sync if present
CV_DASH="/Users/petrafolk/Documents/Design/00 AI Projects/My CV : Portfolio/job-search/dashboard.html"
update_file "$CV_DASH"

echo
echo "PIN updated (hash only stored). Old PIN no longer works."
echo "To push the live site:"
echo "  git add index.html dashboard.html && git commit -m \"Update dashboard PIN\" && git push"
echo "Or from my-cv-portfolio: bash job-search/publish-dashboard.sh"
