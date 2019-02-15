sudo amazon-linux-extras install php7.2
curl -s -o composer-setup.php https://getcomposer.org/installer
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php