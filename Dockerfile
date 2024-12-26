# Use Node.js as the base image
FROM node:18

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all files
COPY . .

# *** Build the React app ***
RUN npm run build

# The final build files are now in /app/build

# Expose the port your app runs on
EXPOSE 3000

# Start your Node/Express server
CMD ["npm", "start"]
