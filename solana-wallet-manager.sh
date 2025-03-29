#!/bin/bash

# Solana Wallet Manager Script
# Usage: ./solana-wallet-manager.sh [command] [options]

# Base directory for storing wallets and recipients
WALLETS_DIR="$HOME/solana-wallets"
RECIPIENTS_DIR="$HOME/solana-wallets/recipients"
CURRENT_WALLET=""
CURRENT_CLUSTER="http://localhost:8899"  # Default to local test validator

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create wallets and recipients directories if they don't exist
if [ ! -d "$WALLETS_DIR" ]; then
    mkdir -p "$WALLETS_DIR"
    echo -e "${GREEN}Created wallets directory at $WALLETS_DIR${NC}"
fi

if [ ! -d "$RECIPIENTS_DIR" ]; then
    mkdir -p "$RECIPIENTS_DIR"
    echo -e "${GREEN}Created recipients directory at $RECIPIENTS_DIR${NC}"
fi

# Function to display help
show_help() {
    echo -e "${BLUE}Solana Wallet Manager${NC}"
    echo "Usage: ./solana-wallet-manager.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create-wallet <name>              - Create a new wallet with given name"
    echo "  list-wallets                      - List all available wallets"
    echo "  use-wallet <name>                 - Set current wallet"
    echo "  show-balance [name]               - Show balance of current or specified wallet"
    echo "  airdrop <amount> [name]           - Airdrop SOL to current or specified wallet"
    echo "  set-cluster <cluster>             - Set cluster (local, devnet, testnet, mainnet)"
    echo "  show-cluster                      - Show current cluster"
    echo "  transfer <amount> <recipient>     - Transfer SOL from current wallet to recipient"
    echo "  create-token <name> <symbol> <decimals> - Create a new SPL token"
    echo "  mint-token <token> <amount> [recipient] - Mint tokens to current or specified wallet"
    echo "  transfer-token <token> <amount> <recipient> - Transfer tokens from current wallet"
    echo "  list-tokens [name]                - List all tokens owned by current or specified wallet"
    echo "  help                              - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./solana-wallet-manager.sh create-wallet my-wallet"
    echo "  ./solana-wallet-manager.sh airdrop 1 my-wallet"
    echo "  ./solana-wallet-manager.sh transfer 0.5 recipient-wallet"
}

# Function to create a new wallet
create_wallet() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Wallet name is required${NC}"
        return 1
    fi
    
    local wallet_name="$1"
    local wallet_dir="$WALLETS_DIR/$wallet_name"
    
    if [ -d "$wallet_dir" ]; then
        echo -e "${RED}Error: Wallet '$wallet_name' already exists${NC}"
        return 1
    fi
    
    mkdir -p "$wallet_dir"
    solana-keygen new --no-bip39-passphrase -o "$wallet_dir/keypair.json"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Created new wallet: $wallet_name${NC}"
        echo -e "Wallet address: $(solana address -k $wallet_dir/keypair.json)"
        CURRENT_WALLET="$wallet_name"
        echo -e "${GREEN}Now using wallet: $CURRENT_WALLET${NC}"
    else
        echo -e "${RED}Failed to create wallet${NC}"
        return 1
    fi
}

# Function to list all available wallets
list_wallets() {
    echo -e "${BLUE}Available wallets:${NC}"
    
    if [ ! "$(ls -A $WALLETS_DIR 2>/dev/null)" ]; then
        echo "No wallets found. Create one with 'create-wallet <name>'"
        return 0
    fi
    
    for wallet_dir in "$WALLETS_DIR"/*; do
        if [ -d "$wallet_dir" ] && [ -f "$wallet_dir/keypair.json" ]; then
            wallet_name=$(basename "$wallet_dir")
            address=$(solana address -k "$wallet_dir/keypair.json")
            
            if [ "$wallet_name" == "$CURRENT_WALLET" ]; then
                echo -e "${GREEN}* $wallet_name${NC} - $address"
            else
                echo "  $wallet_name - $address"
            fi
        fi
    done
}

# Function to set the current wallet
use_wallet() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Wallet name is required${NC}"
        return 1
    fi
    
    local wallet_name="$1"
    local wallet_dir="$WALLETS_DIR/$wallet_name"
    
    if [ ! -d "$wallet_dir" ] || [ ! -f "$wallet_dir/keypair.json" ]; then
        echo -e "${RED}Error: Wallet '$wallet_name' not found${NC}"
        return 1
    fi
    
    CURRENT_WALLET="$wallet_name"
    echo -e "${GREEN}Now using wallet: $CURRENT_WALLET${NC}"
    echo -e "Wallet address: $(solana address -k $wallet_dir/keypair.json)"
}

# Function to show the balance of a wallet
show_balance() {
    local wallet_name="${1:-$CURRENT_WALLET}"
    
    if [ -z "$wallet_name" ]; then
        echo -e "${RED}Error: No wallet selected. Use 'use-wallet <name>' first${NC}"
        return 1
    fi
    
    local wallet_dir="$WALLETS_DIR/$wallet_name"
    
    if [ ! -d "$wallet_dir" ] || [ ! -f "$wallet_dir/keypair.json" ]; then
        echo -e "${RED}Error: Wallet '$wallet_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Checking balance for wallet: $wallet_name${NC}"
    solana balance -k "$wallet_dir/keypair.json"
}

# Function to airdrop SOL to a wallet
airdrop() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Amount is required${NC}"
        return 1
    fi
    
    local amount="$1"
    local wallet_name="${2:-$CURRENT_WALLET}"
    
    if [ -z "$wallet_name" ]; then
        echo -e "${RED}Error: No wallet selected. Use 'use-wallet <name>' first${NC}"
        return 1
    fi
    
    local wallet_dir="$WALLETS_DIR/$wallet_name"
    
    if [ ! -d "$wallet_dir" ] || [ ! -f "$wallet_dir/keypair.json" ]; then
        echo -e "${RED}Error: Wallet '$wallet_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Airdropping $amount SOL to wallet: $wallet_name${NC}"
    solana airdrop "$amount" -k "$wallet_dir/keypair.json"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Airdrop successful${NC}"
        show_balance "$wallet_name"
    else
        echo -e "${RED}Airdrop failed${NC}"
        return 1
    fi
}

# Function to set the current cluster
set_cluster() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Cluster is required${NC}"
        return 1
    fi
    
    local cluster="$1"
    local url=""
    
    case "$cluster" in
        "local")
            url="http://localhost:8899"
            ;;
        "devnet")
            url="https://api.devnet.solana.com"
            ;;
        "testnet")
            url="https://api.testnet.solana.com"
            ;;
        "mainnet")
            url="https://api.mainnet-beta.solana.com"
            ;;
        *)
            # Assume input is a direct URL
            url="$cluster"
            ;;
    esac
    
    echo -e "${BLUE}Setting cluster to: $cluster ($url)${NC}"
    solana config set --url "$url"
    
    if [ $? -eq 0 ]; then
        CURRENT_CLUSTER="$url"
        echo -e "${GREEN}Cluster set successfully${NC}"
    else
        echo -e "${RED}Failed to set cluster${NC}"
        return 1
    fi
}

# Function to show the current cluster
show_cluster() {
    echo -e "${BLUE}Current cluster:${NC} $(solana config get -v | grep "RPC URL" | cut -d ' ' -f 3)"
}

# Function to check if the current cluster is available
check_cluster() {
    local current_cluster=$(solana config get -v | grep "RPC URL" | cut -d ' ' -f 3)
    echo -e "${BLUE}Checking availability of cluster:${NC} $current_cluster"
    
    # Try to get cluster version
    local response
    if response=$(solana cluster-version 2>&1); then
        echo -e "${GREEN}Cluster is available!${NC}"
        echo "Cluster version: $response"
        return 0
    else
        echo -e "${RED}Cluster is not available or not responding${NC}"
        echo "Error: $response"
        return 1
    fi
}

# Function to transfer SOL between wallets
transfer_sol() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Amount and recipient are required${NC}"
        return 1
    fi
    
    local amount="$1"
    local recipient="$2"
    local recipient_address=""
    
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}Error: No wallet selected. Use 'use-wallet <name>' first${NC}"
        return 1
    fi
    
    # Check if recipient is a wallet name or a direct address
    if [ -d "$WALLETS_DIR/$recipient" ] && [ -f "$WALLETS_DIR/$recipient/keypair.json" ]; then
        recipient_address=$(solana address -k "$WALLETS_DIR/$recipient/keypair.json")
    else
        # Assume it's already an address
        recipient_address="$recipient"
    fi
    
    echo -e "${BLUE}Transferring $amount SOL from $CURRENT_WALLET to $recipient_address${NC}"
    solana transfer --allow-unfunded-recipient -k "$WALLETS_DIR/$CURRENT_WALLET/keypair.json" "$recipient_address" "$amount"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Transfer successful${NC}"
        show_balance "$CURRENT_WALLET"
    else
        echo -e "${RED}Transfer failed${NC}"
        return 1
    fi
}

# Function to create a new SPL token
create_token() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}Error: Token name, symbol, and decimals are required${NC}"
        return 1
    fi
    
    local token_name="$1"
    local token_symbol="$2"
    local token_decimals="$3"
    
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}Error: No wallet selected. Use 'use-wallet <n>' first${NC}"
        return 1
    fi
    
    local wallet_dir="$WALLETS_DIR/$CURRENT_WALLET"
    local wallet_keypair="$wallet_dir/keypair.json"
    
    echo -e "${BLUE}Creating new token: $token_name ($token_symbol) with $token_decimals decimals${NC}"
    
    # Create tokens directory if it doesn't exist
    mkdir -p "$wallet_dir/tokens"
    
    # Create a token-specific keypair file that we'll keep
    local token_keypair_file="$wallet_dir/tokens/${token_symbol}_keypair.json"
    
    # Create token keypair
    echo -e "${BLUE}Generating token keypair...${NC}"
    solana-keygen new -o "$token_keypair_file" --no-bip39-passphrase --force
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to generate token keypair${NC}"
        return 1
    fi
    
    # Get the token keypair public key - this will be the token address
    local token_address=$(solana-keygen pubkey "$token_keypair_file")
    echo -e "${BLUE}Token keypair public key: $token_address${NC}"
    
    # Save current Solana configuration
    echo -e "${BLUE}Saving current Solana configuration...${NC}"
    local current_keypair
    current_keypair=$(solana config get keypair -o json 2>/dev/null || echo "none")
    
    # Set wallet keypair as default
    echo -e "${BLUE}Setting wallet keypair as default...${NC}"
    solana config set --keypair "$wallet_keypair"
    
    # Create the token 
    echo -e "${BLUE}Creating token...${NC}"
    local token_output
    token_output=$(spl-token create-token --decimals "$token_decimals" "$token_keypair_file" 2>&1)
    local token_status=$?
    
    if [ $token_status -eq 0 ]; then
        # Token created successfully
        echo -e "${GREEN}Token created successfully!${NC}"
        echo -e "${GREEN}Token address: $token_address${NC}"
        
        # Store token info
        echo "{\"name\":\"$token_name\",\"symbol\":\"$token_symbol\",\"decimals\":$token_decimals,\"address\":\"$token_address\",\"keypair\":\"${token_symbol}_keypair.json\"}" > "$wallet_dir/tokens/$token_symbol.json"
        echo -e "${GREEN}Token information saved to $wallet_dir/tokens/$token_symbol.json${NC}"
        
        # Create token account
        echo -e "${BLUE}Creating token account...${NC}"
        local account_output
        account_output=$(spl-token create-account "$token_address" 2>&1)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Token account created successfully!${NC}"
        else
            echo -e "${YELLOW}Failed to create token account: $account_output${NC}"
            echo -e "${YELLOW}You may need to create a token account manually${NC}"
        fi
    else
        echo -e "${RED}Token creation failed${NC}"
        echo -e "Error: $token_output"
    fi
    
    # Restore original configuration if it existed
    if [ "$current_keypair" != "none" ]; then
        echo -e "${BLUE}Restoring original Solana configuration...${NC}"
        local original_keypair=$(echo "$current_keypair" | grep -o '"keypair":"[^"]*"' | cut -d '"' -f 4)
        solana config set --keypair "$original_keypair"
    fi
    
    return $token_status
}

# Function to mint tokens
mint_token() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Token and amount are required${NC}"
        return 1
    fi
    
    local token="$1"
    local amount="$2"
    local recipient="${3:-$CURRENT_WALLET}"
    local token_address=""
    local token_keypair_file=""
    
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}Error: No wallet selected. Use 'use-wallet <name>' first${NC}"
        return 1
    fi
    
    local wallet_dir="$WALLETS_DIR/$CURRENT_WALLET"
    local wallet_keypair="$wallet_dir/keypair.json"
    
    # Check if token is a symbol or direct address
    if [ -f "$wallet_dir/tokens/$token.json" ]; then
        local token_info=$(cat "$wallet_dir/tokens/$token.json")
        token_address=$(echo "$token_info" | grep -o '"address":"[^"]*"' | cut -d '"' -f 4)
        token_keypair=$(echo "$token_info" | grep -o '"keypair":"[^"]*"' | cut -d '"' -f 4)
        token_keypair_file="$wallet_dir/tokens/$token_keypair"
    else
        # Assume it's already an address
        token_address="$token"
        echo -e "${YELLOW}Warning: Using direct token address without keypair file${NC}"
    fi
    
    local recipient_address=""
    
    # Check if recipient is a wallet name
    if [ -d "$WALLETS_DIR/$recipient" ] && [ -f "$WALLETS_DIR/$recipient/keypair.json" ]; then
        recipient_address=$(solana address -k "$WALLETS_DIR/$recipient/keypair.json")
        echo -e "${BLUE}Using wallet as recipient: $recipient - $recipient_address${NC}"
    else
        # Assume it's already an address
        recipient_address="$recipient"
        echo -e "${BLUE}Using direct address as recipient: $recipient_address${NC}"
    fi
    
    echo -e "${BLUE}Minting $amount $token tokens to $recipient_address${NC}"
    
    # Save current Solana configuration
    echo -e "${BLUE}Saving current Solana configuration...${NC}"
    local current_keypair
    current_keypair=$(solana config get keypair -o json 2>/dev/null || echo "none")
    
    # Set wallet keypair as default
    echo -e "${BLUE}Setting wallet keypair as default...${NC}"
    solana config set --keypair "$wallet_keypair"
    
    # Mint tokens
    local mint_output
    if [ -n "$token_keypair_file" ] && [ -f "$token_keypair_file" ]; then
        echo -e "${BLUE}Minting with token authority...${NC}"
        mint_output=$(spl-token mint "$token_address" "$amount" 2>&1)
    else
        echo -e "${BLUE}Minting without token authority (this may fail if you are not the mint authority)...${NC}"
        mint_output=$(spl-token mint "$token_address" "$amount" 2>&1)
    fi
    
    local mint_status=$?
    
    if [ $mint_status -eq 0 ]; then
        echo -e "${GREEN}Token minting successful${NC}"
    else
        echo -e "${RED}Token minting failed${NC}"
        echo -e "Error: $mint_output"
    fi
    
    # Restore original configuration if it existed
    if [ "$current_keypair" != "none" ]; then
        echo -e "${BLUE}Restoring original Solana configuration...${NC}"
        local original_keypair=$(echo "$current_keypair" | grep -o '"keypair":"[^"]*"' | cut -d '"' -f 4)
        solana config set --keypair "$original_keypair"
    fi
    
    return $mint_status
}

# Function to transfer tokens between wallets
transfer_token() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}Error: Token, amount, and recipient are required${NC}"
        return 1
    fi
    
    local token="$1"
    local amount="$2"
    local recipient="$3"
    local token_address=""
    
    if [ -z "$CURRENT_WALLET" ]; then
        echo -e "${RED}Error: No wallet selected. Use 'use-wallet <name>' first${NC}"
        return 1
    fi
    
    local wallet_dir="$WALLETS_DIR/$CURRENT_WALLET"
    local wallet_keypair="$wallet_dir/keypair.json"
    
    # Check if token is a symbol or direct address
    if [ -f "$wallet_dir/tokens/$token.json" ]; then
        token_address=$(cat "$wallet_dir/tokens/$token.json" | grep -o '"address":"[^"]*"' | cut -d '"' -f 4)
    else
        # Assume it's already an address
        token_address="$token"
    fi
    
    local recipient_address=""
    
    # Check if recipient is a wallet name
    if [ -d "$WALLETS_DIR/$recipient" ] && [ -f "$WALLETS_DIR/$recipient/keypair.json" ]; then
        recipient_address=$(solana address -k "$WALLETS_DIR/$recipient/keypair.json")
        echo -e "${BLUE}Using wallet as recipient: $recipient - $recipient_address${NC}"
    else
        # Assume it's already an address
        recipient_address="$recipient"
        echo -e "${BLUE}Using direct address as recipient: $recipient_address${NC}"
    fi
    
    echo -e "${BLUE}Transferring $amount $token tokens from $CURRENT_WALLET to $recipient_address${NC}"
    
    # Save current Solana configuration
    echo -e "${BLUE}Saving current Solana configuration...${NC}"
    local current_keypair
    current_keypair=$(solana config get keypair -o json 2>/dev/null || echo "none")
    
    # Set wallet keypair as default
    echo -e "${BLUE}Setting wallet keypair as default...${NC}"
    solana config set --keypair "$wallet_keypair"
    
    # Transfer tokens with --fund-recipient flag to automatically create the token account
    echo -e "${BLUE}Attempting transfer with automatic recipient account funding...${NC}"
    local transfer_output
    transfer_output=$(spl-token transfer --allow-unfunded-recipient --fund-recipient "$token_address" "$amount" "$recipient_address" 2>&1)
    local transfer_status=$?
    
    if [ $transfer_status -eq 0 ]; then
        echo -e "${GREEN}Token transfer successful${NC}"
    else
        echo -e "${RED}Token transfer failed${NC}"
        echo -e "Error: $transfer_output"
        
        # If that fails, try to create the account first
        echo -e "${YELLOW}Trying to create the recipient's token account first...${NC}"
        
        # Save current wallet address
        local current_wallet_address=$(solana address -k "$wallet_keypair")
        
        # Try to create the associated token account for the recipient
        local create_output
        create_output=$(spl-token create-account "$token_address" "$recipient_address" --fund-recipient 2>&1)
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully created token account for recipient${NC}"
            
            # Try transfer again
            echo -e "${BLUE}Attempting transfer again...${NC}"
            transfer_output=$(spl-token transfer "$token_address" "$amount" "$recipient_address" 2>&1)
            transfer_status=$?
            
            if [ $transfer_status -eq 0 ]; then
                echo -e "${GREEN}Token transfer successful${NC}"
            else
                echo -e "${RED}Token transfer failed after creating account${NC}"
                echo -e "Error: $transfer_output"
            fi
        else
            echo -e "${RED}Failed to create token account for recipient${NC}"
            echo -e "Error: $create_output"
        fi
    fi
    
    # Restore original configuration if it existed
    if [ "$current_keypair" != "none" ]; then
        echo -e "${BLUE}Restoring original Solana configuration...${NC}"
        local original_keypair=$(echo "$current_keypair" | grep -o '"keypair":"[^"]*"' | cut -d '"' -f 4)
        solana config set --keypair "$original_keypair"
    fi
    
    return $transfer_status
}

# Function to list tokens owned by a wallet
list_tokens() {
    local wallet_name="${1:-$CURRENT_WALLET}"
    
    if [ -z "$wallet_name" ]; then
        echo -e "${RED}Error: No wallet selected. Use 'use-wallet <name>' first${NC}"
        return 1
    fi
    
    local wallet_dir="$WALLETS_DIR/$wallet_name"
    local wallet_keypair="$wallet_dir/keypair.json"
    
    if [ ! -d "$wallet_dir" ] || [ ! -f "$wallet_keypair" ]; then
        echo -e "${RED}Error: Wallet '$wallet_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Tokens owned by wallet: $wallet_name${NC}"
    
    # Save current Solana configuration
    echo -e "${BLUE}Saving current Solana configuration...${NC}"
    local current_keypair
    current_keypair=$(solana config get keypair -o json 2>/dev/null || echo "none")
    
    # Set wallet keypair as default
    echo -e "${BLUE}Setting wallet keypair as default...${NC}"
    solana config set --keypair "$wallet_keypair"
    
    # List token accounts
    local accounts_output
    accounts_output=$(spl-token accounts 2>&1)
    local accounts_status=$?
    
    if [ $accounts_status -eq 0 ]; then
        echo "$accounts_output"
    else
        echo -e "${RED}Failed to list token accounts${NC}"
        echo -e "Error: $accounts_output"
    fi
    
    # Also list token info if available
    if [ -d "$wallet_dir/tokens" ] && [ "$(ls -A $wallet_dir/tokens 2>/dev/null)" ]; then
        echo -e "\n${BLUE}Tokens created by this wallet:${NC}"
        for token_file in "$wallet_dir/tokens"/*.json; do
            if [ -f "$token_file" ] && [[ "$token_file" != *"_keypair.json" ]]; then
                local token_info=$(cat "$token_file")
                local token_name=$(echo "$token_info" | grep -o '"name":"[^"]*"' | cut -d '"' -f 4)
                local token_symbol=$(echo "$token_info" | grep -o '"symbol":"[^"]*"' | cut -d '"' -f 4)
                local token_decimals=$(echo "$token_info" | grep -o '"decimals":[^,}]*' | cut -d ':' -f 2)
                local token_address=$(echo "$token_info" | grep -o '"address":"[^"]*"' | cut -d '"' -f 4)
                
                echo -e "${GREEN}$token_name ($token_symbol)${NC} - Decimals: $token_decimals - Address: $token_address"
            fi
        done
    fi
    
    # Restore original configuration if it existed
    if [ "$current_keypair" != "none" ]; then
        echo -e "${BLUE}Restoring original Solana configuration...${NC}"
        local original_keypair=$(echo "$current_keypair" | grep -o '"keypair":"[^"]*"' | cut -d '"' -f 4)
        solana config set --keypair "$original_keypair"
    fi
    
    return $accounts_status
}

# Fix the CURRENT_WALLET env variable if it's not persisting
fix_current_wallet() {
    # Create a file to store the current wallet
    if [ -f "$WALLETS_DIR/current_wallet" ]; then
        CURRENT_WALLET=$(cat "$WALLETS_DIR/current_wallet")
    fi
}

# Set the current wallet in a file for persistence
set_current_wallet_file() {
    echo "$CURRENT_WALLET" > "$WALLETS_DIR/current_wallet"
}

# When using a wallet, fix the persistence
use_wallet() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Wallet name is required${NC}"
        return 1
    fi
    
    local wallet_name="$1"
    local wallet_dir="$WALLETS_DIR/$wallet_name"
    
    if [ ! -d "$wallet_dir" ] || [ ! -f "$wallet_dir/keypair.json" ]; then
        echo -e "${RED}Error: Wallet '$wallet_name' not found${NC}"
        return 1
    fi
    
    CURRENT_WALLET="$wallet_name"
    set_current_wallet_file
    echo -e "${GREEN}Now using wallet: $CURRENT_WALLET${NC}"
    echo -e "Wallet address: $(solana address -k $wallet_dir/keypair.json)"
}

# Main command parser
fix_current_wallet

case "$1" in
    "create-wallet")
        create_wallet "$2"
        # Save current wallet after creation
        set_current_wallet_file
        ;;
    "list-wallets")
        list_wallets
        ;;
    "use-wallet")
        use_wallet "$2"
        ;;
    "show-balance")
        show_balance "$2"
        ;;
    "airdrop")
        airdrop "$2" "$3"
        ;;
    "set-cluster")
        set_cluster "$2"
        ;;
    "show-cluster")
        show_cluster
        ;;
    "check-cluster")
        check_cluster
        ;;
    "add-recipient")
        add_recipient "$2" "$3"
        ;;
    "list-recipients")
        list_recipients
        ;;
    "transfer")
        transfer_sol "$2" "$3"
        ;;
    "create-token")
        create_token "$2" "$3" "$4"
        ;;
    "mint-token")
        mint_token "$2" "$3" "$4"
        ;;
    "transfer-token")
        transfer_token "$2" "$3" "$4"
        ;;
    "list-tokens")
        list_tokens "$2"
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac