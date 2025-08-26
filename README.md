# PowerShell-GAS Real People Chat System

This project implements a **real-time chat system** where multiple PowerShell clients can communicate with each other through a Google Apps Script server. Real people can register with unique usernames, send messages, and see chat history with other users.

## 🚀 New Features

- **Real User Registration**: Dynamic user registration with unique usernames
- **Persistent Message Storage**: Messages are stored and can be retrieved
- **Multi-User Support**: Multiple people can chat simultaneously
- **Real-Time Chat History**: View recent messages and see what others are saying
- **User Management**: See who's registered and when they joined
- **Interactive Commands**: Built-in commands for enhanced chat experience

## 🌟 How It Works

1. **User Registration**: Each person chooses a unique username when joining
2. **Real-Time Messaging**: Send messages that are stored on the server
3. **Message History**: See recent messages from all users
4. **User Directory**: View all registered users
5. **Persistent Storage**: All data is stored using Google Apps Script's PropertiesService

## 📁 Project Structure

```
powershell-gas-chat-system
├── client
│   ├── chat.ps1          # Enhanced PowerShell client with real user support
│   ├── config.ps1        # Configuration settings for the PowerShell client
│   └── utils
│       └── http-helpers.ps1 # Utility functions for HTTP requests
├── server
│   ├── code.js           # Enhanced Google Apps Script with real user management
│   ├── config.gs         # Configuration settings for the Google Apps Script server
│   └── utils
│       └── user-helpers.gs # Utility functions for managing user data
├── docs
│   └── setup-guide.md     # Step-by-step setup guide
├── start-chat.bat         # Windows batch file to easily start the chat
├── start-chat.ps1         # PowerShell script to start the chat
└── README.md              # Project overview and usage instructions
```

## 🎯 Quick Start

1. **Deploy the Server**: Copy `server/code.js` to Google Apps Script and deploy as a web app
2. **Configure Client**: Update `client/config.ps1` with your Google Apps Script URL
3. **Run Chat**: Double-click `start-chat.bat` or run `.\start-chat.ps1`

## 💬 Chat Commands

Once in the chat, you can use these commands:

- `/recent [count]` - Show recent messages (default: 5, max: 20)
- `/users` - Show all registered users and when they joined
- `/help` - Display available commands
- `/quit` - Exit the chat
- Just type normally to send messages!

## 🔧 Usage

1. **Setup the Google Apps Script Server:**
   - Open the `server/code.gs` file and configure any necessary settings in `server/config.gs`.
   - Deploy the Google Apps Script as a web app to receive requests from the PowerShell client.

2. **Configure the PowerShell Client:**
   - Open the `client/config.ps1` file and set the server URL and any authentication details required to connect to the Google Apps Script server.

3. **Run the PowerShell Client:**
   - Execute the `client/chat.ps1` script to start the chat interface.
   - Follow the prompts to send messages and view the responses.

## Contributing

Feel free to contribute to this project by submitting issues or pull requests. Your feedback and improvements are welcome!