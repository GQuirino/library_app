# Library App

## Backend API

This is the backend API for a library management system built with Ruby on Rails. It provides endpoints for managing books, users, and reservations.

## Requirements
- docker

## Getting Started
To get started with the project, follow these steps:

1. run `docker-compose up --build` to build and start the application.
2. The API will be accessible at `http://localhost:3001`.
3. Run Migrations: `docker-compose exec backend-app bundle exec rails db:migrate`
4. Run Seeds: `docker-compose exec backend-app bundle exec rails db:seed`

## API Documentation
The API documentation is provided by Swagger and available at `http://localhost:3001/api-docs`.


## Frontend
This is the frontend application for the library management system built with React. It provides a user interface for interacting with the backend API.
To get started with the frontend application, follow these steps:

1. The frontend will be accessible at `http://localhost:3000`.

# LIBRARIAN ACCESS
email: alice.johnson@library.com
password: password123

# MEMBER ACCESS
email: john.smith@email.com
password: password123
