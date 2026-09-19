#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ha_config_dir="${HA_CONFIG_DIR:-${repo_root}/home-assistant}"
xiaomi_home_ref="${XIAOMI_HOME_REF:-v0.4.7}"
xiaomi_home_repo="https://github.com/XiaoMi/ha_xiaomi_home.git"
component_dir="${ha_config_dir}/custom_components/xiaomi_home"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf -- "${tmp_dir}"
}
trap cleanup EXIT

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install Xiaomi Home." >&2
  exit 1
fi

mkdir -p "${ha_config_dir}/custom_components"

echo "Downloading Xiaomi Home ${xiaomi_home_ref}..."
git clone --depth 1 --branch "${xiaomi_home_ref}" "${xiaomi_home_repo}" "${tmp_dir}/ha_xiaomi_home"

if [[ ! -d "${tmp_dir}/ha_xiaomi_home/custom_components/xiaomi_home" ]]; then
  echo "The selected Xiaomi Home ref does not contain custom_components/xiaomi_home." >&2
  exit 1
fi

rm -rf -- "${component_dir}"
cp -a "${tmp_dir}/ha_xiaomi_home/custom_components/xiaomi_home" "${component_dir}"

echo "Installed Xiaomi Home ${xiaomi_home_ref} into ${component_dir}"
echo "Restart Home Assistant with: docker compose restart homeassistant"
