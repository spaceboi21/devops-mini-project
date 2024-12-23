# Use Node.js as the base image
FROM node:16

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all the project files to the container
COPY . .

# Expose the port your app runs on (e.g., 3000)
EXPOSE 3000

# Command to start the app
CMD ["npm", "start"]
