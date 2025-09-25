FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Expose port 3000 for React dev server
EXPOSE 3000

# Start the development server
CMD ["npm", "start"]
