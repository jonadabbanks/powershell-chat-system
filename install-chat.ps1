param(
    [string]$InstallPath = "$env:USERPROFILE\PowerShellChat",
    [string]$ServerUrl = "",
    [switch]$Silent,
    [switch]$AutoStart
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

function Get-SecurePassword {
    param([string]$Prompt = "Enter password")
    
    $securePassword = Read-Host -Prompt $Prompt -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    return $password
}

function Register-User {
    param([string]$Username)
    
    Write-Host "Registering new user: $Username" -ForegroundColor Yellow
    $password = Get-SecurePassword -Prompt "Create a password for your account"
    
    if ($password.Trim() -eq "") {
        Write-Host "Password cannot be empty!" -ForegroundColor Red
        return $null
    }
    
    try {
        $body = @{
            action = "register"
            username = $Username
            password = $password
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $global:config.ServerUrl -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
        
        if ($response.success) {
            Write-Host "Registration successful!" -ForegroundColor Green
            return @{
                username = $response.username
                userId = $response.userId
            }
        } else {
            if ($response.requiresLogin) {
                Write-Host "Username already exists. Please login." -ForegroundColor Yellow
                return Login-User -Username $Username
            } else {
                Write-Host "Registration failed: $($response.error)" -ForegroundColor Red
                return $null
            }
        }
    } catch {
        Write-Host "Error during registration: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Login-User {
    param([string]$Username)
    
    Write-Host "Logging in user: $Username" -ForegroundColor Yellow
    
    # First, try to login without password (for new usernames or to check account status)
    try {
        $body = @{
            action = "login"
            username = $Username
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $global:config.ServerUrl -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
        
        if ($response.success) {
            Write-Host "Login successful!" -ForegroundColor Green
            return @{
                username = $response.username
                userId = $response.userId
            }
        } else {
            if ($response.canRegister) {
                Write-Host "Username not found. Let's register you." -ForegroundColor Cyan
                return Register-User -Username $Username
            } elseif ($response.needsPasswordSetup) {
                Write-Host "Your account needs a password for security." -ForegroundColor Yellow
                $password = Get-SecurePassword -Prompt "Set a password for your account"
                
                if ($password.Trim() -eq "") {
                    Write-Host "Password cannot be empty!" -ForegroundColor Red
                    return $null
                }
                
                # Set password for legacy user
                $bodyWithPassword = @{
                    action = "login"
                    username = $Username
                    password = $password
                } | ConvertTo-Json
                
                $passwordResponse = Invoke-RestMethod -Uri $global:config.ServerUrl -Method POST -Body $bodyWithPassword -ContentType "application/json" -UseBasicParsing
                
                if ($passwordResponse.success) {
                    Write-Host "Password set successfully! You are now logged in." -ForegroundColor Green
                    return @{
                        username = $passwordResponse.username
                        userId = $passwordResponse.userId
                    }
                } else {
                    Write-Host "Failed to set password: $($passwordResponse.error)" -ForegroundColor Red
                    return $null
                }
            } elseif ($response.requiresPassword) {
                Write-Host "Password required for this account." -ForegroundColor Yellow
                $password = Get-SecurePassword -Prompt "Enter your password"
                
                $bodyWithPassword = @{
                    action = "login"
                    username = $Username
                    password = $password
                } | ConvertTo-Json
                
                $passwordResponse = Invoke-RestMethod -Uri $global:config.ServerUrl -Method POST -Body $bodyWithPassword -ContentType "application/json" -UseBasicParsing
                
                if ($passwordResponse.success) {
                    Write-Host "Login successful!" -ForegroundColor Green
                    return @{
                        username = $passwordResponse.username
                        userId = $passwordResponse.userId
                    }
                } else {
                    Write-Host "Login failed: $($passwordResponse.error)" -ForegroundColor Red
                    return $null
                }
            } else {
                Write-Host "Login failed: $($response.error)" -ForegroundColor Red
                return $null
            }
        }
    } catch {
        Write-Host "Error during login: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-OnlineUsers {
    try {
        $response = Invoke-RestMethod -Uri "$($global:config.ServerUrl)/users" -Method GET -UseBasicParsing
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
        
        $response = Invoke-RestMethod -Uri "$($global:config.ServerUrl)/send" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
        return $response.status -eq "success"
    } catch {
        Write-Host "Error sending message: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-PrivateMessages {
    param([string]$With)
    
    try {
        $encodedUser = [System.Web.HttpUtility]::UrlEncode($currentUser)
        $encodedWith = [System.Web.HttpUtility]::UrlEncode($With)
        $url = "$($global:config.ServerUrl)/messages?user=$encodedUser&with=$encodedWith"
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
                Write-Host "[$timestamp] ${from}: " -ForegroundColor Blue -NoNewline
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
    Write-Host "Server URL: $($global:config.ServerUrl)" -ForegroundColor Gray
    exit 1
}

$currentUsername = Get-Username
Write-Host "Welcome, $currentUsername!" -ForegroundColor Green

# Authenticate user (register or login)
Write-Host ""
Write-Host "Authenticating..." -ForegroundColor Cyan
$userInfo = Login-User -Username $currentUsername

if (-not $userInfo) {
    Write-Host "Authentication failed. Please try again later." -ForegroundColor Red
    exit 1
}

$currentUser = $userInfo.username
$currentUserId = $userInfo.userId

Write-Host "Authentication successful!" -ForegroundColor Green

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
    
    # Use provided ServerUrl or your default server
    $configServerUrl = if ($ServerUrl) { $ServerUrl } else { "https://script.google.com/macros/s/AKfycbytNa-9WrkWGbCGHpmBIhnlOQMrj-3QpCcF-iWqYxgFYpOZg1LKIS2pSQsjZY815H0W/exec" }
    
    # Use the same format as the working client config
    $configContent = "# PowerShell Chat System Configuration`n"
    $configContent += "`$serverUrl = `"$configServerUrl`"`n"
    $configContent += "`$apiKey = `"`"`n`n"
    $configContent += "`$global:config = @{`n"
    $configContent += "    ServerUrl = `$serverUrl`n"
    $configContent += "    ApiKey = `$apiKey`n"
    $configContent += "}"
    
    try {
        [System.IO.File]::WriteAllText("$InstallPath\config.ps1", $configContent, [System.Text.Encoding]::UTF8)
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
Write-Host "Starting PowerShell Chat System..." -ForegroundColor Cyan
Write-Host ""

try {
    Set-Location "$InstallPath"
    if (Test-Path ".\chat.ps1") {
        .\chat.ps1
    } else {
        Write-Host "Error: chat.ps1 not found in installation directory!" -ForegroundColor Red
        Write-Host "Current location: $(Get-Location)" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
    }
} catch {
    Write-Host "Error launching chat system: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
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
    if ($ServerUrl) {
        Write-ColoredOutput "Server URL: $ServerUrl" Green
    } else {
        Write-ColoredOutput "Server URL: Using default server (jonadabbanks)" Green
    }
    Write-ColoredOutput ""
    Write-ColoredOutput "How to Start Chatting:" Yellow
    Write-ColoredOutput "1. Navigate to: $InstallPath" Gray
    Write-ColoredOutput "2. Double-click 'Start-Chat.ps1' OR run it from PowerShell" Gray
    Write-ColoredOutput "3. Alternative: Run .\chat.ps1 from the installation folder" Gray
    Write-ColoredOutput ""
    Write-ColoredOutput "Quick Start Command:" Cyan
    Write-ColoredOutput "& `"$InstallPath\Start-Chat.ps1`"" Green
    Write-ColoredOutput ""
    if (-not $AutoStart) {
        Write-ColoredOutput "Pro Tip: Use -AutoStart parameter to launch chat immediately after install!" Magenta
        Write-ColoredOutput ""
    }
    if (-not $ServerUrl) {
        Write-ColoredOutput "Ready to chat! Default server configured." Green
        Write-ColoredOutput "To use your own server, specify -ServerUrl parameter during installation" Gray
    }
    
    return $true
}

# Main execution
try {
    $success = Install-PowerShellChat
    if ($success) {
        Write-ColoredOutput ""
        Write-ColoredOutput "Installation completed successfully!" Green
        
        if ($AutoStart) {
            Write-ColoredOutput ""
            Write-ColoredOutput "Auto-starting chat system..." Cyan
            Write-ColoredOutput "Press Ctrl+C to stop the chat and return to PowerShell" Yellow
            Write-ColoredOutput ""
            Start-Sleep -Seconds 2
            
            try {
                Set-Location $InstallPath
                & ".\chat.ps1"
            } catch {
                Write-ColoredOutput "Error starting chat: $($_.Exception.Message)" Red
                if (-not $Silent) {
                    Read-Host "Press Enter to exit"
                }
            }
        } else {
            if (-not $Silent) {
                Write-ColoredOutput ""
                Read-Host "Press Enter to exit"
            }
        }
        exit 0
    } else {
        Write-ColoredOutput ""
        Write-ColoredOutput "Installation failed. Please check the error messages above." Red
        if (-not $Silent) {
            Read-Host "Press Enter to exit"
        }
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
