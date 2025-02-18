#!/bin/bash

# Ensure the script stops if any command fails
set -e

echo "Starting Laravel cleanup..."

rm -fR bootstrap/cache/*
rm -fR storage/cache/*
rm -fR storage/framework/views/*
rm -fR storage/framework/sessions/*
rm -fR storage/app/public/*
rm -fR storage/logs/*

# Clear various caches and configurations
echo "Clearing cache..."
php artisan cache:clear

echo "Clearing config cache..."
php artisan config:clear

echo "Clearing route cache..."
php artisan route:clear

echo "Clearing view cache..."
php artisan view:clear

echo "Clearing event cache..."
php artisan event:clear

# Optionally rebuild the cache for better performance
echo "Rebuilding config cache..."
php artisan config:cache

echo "Rebuilding route cache..."
php artisan route:cache

echo "Rebuilding view cache..."
php artisan view:cache
#npm run build

# Optionally optimize autoload files (composer dump-autoload)
#echo "Optimizing Composer autoload..."
#composer dump-autoload -o

echo "Laravel cleanup completed successfully!"
composer dump-autoload