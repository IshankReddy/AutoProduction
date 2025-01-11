#!/bin/bash

while true; do
  echo "\n========= Operator Menu ========="
  echo "1. Status Uvicorn"
  echo "2. Check Status of Apache"
  echo "3. Start Apache"
  echo "4. Stop Apache"
  echo "5. Reload Apache"
  echo "6. Start Uvicorn Server"
  echo "7. Stop Uvicorn Server"
  echo "8 . Update Vector DB"
  echo "9. Exit Menu"
  echo "================================="

  read -p "Enter your choice: " choice

  case $choice in
    1)
      echo "Checking Uvicorn status..."
      if pgrep -f "uvicorn main:app" > /dev/null; then
        echo "Uvicorn server is running."
      else
        echo "Uvicorn server is not running."
      fi
      ;;

    2)
      echo "Checking Apache status..."
      sudo systemctl status apache2
      ;;

    3)
      echo "Starting Apache..."
      if sudo systemctl start apache2; then
        echo "Apache started successfully."
      else
        echo "Failed to start Apache."
      fi
      ;;

    4)
      echo "Stopping Apache..."
      if sudo systemctl stop apache2; then
        echo "Apache stopped successfully."
      else
        echo "Failed to stop Apache."
      fi
      ;;

    5)
      echo "Reloading Apache..."
      if sudo systemctl daemon-reload; then
        echo "Apache reloaded successfully."
      else
        echo "Failed to reload Apache."
      fi
      ;;

    6)
      echo "Starting Uvicorn server..."
      conda activate Production && log_msg $? "activate Conda environment"
      nohup uvicorn main:app --reload --host 0.0.0.0 --port 8080 &> uvicorn.log &
      if [ $? -eq 0 ]; then
        echo "Uvicorn server started successfully. Logs are in uvicorn.log."
      else
        echo "Failed to start Uvicorn server."
      fi
      ;;

    7)
      echo "Stopping Uvicorn server..."
      if pkill -f "uvicorn main:app"; then
        echo "Uvicorn server stopped successfully."
      else
        echo "Failed to stop Uvicorn server or it is not running."
      fi
      ;;

    8)
      echo "Updating Vector DB..."
      conda activate Production && log_msg $? "activate Conda environment"
      cd /kaviwebdesign/BACKEND
      python data_vectorizer.py
      if [ $? -eq 0 ]; then
        echo "Vector DB update started successfully."
      else
        echo "Failed to start Vector DB update."
      fi
      ;;

    9)
      echo "Exiting menu. Goodbye!"
      break
      ;;

    *)
      echo "Invalid choice. Please select a valid option."
      ;;
  esac

done
