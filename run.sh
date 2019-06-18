#!/bin/bash

set -e

# Create the reprepro user
if [[ -z "${REPREPRO_UID}" ]] ; then
  REPREPRO_UID=1000
fi
if ! grep "${USER_NAME}" /etc/passwd >/dev/null 2>&1 ; then
  adduser \
      --system \
      --group \
      --shell /bin/bash \
      --uid "${REPREPRO_UID}" \
      --disabled-password \
      --no-create-home \
      reprepro
fi

# Ensure the GPG configuration directory exists
if [[ ! -d "${GNUPGHOME}" ]]; then
  echo "=> /data/.gnupg directory does not exist:"
  echo "   Please include this directry in the Docker volume"
  echo "   with an appropriately configured GPG key."
  exit 1
fi

# Ensure each distribution is configured
for base_path in /data/*; do
  echo "=> Configuring repo ${base_path}..."

  # Ensure some extra directories exist
  mkdir -p "${base_path}/{tmp,incoming,conf}"

  # Create the options file
  options_file="${base_path}/conf/options"
  if [[ ! -e "${options_file}" ]]; then
    cat <<EOF >"${options_file}"
verbose
basedir ${base_path}
gnupghome ${GNUPGHOME}
ask-passphrase
EOF
  fi

  # Make sure there are no root-owned files in there
  chown -R reprepro:reprepro "${base_path}"
done

# Ensure reprepro can SSH in via key authentication
if [[ -z "${REPREPRO_SSH_KEY_FILE_PATH}" ]] ; then
  echo "=> ERROR: No SSH public key given for reprepro user."
  echo "   Please provide a public key to SSH in as the reprepro user by"
  echo "   specifying the REPREPRO_SSH_KEY_FILE_PATH environment variable."
  exit 1
elif ! grep 'Match User reprepro' /etc/ssh/sshd_config ; then
  echo "Match User reprepro" >> /etc/ssh/sshd_config
  echo "    AuthorizedKeysFile ${REPREPRO_SSH_KEY_FILE_PATH}"
fi

echo "=> Starting SSH server..."
exec /usr/sbin/sshd -D -e
