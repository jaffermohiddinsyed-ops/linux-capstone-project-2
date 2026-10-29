#!/bin/bash

# Nginx Service Management Script
ACTION="$1"

if [ -z "$ACTION" ]; then
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
fi

case "$ACTION" in
    start)
        echo "Starting Nginx..."
        if sudo systemctl start nginx && systemctl is-active --quiet nginx; then
            echo "Nginx started successfully"
        else
            echo "Failed to start Nginx"
            exit 1
        fi
        ;;

    stop)
        echo "Stopping Nginx..."
        if sudo systemctl stop nginx && ! systemctl is-active --quiet nginx; then
            echo "Nginx stopped successfully"
        else
            echo "Failed to stop Nginx"
            exit 1
        fi
        ;;

    restart)
        echo "Restarting Nginx..."
        if sudo systemctl restart nginx && systemctl is-active --quiet nginx; then
            echo "Nginx restarted successfully"
        else
            echo "Failed to restart Nginx"
            exit 1
        fi
        ;;

    status)
        systemctl status nginx --no-pager
        ;;

    *)
        echo "Invalid action: $ACTION"
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
