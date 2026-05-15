apt_update() {
  if [ -n "${APT_CACHE_URL:-}" ]; then
    cat > /etc/apt/apt.conf.d/01proxy <<EOF
Acquire::http::Proxy "$APT_CACHE_URL";
Acquire::https::Proxy "false";
Acquire::http::Timeout "5";
Acquire::Retries "0";
EOF
    if apt-get update; then
      return 0
    fi
    echo "APT cache unavailable, retrying without proxy..." >&2
    rm -f /etc/apt/apt.conf.d/01proxy
  fi

  apt-get update
}

apt_install() {
  apt-get install -y --no-install-recommends "$@"
}

apt_clean() {
  rm -rf /var/lib/apt/lists/*
}
