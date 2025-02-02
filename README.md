# Termux-phpmyadmin-installer

This script simplifies the installation and management of phpMyAdmin on Termux for Android. It automates the process of configuring phpMyAdmin and sets up convenient `pma start` and `pma stop` commands. It also checks for a pre-existing MariaDB installation.

## Features

* Installs phpMyAdmin.
* Installs PHP, required for phpMyAdmin.
* Configures phpMyAdmin (using cookie authentication by default - **INSECURE FOR PRODUCTION**).
* Creates `pma start` and `pma stop` aliases for easy server management.
* Checks for existing MariaDB installation before proceeding.

## Installation

Update & Upgrade Packages
```
apt update && apt upgrade -y
```

Install Required Packages
```
apt install git -y && apt install bash -y
```

Installation
```
cd $Home && git clone https://github.com/y-nabeelxd/Termux-phpmyadmin-installer && clear && cd Termux-phpmyadmin-installer && chmod +x install.sh && bash install.sh && cd $Home && rm -rf Termux-phpmyadmin-installer
```



**Usage**

Starting phpMyAdmin
```
pma start
```
This command starts the PHP development server with phpMyAdmin on port 8081 in the background. You can then access phpMyAdmin in your browser (within Termux or using a localhost port forwarding solution if accessing from another device on your network) at `http://localhost:8081`.

Stopping phpMyAdmin
```
pma stop
```
This command stops the phpMyAdmin server.


### Important Security Considerations
* **The default cookie authentication is highly insecure and is only recommended for development or testing purposes in Termux.** For any production or publicly accessible environment, you must configure proper authentication. See the instructions below on how to do this.
* **Do not expose phpMyAdmin directly to the internet.** phpMyAdmin is a powerful tool but can be a security risk if not properly secured. If you need to access it remotely, use a secure method such as SSH tunneling or a VPN.


### How to change to config authentication (Recommended for production)
Edit phpMyAdmin's config file:
```
nano $PREFIX/share/phpmyadmin/config.inc.php
```

Modify the authentication settings (replace with your chosen credentials):
Change this:
```
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['AllowNoPassword'] = true; // REMOVE THIS LINE - IT IS VERY INSECURE
```

To this:
```
$cfg['Servers'][$i]['auth_type'] = 'config';
$cfg['Servers'][$i]['user'] = 'your_mariadb_user';      // Replace with your MariaDB user
$cfg['Servers'][$i]['password'] = 'your_mariadb_password';  // Replace with your MariaDB password
```
Make sure to replace `your_mariadb_user` and `your_mariadb_password` with the actual credentials of a MariaDB user that has the necessary privileges.  **Do not use the root user.**  Create a separate user for phpMyAdmin.

Save the config file.


### How to create a MariaDB user (if you don't have one)
Connect to MariaDB:
```
mysql -u root -p
```

Create a new user (replace `pma_user` and `pma_password` with your chosen credentials):
```
CREATE USER 'pma_user'@'localhost' IDENTIFIED BY 'pma_password';
```

Grant privileges to the new user (adjust privileges as needed):
```
GRANT ALL PRIVILEGES ON *.* TO 'pma_user'@'localhost' WITH GRANT OPTION;  -- For full access.  Restrict privileges as needed for your setup.
FLUSH PRIVILEGES;
```

Exit the MariaDB shell:
```
exit
```


### Troubleshooting
`Sorry, MariaDB is not installed.`: This means the script couldn't find a MariaDB installation. Visit Here. [MySQL-MariaDB-Termux-Installer](https://github.com/y-nabeelxd/MySQL-MariaDB-Termux-Installer)

**Connection issues**: Double-check that the MariaDB server is running (`mysqld_safe &`) and that the password and username you're using in `config.inc.php` are correct


### Disclaimer
This script is provided for educational purposes and for simplifying local development in Termux.  Using cookie authentication or the root user for phpMyAdmin is a significant security risk and is not recommended for production environments.  Please follow the security best practices outlined above to protect your data.  The author is not responsible for any data loss or security breaches that may occur as a result of using this script.
