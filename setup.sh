#!/usr/bin/env bash

CRUSH_FTP_BASE_DIR="/var/opt/CrushFTP11"

# If CrushFTP is already present, skip extraction
if [[ -f "${CRUSH_FTP_BASE_DIR}/CrushFTP.jar" ]]; then
    echo "CrushFTP already installed at ${CRUSH_FTP_BASE_DIR}. Skipping extraction."
else
    if [[ -f /tmp/CrushFTP11.zip ]] ; then
        echo "Unzipping CrushFTP..."
        unzip -o -q /tmp/CrushFTP11.zip -d /var/opt/
        rm -f /tmp/CrushFTP11.zip
    fi
fi

# Defaults
if [ -z "${CRUSH_ADMIN_USER:-}" ]; then
    CRUSH_ADMIN_USER=crushadmin
fi

if [ -z "${CRUSH_ADMIN_PASSWORD:-}" ] && [ -f "${CRUSH_FTP_BASE_DIR}/admin_user_set" ]; then
    # Admin already set previously; don't try to show or re-generate password
    CRUSH_ADMIN_PASSWORD="NOT DISPLAYED!"
elif [ -z "${CRUSH_ADMIN_PASSWORD:-}" ] && [ ! -f "${CRUSH_FTP_BASE_DIR}/admin_user_set" ]; then
    CRUSH_ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | fold -w 16 | head -n 1)
fi

if [ -z "${CRUSH_ADMIN_PROTOCOL:-}" ]; then
    CRUSH_ADMIN_PROTOCOL=http
fi

if [ -z "${CRUSH_ADMIN_PORT:-}" ]; then
    CRUSH_ADMIN_PORT=8080
fi

# Create admin only if the admin user directory DOES NOT exist AND admin_user_set does not exist.
if [[ ! -d "${CRUSH_FTP_BASE_DIR}/users/MainUsers/${CRUSH_ADMIN_USER}" && ! -f "${CRUSH_FTP_BASE_DIR}/admin_user_set" ]]; then
    echo "Creating default admin..."
    cd "${CRUSH_FTP_BASE_DIR}" && java -jar "${CRUSH_FTP_BASE_DIR}/CrushFTP.jar" -a "${CRUSH_ADMIN_USER}" "${CRUSH_ADMIN_PASSWORD}"
    touch "${CRUSH_FTP_BASE_DIR}/admin_user_set"
else
    echo "Admin user already exists or admin_user_set marker present; skipping admin creation."
fi

# Ensure the init script is executable and start the server
chmod +x "${CRUSH_FTP_BASE_DIR}/crushftp_init.sh"
"${CRUSH_FTP_BASE_DIR}/crushftp_init.sh" start

# Wait for prefs.XML to appear in the CrushFTP directory
until [ -f "${CRUSH_FTP_BASE_DIR}/prefs.XML" ]; do
     sleep 1
done

echo "########################################"
echo "# User:		${CRUSH_ADMIN_USER}"
echo "# Password:	${CRUSH_ADMIN_PASSWORD}"
echo "########################################"

# Keep container running
while true; do sleep 86400; done
