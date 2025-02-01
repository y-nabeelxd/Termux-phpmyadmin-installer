#!/bin/bash

# --- Configuration ---
PMA_PORT="8081"
PMA_DIR="$PREFIX/share/phpmyadmin"
PHP_INI="$PREFIX/etc/php/php.ini"
PMA_PID_FILE="$HOME/.pma_pid"
# ---------------------

if ! dpkg -s mariadb-server &> /dev/null; then
    echo "Sorry, MariaDB is not installed."
    echo "Visit: https://github.com/y-nabeelxd/MySQL-MariaDB-Termux-Installer"
    exit 1
fi

# --- Install and Configure ---
apt install -y php phpmyadmin

while true; do
  read -s -p "Enter MariaDB root password: " MARIADB_ROOT_PASSWORD
  echo ""

  if mysql -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
    break
  else
    echo "Incorrect password. Please try again."
  fi
done

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

pma_start() {
  if [ -f "$PMA_PID_FILE" ]; then
    PMA_PID=$(cat "$PMA_PID_FILE")
    if ps -p "$PMA_PID" > /dev/null; then
      echo "phpMyAdmin is already running on http://localhost:${PMA_PORT} (PID: $PMA_PID)"
      return 0
    fi
    rm "$PMA_PID_FILE"
  fi

  php -S localhost:${PMA_PORT} -t "$PMA_DIR" > /dev/null 2>&1 &
  PMA_PID=$!
  echo "$PMA_PID" > "$PMA_PID_FILE"
  echo "phpMyAdmin started on http://localhost:${PMA_PORT} (PID: $PMA_PID)"
}

pma_stop() {
  if [ -f "$PMA_PID_FILE" ]; then
    PMA_PID=$(cat "$PMA_PID_FILE")
    if kill "$PMA_PID" 2>/dev/null; then
      rm "$PMA_PID_FILE"
      echo "phpMyAdmin stopped (PID: $PMA_PID)"
    else
      rm "$PMA_PID_FILE"
      echo "Could not stop phpMyAdmin (PID: $PMA_PID). Process might have already exited."
    fi
  else
    echo "phpMyAdmin is not running."
  fi
}

echo "alias pma_start='pma_start'" >> ~/.bashrc
echo "alias pma_stop='pma_stop'" >> ~/.bashrc
source ~/.bashrc

echo "phpMyAdmin installation complete."
echo "Run 'pma start' to start the server."
echo "Run 'pma stop' to stop the server."
