#! /bin/bash

PSQL="psql --username=postgres --dbname=salon --no-align --tuples-only --quiet"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

show_services() {
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

show_services
echo
read SERVICE_ID_SELECTED

while true; do
  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  else
    SERVICE_NAME=""
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  echo -e "\nI could not find that service. What would you like today?"
  show_services
  echo
  read SERVICE_ID_SELECTED
done

echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_PHONE_ESCAPED=$(printf '%s' "$CUSTOMER_PHONE" | sed "s/'/''/g")
CUSTOMER_ID=$($PSQL -c "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE_ESCAPED';")

if [[ -z "$CUSTOMER_ID" ]]; then
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_NAME_ESCAPED=$(printf '%s' "$CUSTOMER_NAME" | sed "s/'/''/g")
  CUSTOMER_ID=$($PSQL -c "INSERT INTO customers(name, phone) VALUES ('$CUSTOMER_NAME_ESCAPED', '$CUSTOMER_PHONE_ESCAPED') RETURNING customer_id;")
else
  CUSTOMER_NAME=$($PSQL -c "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
fi

echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

SERVICE_TIME_ESCAPED=$(printf '%s' "$SERVICE_TIME" | sed "s/'/''/g")
$PSQL -c "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME_ESCAPED');"

echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."