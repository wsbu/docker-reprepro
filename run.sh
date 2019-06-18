#!/bin/bash

set -e

# Create the reprepro user
if [[ -z "${REPREPRO_UID}" ]] ; then
  REPREPRO_UID=1000
fi
if ! grep "${REPREPRO_USERNAME}" /etc/passwd >/dev/null 2>&1 ; then
  echo "=> User '${REPREPRO_USERNAME}' use does not exist."
  echo "   Creating user '${REPREPRO_USERNAME}' with uid=${REPREPRO_UID}"
  adduser \
      --system \
      --group \
      --shell /bin/bash \
      --uid "${REPREPRO_UID}" \
      --disabled-password \
      --no-create-home \
      "${REPREPRO_USERNAME}"
else
  echo "=> User '${REPREPRO_USERNAME}' already exists. Skipping new user creation."
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
  # Skip any non-directory entries - we only care about directories
  if [[ ! -d "${base_path}" ]] ; then
    continue
  fi

  echo "=> Configuring repo ${base_path}..."

  # Ensure some extra directories exist
  mkdir -p "${base_path}"/{tmp,incoming,conf}

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
  chown -R "${REPREPRO_USERNAME}:${REPREPRO_USERNAME}" "${base_path}"
done

# Ensure reprepro can SSH in via key authentication
if [[ -z "${REPREPRO_SSH_KEY_FILE_PATH}" ]] ; then
  echo "=> ERROR: No SSH public key given for ${REPREPRO_USERNAME} user."
  echo "   Please provide a public key to SSH in as the ${REPREPRO_USERNAME} user by"
  echo "   specifying the REPREPRO_SSH_KEY_FILE_PATH environment variable."
  exit 1
elif ! grep "Match User ${REPREPRO_USERNAME}" /etc/ssh/sshd_config > /dev/null ; then
  echo "Match User ${REPREPRO_USERNAME}" >> /etc/ssh/sshd_config
  echo "    AuthorizedKeysFile ${REPREPRO_SSH_KEY_FILE_PATH}"
fi

echo "=> Starting SSH server..."
mkdir -p /run/sshd
exec /usr/sbin/sshd -D -e
