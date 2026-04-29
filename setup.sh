#!/usr/bin/env bash

CRUSH_FTP_BASE_DIR="/var/opt/CrushFTP11"

PUID=${PUID:-0}
PGID=${PGID:-0}

# --- 1. Execution Context Logic ---
if [ "$PUID" -ne 0 ]; then
    echo "Configured for non-root execution (UID: ${PUID}, GID: ${PGID})."
    
    if ! getent group crushgroup >/dev/null 2>&1; then
        groupadd -g ${PGID} crushgroup
    fi

    if ! id -u crushuser >/dev/null 2>&1; then
        useradd -u ${PUID} -g ${PGID} -m -s /bin/bash crushuser
    fi

    # Fix permissions so the new user can access the folder
    chown -R ${PUID}:${PGID} /var/opt/ /tmp/CrushFTP11.zip 2>/dev/null
    
    # Set the execution prefix
    RUN_AS="su-exec crushuser"
else
    echo "Configured for standard root execution."
    RUN_AS=""
fi

# --- 2. Extraction Logic ---
if [[ -f "${CRUSH_FTP_BASE_DIR}/CrushFTP.jar" ]]; then
    echo "CrushFTP already installed at ${CRUSH_FTP_BASE_DIR}. Skipping extraction."
else
    if [[ -f /tmp/CrushFTP11.zip ]] ; then
        echo "Unzipping CrushFTP..."
        # If RUN_AS is empty, this just runs 'unzip'. If not, it runs 'su-exec crushuser unzip'
        $RUN_AS busybox unzip -o -q /tmp/CrushFTP11.zip -d /var/opt/
        rm -f /tmp/CrushFTP11.zip
    fi
fi

# --- 3. Admin Setup Logic ---
ORIGINAL_CRUSH_ADMIN_USER="${CRUSH_ADMIN_USER:-}"
ORIGINAL_CRUSH_ADMIN_PASSWORD="${CRUSH_ADMIN_PASSWORD:-}"

if [ -z "${CRUSH_ADMIN_USER:-}" ]; then
    CRUSH_ADMIN_USER=crushadmin
fi

if [ -n "${ORIGINAL_CRUSH_ADMIN_PASSWORD}" ]; then
    DISPLAYED_PASSWORD="NOT DISPLAYED!"
elif [ -f "${CRUSH_FTP_BASE_DIR}/admin_user_set" ]; then
    CRUSH_ADMIN_PASSWORD="NOT DISPLAYED!"
    DISPLAYED_PASSWORD="NOT DISPLAYED!"
elif [ -n "${ORIGINAL_CRUSH_ADMIN_USER}" ]; then
    CRUSH_ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | fold -w 16 | head -n 1)
    DISPLAYED_PASSWORD="NOT DISPLAYED!"
else
    CRUSH_ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | fold -w 16 | head -n 1)
    DISPLAYED_PASSWORD="${CRUSH_ADMIN_PASSWORD}"
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
    cd "${CRUSH_FTP_BASE_DIR}" && $RUN_AS java -jar "${CRUSH_FTP_BASE_DIR}/CrushFTP.jar" -a "${CRUSH_ADMIN_USER}" "${CRUSH_ADMIN_PASSWORD}"
    touch "${CRUSH_FTP_BASE_DIR}/admin_user_set"
    
    if [ "$PUID" -ne 0 ]; then
        chown ${PUID}:${PGID} "${CRUSH_FTP_BASE_DIR}/admin_user_set"
    fi
else
    echo "Admin user already exists or admin_user_set marker present; skipping admin creation."
fi

# --- 4. Start the Server ---
chmod +x "${CRUSH_FTP_BASE_DIR}/crushftp_init.sh"
$RUN_AS "${CRUSH_FTP_BASE_DIR}/crushftp_init.sh" start

until [ -f "${CRUSH_FTP_BASE_DIR}/prefs.XML" ]; do
     sleep 1
done

echo "########################################"
echo "# User:       ${CRUSH_ADMIN_USER}"
echo "# Password:   ${DISPLAYED_PASSWORD}"
echo "########################################"

while true; do sleep 86400; done
