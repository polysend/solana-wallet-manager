# Solana Wallet Manager

A comprehensive bash script for managing Solana wallets, addresses, tokens, and transactions in development environments.

## Features

- **Wallet Management**: Create, list, and select wallets
- **Address Management**: Store and manage recipient addresses
- **Transaction Support**: Transfer SOL and custom tokens between wallets
- **Token Operations**: Create SPL tokens, mint tokens, and manage token accounts
- **Cluster Management**: Switch between Solana clusters and check cluster availability
- **Developer Friendly**: Designed to work with `solana-test-validator` for local development

## Prerequisites

- Solana CLI tools (`solana`, `solana-keygen`, `spl-token`)
- Bash shell environment
- For local development: Docker with `solana-test-validator`

## Installation

1. Download the script:

```bash
curl -O https://raw.githubusercontent.com/yourusername/solana-wallet-manager/main/solana-wallet-manager.sh
```

2. Make it executable:

```bash
chmod +x solana-wallet-manager.sh
```

3. (Optional) For easier access, you can move it to a directory in your PATH:

```bash
sudo mv solana-wallet-manager.sh /usr/local/bin/solana-wallet-manager
```

## Setup and Configuration

### Setting Up a Local Validator

Start a local Solana validator in Docker:

```bash
docker run -ti \
  --name solana-test-validator \
  -p 8899:8899 \
  -p 8900:8900 \
  -p 8001:8001 \
  -v ~/dev:/working-dir:rw \
  --rm \
  tchambard/solana-test-validator:latest \
  solana-test-validator
```

## Customizing Environment Settings

### Wallet Directory Location

By default, the script stores all wallets and related files in `$HOME/solana-wallets/`. To change this location:

1. Open the script in your text editor:
   ```bash
   nano solana-wallet-manager.sh
   ```

2. Find and modify the `WALLETS_DIR` variable near the top of the file:
   ```bash
   # Base directory for storing wallets and recipients
   WALLETS_DIR="/your/custom/path"
   ```

3. The script will automatically create this directory if it doesn't exist.

### Changing Default Cluster

The script defaults to local validator (`http://localhost:8899`). To change the default:

1. Edit the script and modify the `CURRENT_CLUSTER` variable:
   ```bash
   CURRENT_CLUSTER="https://api.devnet.solana.com"  # Change to your preferred default
   ```

2. Available options include:
   - `http://localhost:8899` (Local)
   - `https://api.devnet.solana.com` (Devnet)
   - `https://api.testnet.solana.com` (Testnet)
   - `https://api.mainnet-beta.solana.com` (Mainnet)
   - Any custom RPC URL

You can also change the cluster at runtime without modifying the script:
```bash
./solana-wallet-manager.sh set-cluster devnet
```


This snippet provides clear instructions for customizing the two most important environment settings: the wallet directory location and the default cluster URL.

## Usage

### Basic Commands

```bash
# Get help
./solana-wallet-manager.sh help

# Set to local cluster
./solana-wallet-manager.sh set-cluster local

# Check if cluster is available
./solana-wallet-manager.sh check-cluster

# Create a wallet
./solana-wallet-manager.sh create-wallet wallet1

# List all wallets
./solana-wallet-manager.sh list-wallets

# Select a wallet
./solana-wallet-manager.sh use-wallet wallet1

# Check wallet balance
./solana-wallet-manager.sh show-balance

# Airdrop SOL to wallet (only works on test networks)
./solana-wallet-manager.sh airdrop 1 wallet1
```

### Managing Recipients

```bash
# Add an address as a named recipient
./solana-wallet-manager.sh add-recipient exchange 9xDUcfd3uKKFkZfcFYM7UpREf8dYUBZ3Rh6GQKJyzuZU

# List all saved recipients
./solana-wallet-manager.sh list-recipients
```

### Transferring SOL

```bash
# Transfer SOL to another wallet
./solana-wallet-manager.sh transfer 0.5 wallet2

# Transfer SOL to a saved recipient
./solana-wallet-manager.sh transfer 0.5 exchange

# Transfer SOL to a direct address
./solana-wallet-manager.sh transfer 0.5 9xDUcfd3uKKFkZfcFYM7UpREf8dYUBZ3Rh6GQKJyzuZU
```

### SPL Token Operations

#### Understanding Token Keypairs and Roles

When working with Solana tokens, it's important to understand the different roles and keypairs involved:

1. **Mint Authority Keypair**: Controls who can mint (create) new tokens. This is the keypair used during token creation.
2. **Wallet Keypair**: Your wallet that pays for transactions and can own tokens.
3. **Token Account**: An account associated with a wallet that can hold a specific token.

The script manages these keypairs for you:
- During token creation, a new keypair is generated specifically for the token mint
- This token keypair becomes the mint authority
- Your wallet keypair is used as the fee payer for all transactions
- Token accounts are automatically created for your wallet

#### Token Commands

```bash
# Create a new SPL token
# This creates a token mint keypair and makes your current wallet the fee payer
./solana-wallet-manager.sh create-token "My Token" MTK 9
#                                         Name    Symbol Decimals

# Mint tokens to your wallet
# Uses your current wallet as fee payer and recipient
./solana-wallet-manager.sh mint-token MTK 1000
#                                     Symbol Amount

# Transfer tokens to another wallet
# Automatically creates recipient token account if needed
./solana-wallet-manager.sh transfer-token MTK 500 wallet2
#                                        Symbol Amount Recipient

# List all tokens in wallet
./solana-wallet-manager.sh list-tokens
```

## Example Workflow

Here's a complete workflow for creating wallets, tokens, and transferring between them:

```bash
# Start your validator in another terminal
docker run -ti --name solana-test-validator -p 8899:8899 -p 8900:8900 -p 8001:8001 -v ~/dev:/working-dir:rw --rm tchambard/solana-test-validator:latest solana-test-validator

# Set local cluster
./solana-wallet-manager.sh set-cluster local

# Verify cluster is running
./solana-wallet-manager.sh check-cluster

# Create wallets
./solana-wallet-manager.sh create-wallet wallet1
./solana-wallet-manager.sh create-wallet wallet2

# Airdrop SOL to wallets
./solana-wallet-manager.sh airdrop 2 wallet1
./solana-wallet-manager.sh airdrop 1 wallet2

# Transfer SOL between wallets
./solana-wallet-manager.sh use-wallet wallet1
./solana-wallet-manager.sh transfer 0.5 wallet2

# Create a token
./solana-wallet-manager.sh create-token "Example Token" EXTKN 6

# Mint and transfer tokens
./solana-wallet-manager.sh mint-token EXTKN 1000
./solana-wallet-manager.sh transfer-token EXTKN 500 wallet2

# Add an external recipient
./solana-wallet-manager.sh add-recipient friend H9jwtuKnD63iRQBPXdYbGjekfwzAoqWBcJaqdgx1QcV4

# Transfer to external recipient
./solana-wallet-manager.sh transfer 0.1 friend
```

## Token Management Behind the Scenes

When you run `create-token`, the script:

1. Generates a new keypair file (e.g., `~/solana-wallets/wallet1/tokens/MTK_keypair.json`)
2. This keypair becomes the mint authority for the token
3. Sets your current wallet as the default fee payer in Solana config
4. Creates the token with the specified decimals
5. Creates a token account in your wallet for this new token
6. Stores token metadata in JSON format (`~/solana-wallets/wallet1/tokens/MTK.json`)

When you run `mint-token`, the script:
1. Uses your current wallet as the default signer
2. Finds the token mint authority keypair from your wallet's tokens directory
3. Mints the specified amount to a token account in your wallet

When you run `transfer-token`, the script:
1. Sets your current wallet as the default signer
2. Automatically creates a token account for the recipient if needed (using the `--fund-recipient` flag)
3. Transfers the tokens to the recipient's token account

## File Structure

The script creates the following directory structure:

```
~/solana-wallets/              # Base directory for all wallets
├── current_wallet             # File storing the name of the currently selected wallet
├── recipients/                # Directory for stored recipient addresses
│   ├── exchange               # Example recipient
│   └── friend                 # Example recipient
├── wallet1/                   # Directory for wallet1
│   ├── keypair.json           # Wallet keypair
│   └── tokens/                # Directory for tokens created by this wallet
│       ├── MTK.json           # Information about created token
│       └── MTK_keypair.json   # Token mint authority keypair
└── wallet2/                   # Directory for wallet2
    └── keypair.json           # Wallet keypair
```

## Cluster Options

Available clusters:

- `local` - Local test validator (http://localhost:8899)
- `devnet` - Solana Devnet (https://api.devnet.solana.com)
- `testnet` - Solana Testnet (https://api.testnet.solana.com)
- `mainnet` - Solana Mainnet (https://api.mainnet-beta.solana.com)
- Any custom URL

## Technical Implementation Details

### Token Creation Process

1. **Generating token keypair**: Creates a unique keypair that serves as the token mint
   ```bash
   solana-keygen new -o "$token_keypair_file" --no-bip39-passphrase --force
   ```

2. **Creating the token**: Uses the keypair to create a new SPL token with specified decimals
   ```bash
   spl-token create-token --decimals "$token_decimals" "$token_keypair_file"
   ```

3. **Creating token account**: Creates an account in your wallet that can hold this token
   ```bash
   spl-token create-account "$token_address"
   ```

### Token Transfer Process

The token transfer function handles multiple scenarios:
- Transfers between known wallets managed by the script
- Transfers to external addresses
- Automatic creation of recipient token accounts when needed

During a transfer, if the recipient doesn't have a token account yet, the script:
```bash
spl-token transfer --allow-unfunded-recipient --fund-recipient "$token_address" "$amount" "$recipient_address"
```

## Notes

- This script is designed for development and testing purposes.
- For production use cases, consider proper key management and security practices.
- The script stores keypairs in plain JSON files. For production, use hardware wallets or more secure storage methods.
- The script automatically handles Solana configuration changes during operations and restores your original configuration when done.

## Troubleshooting

### Common Issues

1. **"No wallet selected"** error:
   - Use `use-wallet <wallet-name>` to select a wallet before operations.

2. **Transfer fails**:
   - Ensure you have sufficient balance with `show-balance`.
   - Check that the recipient address is correct.
   - Verify the cluster is available with `check-cluster`.

3. **Airdrop fails**:
   - Airdrops only work on test networks and localnet.
   - There are rate limits on devnet/testnet airdrops.

4. **Token creation fails**:
   - Ensure you have sufficient SOL for the transaction fees.
   - Check that the cluster is available.
   - Verify your wallet has been properly selected with `use-wallet`.

5. **"Default signer required" error**:
   - The script will handle this automatically by temporarily setting your wallet as the default signer.

### Specific Solana CLI Errors

1. **"Error: Recipient's associated token account does not exist"**:
   - The script now automatically handles this by using the `--fund-recipient` flag.

2. **"Error: Found argument '-k' which wasn't expected"**:
   - This is handled internally by using Solana configuration instead of command-line flags.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.