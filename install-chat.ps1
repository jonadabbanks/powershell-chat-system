param(
    [string]$InstallPath = "$env:USERPROFILE\PowerShellChat",
    [string]$ServerUrl = "",
    [switch]$Silent
)

function Write-ColoredOutput {
    param([string]$Message, [string]$Color = "White")
    
    $colorMap = @{
        "Red" = [ConsoleColor]::Red
        "Green" = [ConsoleColor]::Green
        "Yellow" = [ConsoleColor]::Yellow
        "Blue" = [ConsoleColor]::Blue
        "Cyan" = [ConsoleColor]::Cyan
        "Magenta" = [ConsoleColor]::Magenta
        "Gray" = [ConsoleColor]::Gray
        "White" = [ConsoleColor]::White
    }
    
    $consoleColor = if ($colorMap.ContainsKey($Color)) { $colorMap[$Color] } else { [ConsoleColor]::White }
    Write-Host $Message -ForegroundColor $consoleColor
}

function Test-Administrator {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-PowerShellChat {
    Clear-Host
    
    Write-ColoredOutput "PowerShell Chat System - Pure PowerShell Installer" Cyan
    Write-ColoredOutput "===================================================" Cyan
    Write-ColoredOutput ""
    
    # Check if running as admin
    if (Test-Administrator) {
        Write-ColoredOutput "Running as Administrator - Good!" Green
    } else {
        Write-ColoredOutput "Warning: Not running as Administrator. Some features may not work properly." Yellow
    }
    
    Write-ColoredOutput ""
    Write-ColoredOutput "Installation Path: $InstallPath" Gray
    Write-ColoredOutput ""
    
    # Create installation directory
    Write-ColoredOutput "Creating installation directory..." Yellow
    
    try {
        if (Test-Path $InstallPath) {
            Write-ColoredOutput "Directory already exists. Cleaning up..." Yellow
            Remove-Item "$InstallPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        }
        
        # Create utils subdirectory
        $utilsPath = Join-Path $InstallPath "utils"
        New-Item -ItemType Directory -Path $utilsPath -Force | Out-Null
        
        Write-ColoredOutput "Directory created successfully!" Green
    } catch {
        Write-ColoredOutput "Failed to create directory: $($_.Exception.Message)" Red
        return $false
    }
    
    # Create chat.ps1 - Main chat client
    Write-ColoredOutput "Creating chat client..." Yellow
    
    $chatContent = @'
param(
    [string]$Username = "",
    [switch]$Help
)

if ($Help) {
    Write-Host "PowerShell Chat System - Private Messaging Only" -ForegroundColor Cyan
    Write-Host "Usage: .\chat.ps1 [-Username <your_username>]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Features:" -ForegroundColor Green
    Write-Host "- Private messaging only (no public chat)" -ForegroundColor White
    Write-Host "- Real-time message checking" -ForegroundColor White
    Write-Host "- User selection from online users list" -ForegroundColor White
    Write-Host "- Clean, colorful interface" -ForegroundColor White
    Write-Host ""
    Write-Host "Commands during chat:" -ForegroundColor Green
    Write-Host "- Type your message and press Enter to send" -ForegroundColor White
    Write-Host "- Type 'exit' or 'quit' to leave" -ForegroundColor White
    Write-Host "- Type 'users' to see online users" -ForegroundColor White
    Write-Host "- Type 'switch' to change recipient" -ForegroundColor White
    exit
}

# Load configuration and utilities
. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\utils\http-helpers.ps1"

function Show-WelcomeBanner {
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "    PowerShell Chat - Private Messages Only   " -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-Username {
    if ($Username) { return $Username }
    
    do {
        $user = Read-Host "Enter your username"
        if ($user.Trim() -eq "") {
            Write-Host "Username cannot be empty!" -ForegroundColor Red
        }
    } while ($user.Trim() -eq "")
    
    return $user.Trim()
}

function Get-OnlineUsers {
    try {
        $response = Invoke-RestMethod -Uri "$serverUrl/users" -Method GET -UseBasicParsing
        if ($response.status -eq "success") {
            return $response.users
        }
    } catch {
        Write-Host "Error getting users: $($_.Exception.Message)" -ForegroundColor Red
    }
    return @()
}

function Select-Recipient {
    Write-Host ""
    Write-Host "Getting online users..." -ForegroundColor Yellow
    
    $users = Get-OnlineUsers
    if ($users.Count -eq 0) {
        Write-Host "No other users online currently." -ForegroundColor Red
        return $null
    }
    
    $otherUsers = $users | Where-Object { $_ -ne $currentUser }
    if ($otherUsers.Count -eq 0) {
        Write-Host "No other users online currently." -ForegroundColor Red
        return $null
    }
    
    Write-Host ""
    Write-Host "Online Users:" -ForegroundColor Green
    for ($i = 0; $i -lt $otherUsers.Count; $i++) {
        Write-Host "  $($i + 1). $($otherUsers[$i])" -ForegroundColor White
    }
    
    Write-Host ""
    do {
        $selection = Read-Host "Select user number (1-$($otherUsers.Count))"
        if ($selection -match '^\d+$') {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $otherUsers.Count) {
                return $otherUsers[$index]
            }
        }
        Write-Host "Invalid selection. Please enter a number between 1 and $($otherUsers.Count)" -ForegroundColor Red
    } while ($true)
}

function Send-PrivateMessage {
    param([string]$To, [string]$Message)
    
    try {
        $body = @{
            from = $currentUser
            to = $To
            message = $Message
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$serverUrl/send" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
        return $response.status -eq "success"
    } catch {
        Write-Host "Error sending message: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-PrivateMessages {
    param([string]$With)
    
    try {
        $url = "$serverUrl/messages?user=$([System.Web.HttpUtility]::UrlEncode($currentUser))&with=$([System.Web.HttpUtility]::UrlEncode($With))"
        $response = Invoke-RestMethod -Uri $url -Method GET -UseBasicParsing
        
        if ($response.status -eq "success") {
            return $response.messages
        }
    } catch {
        Write-Host "Error getting messages: $($_.Exception.Message)" -ForegroundColor Red
    }
    return @()
}

function Show-Messages {
    param([array]$Messages, [string]$With)
    
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "    Private Chat with: $With" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Messages.Count -eq 0) {
        Write-Host "No messages yet. Start the conversation!" -ForegroundColor Gray
    } else {
        foreach ($msg in $Messages) {
            $timestamp = $msg.timestamp
            $from = $msg.from
            $message = $msg.message
            
            if ($from -eq $currentUser) {
                Write-Host "[$timestamp] You: " -ForegroundColor Green -NoNewline
                Write-Host $message -ForegroundColor White
            } else {
                Write-Host "[$timestamp] $from: " -ForegroundColor Blue -NoNewline
                Write-Host $message -ForegroundColor White
            }
        }
    }
    
    Write-Host ""
    Write-Host "Commands: 'exit', 'quit', 'users', 'switch'" -ForegroundColor Gray
    Write-Host "Type your message:" -ForegroundColor Yellow -NoNewline
    Write-Host " " -NoNewline
}

# Main execution
Show-WelcomeBanner

if (-not (Test-ServerConnection)) {
    Write-Host "Cannot connect to chat server. Please check your configuration." -ForegroundColor Red
    Write-Host "Server URL: $serverUrl" -ForegroundColor Gray
    exit 1
}

$currentUser = Get-Username
Write-Host "Welcome, $currentUser!" -ForegroundColor Green

# Select initial recipient
$recipient = Select-Recipient
if (-not $recipient) {
    Write-Host "No users available for chat. Exiting..." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting private chat with $recipient..." -ForegroundColor Green
Start-Sleep 2

$lastMessageCount = 0

while ($true) {
    # Get messages
    $messages = Get-PrivateMessages -With $recipient
    
    # Show messages if there are new ones or first time
    if ($messages.Count -ne $lastMessageCount) {
        Show-Messages -Messages $messages -With $recipient
        $lastMessageCount = $messages.Count
    }
    
    # Check for user input (non-blocking)
    if ([Console]::KeyAvailable) {
        $input = Read-Host
        
        if ($input -eq "exit" -or $input -eq "quit") {
            Write-Host "Goodbye!" -ForegroundColor Green
            break
        } elseif ($input -eq "users") {
            $users = Get-OnlineUsers
            Write-Host "Online users: $($users -join ', ')" -ForegroundColor Green
            Start-Sleep 2
        } elseif ($input -eq "switch") {
            $newRecipient = Select-Recipient
            if ($newRecipient) {
                $recipient = $newRecipient
                $lastMessageCount = 0
                Write-Host "Switched to chat with $recipient" -ForegroundColor Green
                Start-Sleep 1
            }
        } elseif ($input.Trim() -ne "") {
            if (Send-PrivateMessage -To $recipient -Message $input) {
                # Message sent successfully, refresh will happen in next loop
            }
        }
    }
    
    Start-Sleep 2
}
'@
    
    try {
        $chatContent | Out-File -FilePath "$InstallPath\chat.ps1" -Encoding UTF8
        Write-ColoredOutput "Chat client created successfully!" Green
    } catch {
        Write-ColoredOutput "Failed to create chat client: $($_.Exception.Message)" Red
        return $false
    }
    
    # Create config.ps1
    Write-ColoredOutput "Creating configuration file..." Yellow
    
    $configContent = @'
# PowerShell Chat System Configuration

# Server Configuration
# Replace with your Google Apps Script Web App URL
$global:serverUrl = "https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec"

# Chat Configuration
$global:maxRetries = 3
$global:retryDelay = 2

# Display Configuration
$global:refreshInterval = 3
$global:maxMessageLength = 500

Write-Host "Configuration loaded" -ForegroundColor Green
Write-Host "Server URL: $serverUrl" -ForegroundColor Gray
'@
    
    try {
        $configContent | Out-File -FilePath "$InstallPath\config.ps1" -Encoding UTF8
        Write-ColoredOutput "Configuration file created successfully!" Green
    } catch {
        Write-ColoredOutput "Failed to create configuration file: $($_.Exception.Message)" Red
        return $false
    }
    
    # Create http-helpers.ps1
    Write-ColoredOutput "Creating HTTP helpers..." Yellow
    
    $httpContent = @'
# HTTP Helper Functions for PowerShell Chat

function Test-ServerConnection {
    try {
        $response = Invoke-RestMethod -Uri "$serverUrl/ping" -Method GET -UseBasicParsing -TimeoutSec 10
        return $true
    } catch {
        return $false
    }
}

function Invoke-ChatAPI {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [string]$Body = $null
    )
    
    $headers = @{
        'Content-Type' = 'application/json'
        'User-Agent' = 'PowerShell-Chat/1.0'
    }
    
    try {
        $params = @{
            Uri = "$serverUrl$Endpoint"
            Method = $Method
            Headers = $headers
            UseBasicParsing = $true
            TimeoutSec = 30
        }
        
        if ($Body) {
            $params['Body'] = $Body
        }
        
        return Invoke-RestMethod @params
    } catch {
        throw "API call failed: $($_.Exception.Message)"
    }
}

Write-Host "HTTP helpers loaded" -ForegroundColor Green
'@
    
    try {
        $httpContent | Out-File -FilePath "$InstallPath\utils\http-helpers.ps1" -Encoding UTF8
        Write-ColoredOutput "HTTP helpers created successfully!" Green
    } catch {
        Write-ColoredOutput "Failed to create HTTP helpers: $($_.Exception.Message)" Red
        return $false
    }
    
    # Create launcher script
    Write-ColoredOutput "Creating launcher script..." Yellow
    
    $launcherContent = @"
# PowerShell Chat System Launcher
Set-Location "$InstallPath"
.\chat.ps1
"@
    
    try {
        $launcherContent | Out-File -FilePath "$InstallPath\Start-Chat.ps1" -Encoding UTF8
        Write-ColoredOutput "Launcher script created successfully!" Green
    } catch {
        Write-ColoredOutput "Failed to create launcher script: $($_.Exception.Message)" Red
        return $false
    }
    
    Write-ColoredOutput ""
    Write-ColoredOutput "Installation completed successfully!" Green
    Write-ColoredOutput ""
    Write-ColoredOutput "Installation Summary:" Cyan
    Write-ColoredOutput "- Location: $InstallPath" Gray
    Write-ColoredOutput "- Main script: chat.ps1" Gray
    Write-ColoredOutput "- Configuration: config.ps1" Gray
    Write-ColoredOutput "- Launcher: Start-Chat.ps1" Gray
    Write-ColoredOutput ""
    Write-ColoredOutput "Next Steps:" Yellow
    Write-ColoredOutput "1. Edit config.ps1 to set your server URL" Gray
    Write-ColoredOutput "2. Run Start-Chat.ps1 to begin chatting" Gray
    Write-ColoredOutput ""
    Write-ColoredOutput "Ready to use once you configure your server URL." Gray
    
    return $true
}

# Main execution
try {
    $success = Install-PowerShellChat
    if ($success) {
        Write-ColoredOutput ""
        Write-ColoredOutput "Installation completed successfully!" Green
        exit 0
    } else {
        Write-ColoredOutput ""
        Write-ColoredOutput "Installation failed. Please check the error messages above." Red
        exit 1
    }
} catch {
    Write-ColoredOutput ""
    Write-ColoredOutput "Installation failed with error:" Red
    Write-ColoredOutput $_.Exception.Message Red
    Write-ColoredOutput ""
    if (-not $Silent) {
        Read-Host "Press Enter to exit"
    }
    exit 1
}
