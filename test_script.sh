#! /usr/bin/env bash

clear
echo -e "\ntry to sign in with unregistered user"
curl -X POST "http://127.0.0.1:8000/signIn?password=password&name=Alice" -H  "accept: application/json"
sleep 0.5

echo -e "\n\ntry to sign up with invalid too short password"
curl -X POST "http://127.0.0.1:8000/signUp?password=pw&name=Alice&country=Germany" -H  "accept: application/json"
sleep 0.5

echo -e "\n\nsign up user alice:password"
curl -X POST "http://127.0.0.1:8000/signUp?password=password&name=alice&country=Germany" -H  "accept: application/json"
sleep 0.5

echo -e "\n\ntry to sign up with username already in use"
curl -X POST "http://127.0.0.1:8000/signUp?password=12345&name=alice&country=Germany" -H  "accept: application/json"
sleep 0.5

echo -e "\n\ntry to sign up without parameter country"
curl -X POST "http://127.0.0.1:8000/signUp?password=12345&name=bob" -H  "accept: application/json"
sleep 0.5

echo -e "\n\nsign up user bob:12345"
curl -X POST "http://127.0.0.1:8000/signUp?password=12345&name=bob&country=USA" -H  "accept: application/json"
sleep 0.5

echo -e "\n\ntry to sign in with invalid password"
curl -X POST "http://127.0.0.1:8000/signIn?password=passwort&name=alice" -H  "accept: application/json"
sleep 0.5

echo -e "\n\nsign in user alice:password"
curl -X POST "http://127.0.0.1:8000/signIn?password=password&name=Alice" -H  "accept: application/json"
sleep 0.5


echo -e "\n"
