
#!/bin/bash
yum update -y
yum install httpd -y
service httpd start
chkconfig httpd on
echo "<h1>Shivam Corp Welcomes You</h1>" > /var/www/html/index.html