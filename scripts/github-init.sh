
#!/bin/bash

# Set the freshly created repo to the origin and push
git init
git add .
git commit -am "first commit"
git remote add origin https://github.com/abnerjacobsen/rootfs-alpine-3.6.git
git push -u origin master

