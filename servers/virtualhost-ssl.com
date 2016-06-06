<VirtualHost *:80>
    ServerName domain.com
    ServerAlias www.domain.com
    Redirect permanent / https://domain.com
</VirtualHost>

#a2enmod ssl
# https://pentest-tools.com/network-vulnerability-scanning/openssl-heartbleed-scanner
# check for openssl >= 1.0.1e-2+deb7u21
<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerAdmin email@email.com
        ServerName domain.com
        DocumentRoot "/var/www/htdocs/domain"

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        #   SSL Engine Switch:
        #   Enable/Disable SSL for this virtual host.
        SSLEngine on

        #   A self-signed (snakeoil) certificate can be created by installing
        #   the ssl-cert package. See
        #   /usr/share/doc/apache2/README.Debian.gz for more info.
        #   If both key and certificate are stored in the same file, only the
        #   SSLCertificateFile directive is needed.
        SSLCertificateFile    /home/some/cert.pem

        SSLCertificateKeyFile /home/some/privkey.pem


        #   Server Certificate Chain:
        #   Point SSLCertificateChainFile at a file containing the
        #   concatenation of PEM encoded CA certificates which form the
        #   certificate chain for the server certificate. Alternatively
        #   the referenced file can be the same as SSLCertificateFile
        #   when the CA certificates are directly appended to the server
        #   certificate for convinience.
        SSLCertificateChainFile /home/some/chain.pem


        <FilesMatch "\.(cgi|shtml|phtml|php)$">
            SSLOptions +StdEnvVars
        </FilesMatch>
        <Directory /usr/lib/cgi-bin>
            SSLOptions +StdEnvVars
        </Directory>

        BrowserMatch "MSIE [2-6]" \
            nokeepalive ssl-unclean-shutdown \
            downgrade-1.0 force-response-1.0
        
        # MSIE 7 and newer should be able to use keepalive
        BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown


        # Disable directory listings
        # show 403 when you try to access a directory that doesn't have an index file
        # https://pentest-tools.com/website-vulnerability-scanning/discover-hidden-directories-and-files
        Options -Indexes

        # POODLE attack
        # https://pentest-tools.com/network-vulnerability-scanning/ssl-poodle-scanner
        SSLProtocol all -SSLv2 -SSLv3

        # Methods allowed
        RewriteEngine On
        RewriteCond %{REQUEST_METHOD} !^(GET|HEAD)
        RewriteRule .* - [R=405,L]

        # Error page web server version disclosure
        ErrorDocument 404 /404.html
        ErrorDocument 401 "Unauthorized"
        ErrorDocument 403 "Forbidden"
        ErrorDocument 500 "Internal server error"

        # Clickjacking: X-Frame-Options header
        # a2enmod headers
        Header set X-Frame-Options SAMEORIGIN

    </VirtualHost>  
</IfModule>
