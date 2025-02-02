#!/bin/bash

# --- Configuration ---
PMA_PORT="8081"
PMA_DIR="$PREFIX/share/phpmyadmin"
PHP_INI="$PREFIX/etc/php/php.ini"
PMA_PID_FILE="$HOME/.pma_pid"
# ---------------------

# --- Check MariaDB Installation ---
if ! dpkg -s mariadb &> /dev/null; then
    echo "Sorry, MariaDB is not installed."
    echo "Visit: https://github.com/y-nabeelxd/MySQL-MariaDB-Termux-Installer"
    exit 1
fi

# --- Install and Configure ---

apt install -y php phpmyadmin

# ... (MariaDB root password prompt - same as before)

export MYSQL_PWD="$MARIADB_ROOT_PASSWORD"
cat << EOF > "$PMA_DIR/config.inc.php"
<?php
\$i++;

/* Authentication type */
\$cfg['Servers'][$i]['auth_type'] = 'config'; // Use config authentication

/* Server parameters */
\$cfg['Servers'][$i]['host'] = 'localhost:3306';
\$cfg['Servers'][$i]['compress'] = false;

/* Authentication credentials (using root - INSECURE FOR PRODUCTION) */
\$cfg['Servers'][$i]['user'] = 'root';       // Using root - NOT RECOMMENDED FOR PRODUCTION
\$cfg['Servers'][$i]['password'] = '$MARIADB_ROOT_PASSWORD';  // Using root password - INSECURE FOR PRODUCTION

/**
 * phpMyAdmin configuration storage settings. (Optional - uncomment if needed)
 */
// \$cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';
// \$cfg['Servers'][$i]['controlhost'] = '';
// \$cfg['Servers'][$i]['controlport'] = '';
// \$cfg['Servers'][$i]['controluser'] = '';
// \$cfg['Servers'][$i]['controlpass'] = '';

?>
EOF

unset MYSQL_PWD

# --- PHP Configuration ---
mkdir -p $(dirname "$PHP_INI")
echo 'error_reporting = E_ALL & ~E_NOTICE & ~E_DEPRECATED' > "$PHP_INI"

# --- Determine the correct bin directory ---
if [ -w "$PREFIX/bin" ]; then
  BIN_DIR="$PREFIX/bin"
else
  BIN_DIR="$HOME/bin"
  mkdir -p "$BIN_DIR" # Create it if it doesn't exist
  export PATH="$BIN_DIR:$PATH" # Add to PATH
fi


cat << EOF > "$BIN_DIR/pma"
#!/bin/bash

# --- Configuration ---
PMA_PORT="$PMA_PORT"
PMA_DIR="$PMA_DIR"
PHP_INI="$PHP_INI"
PMA_PID_FILE="$HOME/.pma_pid"
# ---------------------

pma_start() {
  if [ -f "\$PMA_PID_FILE" ]; then
    PMA_PID=\$(cat "\$PMA_PID_FILE")
    if ps -p "\$PMA_PID" > /dev/null; then
      echo "phpMyAdmin is already running on http://localhost:\$PMA_PORT (PID: \$PMA_PID)"
      return 0
    fi
    rm "\$PMA_PID_FILE"
  fi

  php -S localhost:"\$PMA_PORT" -t "\$PMA_DIR" > /dev/null 2>&1 &
  PMA_PID=\$!
  echo "\$PMA_PID" > "\$PMA_PID_FILE"
  echo "phpMyAdmin started on http://localhost:\$PMA_PORT (PID: \$PMA_PID)"
}

pma_stop() {
  if [ -f "\$PMA_PID_FILE" ]; then
    PMA_PID=\$(cat "\$PMA_PID_FILE")
    if kill "\$PMA_PID" 2>/dev/null; then
      rm "\$PMA_PID_FILE"
      echo "phpMyAdmin stopped (PID: \$PMA_PID)"
    else
      rm "\$PMA_PID_FILE"
      echo "Could not stop phpMyAdmin (PID: \$PMA_PID). Process might have already exited."
    fi
  else
    echo "phpMyAdmin is not running."
  fi
}

if [ "\$1" == "start" ]; then
  pma_start
elif [ "\$1" == "stop" ]; then
  pma_stop
else
  echo "Usage: pma {start|stop}"
  exit 1
fi
EOF

chmod +x "$BIN_DIR/pma"

if [ -f ~/.zshrc ]; then
  CONFIG_FILE=~/.zshrc
else
  CONFIG_FILE=~/.bashrc
fi

echo "alias pma='$BIN_DIR/pma'" >> "$CONFIG_FILE"
source "$CONFIG_FILE"

echo "phpMyAdmin installation complete."
echo "Run 'pma start' to start the server."
echo "Run 'pma stop' to stop the server."

