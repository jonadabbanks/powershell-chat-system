# PowerShell Chat System

A **real-time private messaging chat system** built with PowerShell and Google Apps Script. Users can install with a single command and start chatting immediately with other users through private messages.

## 🚀 Quick Start (One Command Install)

### **Install & Start Chatting Immediately:**
```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/jonadabbanks/powershell-chat-system/main/install-chat.ps1') } -AutoStart"
```

### **Install Only (Start Later):**
```powershell
iex (irm "https://raw.githubusercontent.com/jonadabbanks/powershell-chat-system/main/install-chat.ps1")
```

### **Custom Installation Path:**
```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/jonadabbanks/powershell-chat-system/main/install-chat.ps1') } -InstallPath 'C:\MyChat' -AutoStart"
```

## ✨ Features

- **🔐 Private Messages Only**: Secure private messaging between users
- **⚡ One-Command Install**: No setup required, works out of the box
- **🌐 Cross-Platform**: Works on any Windows machine with PowerShell
- **👥 Multi-User Support**: Multiple people can chat simultaneously  
- **📱 Real-Time**: Live message updates and user presence
- **🎨 Colorful Interface**: Clean, user-friendly chat experience
- **☁️ Cloud-Based**: Messages stored securely in Google Apps Script

## 🛠️ How It Works

1. **Automatic Installation**: The installer downloads and sets up all required files
2. **Server Connection**: Connects to a pre-configured Google Apps Script server
3. **User Registration**: Each person chooses a unique username when joining
4. **Private Messaging**: Send and receive private messages with other online users
5. **Real-Time Updates**: Messages appear instantly with automatic refresh

## 📁 Project Structure

```
powershell-gas-chat-system/
├── install-chat.ps1          # One-command installer script
├── README.md                 # This documentation
└── server/                   # Google Apps Script server code
    ├── code.js              # Main server logic with full API
    ├── config.gs            # Server configuration
    └── utils/               # Server utilities
        └── user-helpers.gs  # User management functions
```

## 💬 Chat Features

Once installed and running, users can:

- **Send Private Messages**: Type and send messages to selected users
- **Select Recipients**: Choose from a list of online users to chat with
- **Switch Conversations**: Change who you're chatting with using `switch` command
- **View Online Users**: See who's available to chat with using `users` command
- **Real-Time Updates**: Messages appear automatically as they're sent

### **Chat Commands:**
- Type your message and press Enter to send
- `users` - Show online users list
- `switch` - Change chat recipient  
- `exit` or `quit` - Leave the chat

## 🔧 Advanced Usage

### **For Developers - Custom Server:**
If you want to use your own Google Apps Script server:

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/jonadabbanks/powershell-chat-system/main/install-chat.ps1') } -ServerUrl 'YOUR_GAS_URL' -AutoStart"
```

### **Installation Options:**
- `-InstallPath` - Custom installation directory
- `-ServerUrl` - Use your own Google Apps Script server
- `-AutoStart` - Launch chat immediately after installation
- `-Silent` - Install without prompts (for automation)

## 🌐 Server API

The Google Apps Script server provides these endpoints:

### **PowerShell Client Endpoints:**
- `GET /users` - Get list of online usernames
- `POST /send` - Send private message `{from, to, message}`
- `GET /messages?user=X&with=Y` - Get conversation between users
- `GET /ping` - Test server connection

### **Advanced API Endpoints:**
- `POST /?action=register` - Register new user
- `POST /?action=login` - User login
- `POST /?action=sendPrivateMessage` - Send private message
- `POST /?action=getMessages` - Get user's messages
- `POST /?action=getUsers` - Get full user objects

## 📋 Requirements

- **Windows** with PowerShell 5.1+ (built into Windows 10/11)
- **Internet connection** for installation and messaging
- **No additional software** required

## 🔒 Privacy & Security

- **Private Messages Only**: No public chat rooms, only private conversations
- **Secure Storage**: Messages stored in Google Apps Script's secure environment
- **No Personal Data**: Only usernames are stored, no personal information required
- **Temporary Storage**: Messages are automatically cleaned up (100 message limit)

## 🎯 Use Cases

Perfect for:
- **Team Communication**: Quick private messages between team members
- **Remote Work**: Instant messaging for distributed teams
- **Gaming Groups**: Coordinate with friends during gaming sessions
- **Study Groups**: Private messaging for students and study partners
- **Small Organizations**: Internal communication tool

## 🤝 Contributing

This is an open-source project. Feel free to:
- Report issues or bugs
- Suggest new features
- Submit pull requests
- Fork for your own modifications

## 📞 Support

If you encounter any issues:
1. Check that PowerShell execution policy allows scripts
2. Ensure you have an internet connection
3. Try running PowerShell as Administrator
4. Check the installation path for any permission issues

## 📄 License

This project is open source. Use, modify, and distribute freely.

---

**Ready to start chatting? Run the one-command installer and start messaging instantly! 🚀**