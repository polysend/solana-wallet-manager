# Solana Wallet Manager with IPFS Integration

A comprehensive bash script for managing Solana wallets, addresses, tokens, and transactions in development environments, with full IPFS support for token metadata storage.

## Features

- **Wallet Management**: Create, list, and select wallets
- **Address Management**: Store and manage recipient addresses
- **Transaction Support**: Transfer SOL and custom tokens between wallets
- **Token Operations**: Create SPL tokens, mint tokens, and manage token accounts
- **IPFS Integration**: Upload token metadata and images to IPFS with automatic pinning
- **Metaplex Support**: Create tokens with full Metaplex-compatible metadata
- **Cluster Management**: Switch between Solana clusters and check cluster availability
- **Developer Friendly**: Designed to work with `solana-test-validator` for local development

## Prerequisites

- **Solana CLI tools** (`solana`, `solana-keygen`, `spl-token`)
- **Metaboss** - For creating Metaplex-compatible token metadata ([Install from releases](https://github.com/samuelvanderwaal/metaboss/releases))
- **Bash shell environment**
- **IPFS node access** (see IPFS Setup section below)
- For local development: Docker with `solana-test-validator`
- Optional: `jq` for better JSON formatting in metadata display

### Installing Metaboss

Metaboss is required for creating tokens with Metaplex-compatible metadata. Install it from the official releases:

**macOS (Apple Silicon):**
```bash
curl -L https://github.com/samuelvanderwaal/metaboss/releases/download/v0.44.0/metaboss-macos-m1-latest -o metaboss
chmod +x metaboss
sudo mv metaboss /usr/local/bin/
```

**macOS (Intel):**
```bash
curl -L https://github.com/samuelvanderwaal/metaboss/releases/download/v0.44.0/metaboss-macos-latest -o metaboss
chmod +x metaboss
sudo mv metaboss /usr/local/bin/
```

**Linux:**
```bash
curl -L https://github.com/samuelvanderwaal/metaboss/releases/download/v0.44.0/metaboss-linux-latest -o metaboss
chmod +x metaboss
sudo mv metaboss /usr/local/bin/
```

**Windows:**
Download the appropriate binary from [Metaboss Releases](https://github.com/samuelvanderwaal/metaboss/releases) and add it to your PATH.

Verify installation:
```bash
metaboss --version
```

For other installation methods and the latest releases, see the [official Metaboss repository](https://github.com/samuelvanderwaal/metaboss).

## IPFS Requirements and Setup

### IPFS Node Access

This script requires access to an IPFS node for metadata storage. You have several options:

#### Option 1: Local IPFS Node (Recommended for Development)

1. **Install IPFS**:
   ```bash
   # Using Docker (easiest)
   docker run -d --name ipfs-node \
     -p 4001:4001 -p 5001:5001 -p 8080:8080 \
     ipfs/go-ipfs:latest
   ```

2. **Configure the script**: The script is currently hardcoded to use:
   - IPFS API: `http://100.124.40.90:5001`
   - IPFS Gateway: `http://100.124.40.90:8080`

3. **Update the configuration** in the script to match your setup:
   ```bash
   # Edit these lines in the script to match your IPFS node
   IPFS_API_URL="http://localhost:5001"        # Your IPFS API endpoint
   IPFS_GATEWAY_URL="http://localhost:8080"    # Your IPFS gateway endpoint
   ```

#### Option 2: Remote IPFS Node

If you have access to a remote IPFS node:

1. Update the configuration variables in the script:
   ```bash
   IPFS_API_URL="http://your-ipfs-node:5001"
   IPFS_GATEWAY_URL="http://your-ipfs-node:8080"
   ```

#### Option 3: IPFS Service Providers

For production use, consider services like:
- Pinata (https://pinata.cloud)
- Infura IPFS (https://infura.io/product/ipfs)
- NFT.Storage (https://nft.storage)

**Note**: Using external services requires modifying the upload functions to use their APIs instead of the local IPFS API calls. Additionally, MFS (Web UI organization) features will not work with external services - only basic upload/pinning functionality will be available.

### IPFS Configuration Notes

- The script expects the IPFS API to be available without authentication
- All uploads are automatically pinned to prevent garbage collection
- The script maintains a local registry of uploads for human-readable naming
- IPFS content is addressed by hash, ensuring immutability
- **MFS (Mutable File System) directory structure is local only** - it organizes files in your IPFS Web UI but doesn't propagate to other nodes
- Token metadata remains globally accessible via IPFS hashes regardless of local organization

## Installation

1. Download the script:

```bash
curl -O https://raw.githubusercontent.com/yourusername/solana-wallet-manager/main/solana-wallet-manager.sh
```

2. Make it executable:

```bash
chmod +x solana-wallet-manager.sh
```

3. **Configure IPFS endpoints** by editing the script and updating these variables:
   ```bash
   IPFS_API_URL="http://your-ipfs-api:5001"
   IPFS_GATEWAY_URL="http://your-ipfs-gateway:8080"
   ```

4. (Optional) For easier access, you can move it to a directory in your PATH:

```bash
sudo mv solana-wallet-manager.sh /usr/local/bin/solana-wallet-manager
```

## Setup and Configuration

### Setting Up a Local Validator with Metaplex Support

To support token metadata, your local validator needs the Metaplex Token Metadata program. Start it with:

```bash
# Option 1: Using systemd (if configured)
systemctl stop solana-local
rm -rf /opt/solana-local/ledger  # Clean slate
systemctl start solana-local    # Should include Metaplex cloning

# Option 2: Manual start with Metaplex
solana-test-validator \
  --ledger /path/to/ledger \
  --clone metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s \
  --clone PwDiXFxQsGra4sFFTT8r1QWRMd4vfumiWC1jfWNfdYT \
  --url https://api.devnet.solana.com \
  --rpc-bind-address 0.0.0.0
```

The cloned programs are:
- `metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s` - Token Metadata Program
- `PwDiXFxQsGra4sFFTT8r1QWRMd4vfumiWC1jfWNfdYT` - Token Auth Rules Program

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
./solana-wallet-manager.sh set-cluster testnet
./solana-wallet-manager.sh set-cluster mainnet
./solana-wallet-manager.sh set-cluster local

# Or use a custom RPC URL directly
./solana-wallet-manager.sh set-cluster https://my-custom-rpc.com
./solana-wallet-manager.sh set-cluster http://192.168.1.100:8899
```

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

### IPFS Operations

```bash
# Upload a file to IPFS with optional name
./solana-wallet-manager.sh upload-to-ipfs logo.png "My Token Logo"

# View all IPFS uploads with names (local registry)
./solana-wallet-manager.sh list-ipfs-uploads

# View raw IPFS pins (what IPFS actually stores)
./solana-wallet-manager.sh list-ipfs-pins
```

### Advanced Token Creation with Metadata

```bash
# Create a token with full IPFS metadata
./solana-wallet-manager.sh create-token-with-metadata \
  "My Awesome Token" \
  "MAT" \
  9 \
  logo.png \
  "A token with rich metadata stored on IPFS" \
  "https://myproject.com"

# View the metadata
./solana-wallet-manager.sh show-token-metadata MAT

# The script will:
# 1. Upload logo.png to IPFS
# 2. Create Metaplex-compatible metadata JSON
# 3. Upload metadata JSON to IPFS  
# 4. Create the SPL token
# 5. Create on-chain metadata using metaboss
# 6. Store all IPFS URIs for future reference
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

# Transfer with memo
./solana-wallet-manager.sh transfer-with-memo 0.5 wallet2 "Payment for services"
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

#### Basic Token Commands

```bash
# Create a simple SPL token (no metadata)
./solana-wallet-manager.sh create-token "Basic Token" BTK 9

# Create a token with full IPFS metadata
./solana-wallet-manager.sh create-token-with-metadata "Rich Token" RTK 9 logo.png "Description"

# Mint tokens to your wallet
./solana-wallet-manager.sh mint-token RTK 1000

# Transfer tokens to another wallet
./solana-wallet-manager.sh transfer-token RTK 500 wallet2

# List all tokens in wallet
./solana-wallet-manager.sh list-tokens

# Show detailed metadata for a token
./solana-wallet-manager.sh show-token-metadata RTK
```

## Example Workflow with IPFS

Here's a complete workflow for creating wallets, tokens with metadata, and transferring between them:

```bash
# 1. Ensure IPFS is running and accessible
curl -X POST http://localhost:5001/api/v0/version  # Test IPFS connectivity

# 2. Start your validator with Metaplex support
solana-test-validator \
  --clone metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s \
  --url https://api.devnet.solana.com

# 3. Set local cluster
./solana-wallet-manager.sh set-cluster local

# 4. Verify cluster is running
./solana-wallet-manager.sh check-cluster

# 5. Create wallets
./solana-wallet-manager.sh create-wallet wallet1
./solana-wallet-manager.sh create-wallet wallet2

# 6. Airdrop SOL to wallets
./solana-wallet-manager.sh airdrop 2 wallet1
./solana-wallet-manager.sh airdrop 1 wallet2

# 7. Create a token with rich metadata
./solana-wallet-manager.sh use-wallet wallet1
./solana-wallet-manager.sh create-token-with-metadata \
  "Community Token" \
  "COMM" \
  6 \
  community-logo.png \
  "A token for our awesome community" \
  "https://community.example.com"

# 8. Mint and transfer tokens
./solana-wallet-manager.sh mint-token COMM 10000
./solana-wallet-manager.sh transfer-token COMM 5000 wallet2

# 9. View the rich metadata
./solana-wallet-manager.sh show-token-metadata COMM

# 10. Check your IPFS uploads
./solana-wallet-manager.sh list-ipfs-uploads
```

## File Structure

The script creates the following directory structure:

```
~/solana-wallets/              # Base directory for all wallets
├── current_wallet             # File storing the name of the currently selected wallet
├── ipfs/                      # IPFS upload registry
│   └── uploads.json           # Local registry of IPFS uploads with names
├── recipients/                # Directory for stored recipient addresses
│   ├── exchange               # Example recipient
│   └── friend                 # Example recipient
├── wallet1/                   # Directory for wallet1
│   ├── keypair.json           # Wallet keypair
│   └── tokens/                # Directory for tokens created by this wallet
│       ├── COMM.json          # Enhanced token info with metadata URIs
│       └── COMM_keypair.json  # Token mint authority keypair
└── wallet2/                   # Directory for wallet2
    └── keypair.json           # Wallet keypair
```

### Enhanced Token Metadata Structure

When you create tokens with metadata, the token JSON files contain:

```json
{
  "name": "Community Token",
  "symbol": "COMM",
  "decimals": 6,
  "address": "TokenAddressHere...",
  "keypair": "COMM_keypair.json",
  "metadata_uri": "http://gateway:8080/ipfs/QmMetadataHash...",
  "image_uri": "http://gateway:8080/ipfs/QmImageHash...",
  "description": "A token for our awesome community",
  "external_url": "https://community.example.com",
  "created_at": "2025-05-22T13:47:38Z"
}
```

## IPFS Integration Details

### How IPFS Integration Works

1. **File Upload**: Images and metadata are uploaded to IPFS via the API
2. **Automatic Pinning**: All content is automatically pinned to prevent garbage collection
3. **Local Registry**: The script maintains a local database of uploads with human-readable names
4. **Metaplex Compatibility**: Metadata follows Metaplex standards for maximum compatibility

### IPFS Metadata Structure

The script creates metadata JSON following the Metaplex standard:

```json
{
  "name": "Token Name",
  "symbol": "SYMBOL",
  "description": "Token description",
  "image": "ipfs://QmImageHash...",
  "external_url": "https://project.com",
  "attributes": [],
  "properties": {
    "category": "fungible",
    "creators": []
  }
}
```

### IPFS Configuration Requirements

The script expects:
- IPFS API accessible via HTTP POST requests
- No authentication required (development setup)
- Standard IPFS API endpoints (`/api/v0/add`, `/api/v0/pin/ls`, etc.)
- Gateway accessible for content retrieval
- **MFS (Mutable File System) support for Web UI organization** - works with standard IPFS nodes (go-ipfs/kubo) but not external services like Pinata

## Cluster Options

Available clusters:

- `local` - Local test validator (http://localhost:8899)
- `devnet` - Solana Devnet (https://api.devnet.solana.com)
- `testnet` - Solana Testnet (https://api.testnet.solana.com)
- `mainnet` - Solana Mainnet (https://api.mainnet-beta.solana.com)
- **Custom URL** - Any custom RPC endpoint (e.g., `https://my-rpc.com`, `http://192.168.1.100:8899`)

### Examples of Custom Cluster Usage

```bash
# Switch to a custom RPC provider
./solana-wallet-manager.sh set-cluster https://my-custom-rpc.solana.com

# Use a local validator on a different port
./solana-wallet-manager.sh set-cluster http://localhost:8900

# Connect to a validator on your local network
./solana-wallet-manager.sh set-cluster http://192.168.1.119:8899

# Verify the cluster is working
./solana-wallet-manager.sh check-cluster
```

## Technical Implementation Details

### Token Creation Process

1. **Generating token keypair**: Creates a unique keypair that serves as the token mint
   ```bash
   solana-keygen new -o "$token_keypair_file" --no-bip39-passphrase --force
   ```

2. **IPFS Upload (if metadata provided)**:
   - Upload image to IPFS
   - Create Metaplex-compatible metadata JSON
   - Upload metadata JSON to IPFS

3. **Creating the token**: Uses the keypair to create a new SPL token with specified decimals
   ```bash
   spl-token create-token --decimals "$token_decimals" "$token_keypair_file"
   ```

4. **Creating token account**: Creates an account in your wallet that can hold this token
   ```bash
   spl-token create-account "$token_address"
   ```

5. **Creating on-chain metadata**: Uses metaboss to create Metaplex-compatible metadata
   ```bash
   metaboss create metadata --keypair "$wallet_keypair" --mint "$token_address" --metadata "$metadata_file"
   ```

### IPFS Upload Process

1. **File validation**: Ensures file exists and is accessible
2. **Upload to IPFS**: Uses curl to POST to IPFS API
3. **Pin content**: Automatically pins to prevent garbage collection
4. **Registry update**: Adds entry to local registry with human-readable name
5. **MFS organization**: Copies files to Web UI directory structure (local node only)
6. **Return hash**: Provides IPFS hash for metadata creation

**Important**: The MFS directory structure (`/solana-wallet-manager/uploads/`, `/solana-wallet-manager/tokens/`) only exists on your local IPFS node for Web UI organization. Other IPFS nodes and applications (like Metaplex) access content directly via IPFS hashes, ensuring global accessibility regardless of your local file organization.

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
- **IPFS endpoints are hardcoded** - you must modify the script to match your IPFS setup.
- For production use cases, consider proper key management and security practices.
- The script stores keypairs in plain JSON files. For production, use hardware wallets or more secure storage methods.
- The script automatically handles Solana configuration changes during operations and restores your original configuration when done.
- IPFS content is immutable once uploaded - metadata cannot be changed after creation.

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

6. **"metaboss not found"**:
   - Install metaboss from the [official releases](https://github.com/samuelvanderwaal/metaboss/releases).
   - Ensure metaboss is in your PATH and executable with `metaboss --version`.

### IPFS-Specific Issues

1. **"Failed to upload to IPFS"**:
   - Check if IPFS node is running: `curl -X POST http://your-ipfs:5001/api/v0/version`
   - Verify the IPFS_API_URL is correctly configured in the script
   - Ensure the IPFS API is accessible from your machine

2. **"IPFS pins show empty names"**:
   - This is normal - IPFS doesn't support named pins natively
   - Use `list-ipfs-uploads` instead for human-readable names

3. **"Metadata not accessible"**:
   - Check if IPFS gateway is running: `curl http://your-gateway:8080/ipfs/QmSomeHash`
   - Verify the IPFS_GATEWAY_URL is correctly configured

4. **"Image not displaying in wallets"**:
   - Ensure the IPFS gateway is publicly accessible if using external wallets
   - Some wallets may require HTTPS gateways for security

5. **"Files don't appear in IPFS Web UI"**:
   - Files uploaded via API don't automatically appear in the Web UI's Files section
   - The script copies files to MFS for Web UI visibility in organized folders
   - This organization is local to your node only and doesn't affect global accessibility

### Specific Solana CLI Errors

1. **"Error: Recipient's associated token account does not exist"**:
   - The script now automatically handles this by using the `--fund-recipient` flag.

2. **"Error: Found argument '-k' which wasn't expected"**:
   - This is handled internally by using Solana configuration instead of command-line flags.

3. **"Program metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s not found"**:
   - Your validator doesn't have the Metaplex program. Restart with cloning enabled.

4. **"Failed to create on-chain metadata with metaboss"**:
   - Ensure metaboss is installed and in your PATH
   - Check that your validator has the Metaplex Token Metadata program
   - Verify you have sufficient SOL for the metadata creation transaction

## Security Considerations

### Development vs Production

This script is designed for development environments with the following assumptions:
- IPFS node is trusted and local
- No authentication required for IPFS access
- Keypairs stored in plain files for convenience

### For Production Use

Consider these modifications:
- Use authenticated IPFS services (Pinata, Infura)
- Implement proper key management (hardware wallets, key management services)
- Add input validation and sanitization
- Use HTTPS for all IPFS interactions
- Implement backup and recovery procedures for keypairs and metadata

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. When contributing IPFS-related features, please ensure they work with standard IPFS API endpoints.