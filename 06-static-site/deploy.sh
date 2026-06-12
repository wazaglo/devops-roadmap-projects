#!/bin/bash
rsync -avz --delete static-site/ admin@$1:/var/www/html/