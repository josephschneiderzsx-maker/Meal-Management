# GEMINI SPEC — Meal Management & Reporting Platform

This project is a full-stack application designed to manage and report on employee meal consumption. It is built with a Next.js frontend and an Express.js backend, connecting to a MySQL database.

This repository was scaffolded and developed by an AI software engineer, Jules.

## Current Status

**This repository contains the foundational scaffolding for the project.** It is a work in progress and does not yet include all the features outlined in the original specification.

**Implemented Features:**
-   Backend project setup with Express.js and TypeScript.
-   Frontend project setup with Next.js, TypeScript, and Tailwind CSS.
-   Database schema for application-specific tables (`user`, `app_settings`, etc.).
-   Backend authentication endpoint (`/api/auth/login`).
-   Frontend login page (at the root `/`) that connects to the backend.
-   A styled, component-based dashboard UI with placeholder data.

## Project Structure

The project is organized into two main directories. All commands should be run from the root of the project unless specified otherwise.
-   `api/`: Contains the backend Express.js application.
-   `app/`: Contains the frontend Next.js application.

## Prerequisites

Before you begin, ensure you have the following installed:
-   [Node.js](https://nodejs.org/) (v18 or later recommended)
-   [npm](https://www.npmjs.com/) (or [yarn](https://yarnpkg.com/))
-   [MySQL](https://www.mysql.com/) (v8.0 or later)

## Backend Setup (`api/`)

1.  **Navigate to the API directory:**
    ```bash
    cd api
    ```

2.  **Create an environment file:**
    Manually copy the `env.example` file to a new file named `.env` and fill in your details.

    *On Windows Command Prompt:*
    ```cmd
    copy .env.example .env
    ```
    *On Linux, macOS, or Git Bash:*
    ```bash
    cp .env.example .env
    ```
    Now, open the `.env` file in a text editor and add your database credentials, JWT secret, and SMTP server details.

3.  **Install dependencies:**
    ```bash
    npm install
    ```

4.  **Set up the database:**
    Make sure your MySQL server is running.

    **Important:** The `setup.sql` script **only** creates the new tables required for this application's logic (e.g., `user`, `report_schedule`). It **does not** include the pre-existing `FEDERATED` tables (`company`, `employee`, `meal_cons`, etc.) or other business tables (`meal_setting`) mentioned in the original specification. Your database environment must have these tables installed separately.

    *Example using the `mysql` command-line client:*
    ```bash
    # 1. Create the database
    mysql -u YOUR_MYSQL_USER -p -e "CREATE DATABASE IF NOT EXISTS meal_db;"

    # 2. Import the application-specific table schema
    mysql -u YOUR_MYSQL_USER -p meal_db < setup.sql
    ```

5.  **Run the development server:**
    ```bash
    npm run dev
    ```
    The backend server will run on `http://localhost:3001`.

## Frontend Setup (`app/`)

1.  **Navigate to the App directory:**
    **From the project root**, navigate into the `app` directory.
    ```bash
    cd app
    ```
    *(If you are in the `api` directory, you must go back to the root first with `cd ..`)*

2.  **Create a local environment file:**
    Manually copy `env.local.example` to a new file named `.env.local`. The default values should work for local development.

    *On Windows Command Prompt:*
    ```cmd
    copy .env.local.example .env.local
    ```
    *On Linux, macOS, or Git Bash:*
    ```bash
    cp .env.local.example .env.local
    ```

3.  **Install dependencies:**
    ```bash
    npm install
    ```

4.  **Run the development server:**
    ```bash
    npm run dev
    ```
    The frontend application will be available at `http://localhost:3000`.

## Notes & Known Issues
-   **Placeholder Assets:** The `app/public/logo.png` file is a placeholder and should be replaced with the actual company logo.
-   **Environment Instability:** The automated development environment used for scaffolding sometimes experienced issues with `npm install`. If you encounter a `uv_cwd` error, retrying the command or ensuring you are in the correct directory (`api` or `app`) should resolve it. The `package.json` files are correctly configured.
