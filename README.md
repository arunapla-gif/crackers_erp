# Crackers ERP - React + Tailwind + PostgreSQL

This project has been modernized from a single monolithic HTML file to a modular, full-stack application using **React**, **Tailwind CSS**, and **PostgreSQL**! 

## Step 1: Install Development Environment

Since you are starting on a fresh Mac without developer tools, you must run these exact commands in your terminal, one by one.

**1. Install Xcode Command Line Tools (Required for Mac)**
```bash
xcode-select --install
```
*(A prompt will appear. Click "Install" and wait for it to finish).*

**2. Install Homebrew (Mac Package Manager)**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
*(Follow any instructions it prints at the very end to add Homebrew to your PATH).*

**3. Install Node.js & PostgreSQL**
```bash
brew install node
brew install postgresql@14
brew services start postgresql@14
```

## Step 2: Database Setup

Now that PostgreSQL is running, create the database for the ERP:
```bash
createdb crackers_erp
```

## Step 3: Start the Backend (API & Database)

Open a new terminal window, navigate to the `backend` folder, install the packages, initialize the Prisma database, and start the server!

```bash
cd "/Users/arun_ap/Desktop/crackers erp/backend"
npm install
npx prisma db push
npx prisma generate
npm run dev
```

## Step 4: Start the Frontend (React App)

Open *another* new terminal window, navigate to the `frontend` folder, install the React packages, and start the development server.

```bash
cd "/Users/arun_ap/Desktop/crackers erp/frontend"
npm install
npm run dev
```

Once the frontend starts, you can click on the `http://localhost:5173` link printed in your terminal to see the beautifully modernized React application running! 

*Note: The Customer Master module is fully migrated and hooked up to PostgreSQL. Once you confirm it works, we can proceed to migrate the Billing and Stock modules!*
