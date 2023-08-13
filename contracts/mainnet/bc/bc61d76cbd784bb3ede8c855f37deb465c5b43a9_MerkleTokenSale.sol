// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";

/// @title MerkleTokenSale
/// @notice Allows tokens to be exchanged at a fixed rate with the sell amount per address 
/// capped via merkle tree
/// @author Chris Dev <[email protected]>
/// @dev tokens sold via this contract should be considered burnt as they are non recoverable
contract MerkleTokenSale is ReentrancyGuard {

    /// @notice token exchange calculations are done with an exchange rate with this precision
    uint256 constant public EXCHANGE_RATE_PRECISION = 1e18;

    /// @notice maximum sellable amount per address is defined in this merkle tree
    bytes32 public merkleRoot;

    /// @notice address of ERC20 token sold via this contract
    address public sellToken;

    /// @notice address of ERC20 token bought via this contract
    address[] public buyTokens;

    /// @notice amount of tokens available to buy from this contract
    /// @dev this increases when admin deposits and decreases when tokens are bought or recovered by admin address
    mapping(address => uint256) public buyTokenBalances;

    /// @notice amount of sellTokens received per 1 buyToken, raised to 10**18
    /// @dev must be same precision as EXCHANGE_RATE_PRECISION
    mapping(address => uint256) public buyTokenExchangeRates;

    /// @notice buy token decimals used for exchange amount calculations
    mapping(address => uint8) public buyTokenDecimals;

    /// @notice sell token decimals used for exchange amount calculations
    uint8 public sellTokenDecimals;

    /// @notice total sum of all tokens sold to this contract
    /// @dev tokens in excess of this amount can be recovered by admin address
    uint256 public totalSellTokensSold;

    /// @notice address that can perform admin functionality
    /// @dev this address must be non-zero on contract creation but can be set to 0 after deployment
    address public adminAddress;

    /// @notice keeps track of amounts that addresses have sold to date
    /// @dev this is used to prevent users from selling more than they are allowed to (over potentially multiple sales)
    mapping(address => uint256) public userSoldAmounts;

    /// @notice emitted when the admin address is initially set and when updated
    event AdminSet(
        address indexed adminAddress
    );

    /// @notice emitted when the merkle root is initially set and when updated
    event MerkleRootSet(
        bytes32 indexed merkleRoot
    );

    /// @notice emitted when the exchange rates are initially set and when updated
    event ExchangeRateSet(
        address indexed token,
        uint256 indexed exchangeRate
    );

    /// @notice emitted once per buy token when a sale is made
    event Sell(
        address indexed seller,
        address indexed buyToken,
        uint256 indexed buyAmount
    );

    /// @notice emitted when buy token is deposited
    event Deposit(
        address indexed token,
        uint256 indexed amount
    );

    /// @notice thrown when attempting to sell 0 tokens
    error InvalidSellAmount();

    /// @notice thrown when attempting to sell more tokens than allowed as per merkle tree
    error MaxSellableExceeded();

    /// @notice thrown when invalid merkle proof is provided during claim
    error InvalidMerkleProof();

    /// @notice thrown when non-admin address attempts to call admin functions
    error Unauthorised();

    /// @notice thrown when supplying 0 address for sellToken
    error InvalidSellToken();

    /// @notice thrown when supplying 0 address for buyToken
    error InvalidBuyToken();

    /// @notice thrown when number of buy tokens does not match number of exchange rates
    error BuyTokenCountMismatch();

    /// @notice thrown when supplying 0 address for adminAddress (only at contract creation)
    error InvalidAdminAddress();

    /// @notice thrown when supplying an exchangeRate of 0
    error InvalidExchangeRate();
    
    /// @notice thrown when calculated buyAmount is rounded to 0 due to small sellAmount
    error SellAmountTooSmall();

    /// @notice thrown when calculated buyAmount exceeds the current amount of buyTokens available
    error SellAmountTooBig();

    /// @notice thrown when there are no tokens available to claim
    error NoTokensToClaim();

    /// @notice thrown when there are no excess tokens available to recover by admin
    error NoTokensToRecover();

    /// @notice thrown when attempting to recover sellToken via generic recoverERC20 function
    error CannotRecoverSellToken();

    /// @notice thrown when attempting to recover buyToken via generic recoverERC20 function
    error CannotRecoverBuyToken();

    /// @notice thrown when attempting to send ETH to this contract via fallback method
    error FallbackNotPayable();
    
    /// @notice thrown when attempting to send ETH to this contract via receive method
    error ReceiveNotPayable();

    /// @notice ensures only admin address can call admin functions
    modifier onlyAdmin() {
        if(msg.sender != adminAddress) revert Unauthorised();
        _;
    }

    /// @notice creates a new MerkleTokenSale instance
    /// @param _sellToken address of token to sell to this contract
    /// @param _buyTokens addresses of tokens to buy from this contract
    /// @param _exchangeRates exchange rates of all tokens bought from this contract
    /// @param _adminAddress address allowed to call admin functions
    /// @param _merkleRoot root of merkle tree containg maximum sellable amount per address
    constructor(
        address _sellToken,
        address[] memory _buyTokens,
        uint256[] memory _exchangeRates,
        address _adminAddress,
        bytes32 _merkleRoot
    ) {
        if(_sellToken == address(0)) revert InvalidSellToken();
        sellToken = _sellToken;
        sellTokenDecimals = ERC20(_sellToken).decimals();

        if(_buyTokens.length != _exchangeRates.length) revert BuyTokenCountMismatch();

        for(uint256 i = 0; i < _buyTokens.length; i++) {
            address tokenAddress = _buyTokens[i];
            uint256 exchangeRate = _exchangeRates[i];
            if(tokenAddress == address(0)) revert InvalidBuyToken();
            if(tokenAddress == _sellToken) revert InvalidBuyToken();
            if(exchangeRate == 0) revert InvalidExchangeRate();

            buyTokens.push(tokenAddress);
            buyTokenDecimals[tokenAddress] = ERC20(tokenAddress).decimals();
            buyTokenExchangeRates[tokenAddress] = exchangeRate;
            emit ExchangeRateSet(tokenAddress, exchangeRate);
        }

        if(_adminAddress == address(0)) revert InvalidAdminAddress();
        adminAddress = _adminAddress;
        emit AdminSet(_adminAddress);

        merkleRoot = _merkleRoot;
        emit MerkleRootSet(_merkleRoot);
    }

    /// @notice validates the amount being sold against merkle proof and amount already sold to the contract
    /// @param sellAmount amount to be sold
    /// @param maxSellable maximum amount allow to sell as per merkle tree
    /// @param proof merkle proof containing address and maximum sell amount
    function _validateSellAmount(
        uint256 sellAmount, 
        uint256 maxSellable, 
        bytes32[] calldata proof
    ) private view {
        if(sellAmount == 0) revert InvalidSellAmount();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxSellable));
        bool isValidLeaf = MerkleProofLib.verify(proof, merkleRoot, leaf);
        if (!isValidLeaf) revert InvalidMerkleProof();
        
        // prevent user from selling more than they are allowed to
        if (sellAmount > maxSellable - userSoldAmounts[msg.sender]) revert MaxSellableExceeded();
    }

    /// @notice sells an amount of sellAmount to the contract and received buyToken in return
    /// @param sellAmount amount to be sold
    /// @param maxSellable maximum amount allow to sell as per merkle tree
    /// @param proof merkle proof containing address and maximum sell amount
    function claimSale(uint256 sellAmount, uint256 maxSellable, bytes32[] calldata proof) public nonReentrant {
        _validateSellAmount(sellAmount, maxSellable, proof);

        // update sold amounts/transfer sell token from the seller once
        // and not in the loop body
        totalSellTokensSold += sellAmount;
        userSoldAmounts[msg.sender] += sellAmount;
        ERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount);

        for(uint256 i = 0; i < buyTokens.length; i++) {
            address _buyTokenAddress = buyTokens[i];
            uint256 _buyTokenDecimals = buyTokenDecimals[_buyTokenAddress];
            uint256 _buyTokenBalance = buyTokenBalances[_buyTokenAddress];
            uint256 _buyTokenExchangeRate = buyTokenExchangeRates[_buyTokenAddress];

            uint256 normalisedSellAmount = _buyTokenDecimals == sellTokenDecimals
                ? sellAmount // same decimals, no normalising needed
                : sellTokenDecimals > _buyTokenDecimals
                ? sellAmount / (10 ** (sellTokenDecimals - _buyTokenDecimals)) // sellTokenDecimals > _buyTokenDecimals
                : sellAmount * (10 ** (_buyTokenDecimals - sellTokenDecimals)); // sellTokenDecimals < buyTokenDecimals

            uint256 buyAmount = normalisedSellAmount * _buyTokenExchangeRate / EXCHANGE_RATE_PRECISION;

            // CHECKS
            if(buyAmount == 0) revert SellAmountTooSmall();
            if(buyAmount > _buyTokenBalance) revert SellAmountTooBig();

            // EFFECTS
            buyTokenBalances[_buyTokenAddress] -= buyAmount;

            // INTERACTIONS
            ERC20(_buyTokenAddress).transfer(msg.sender , buyAmount);

            emit Sell(msg.sender, _buyTokenAddress, buyAmount);
        }
    }

    /// @notice deposits an amount of buyToken from the sender to this contract and makes them available for buying
    /// @dev increments buyTokenBalance
    /// @param tokenAddress address of buy token
    /// @param depositAmount amount of tokens to deposit
    function depositBuyToken(address tokenAddress, uint256 depositAmount) public onlyAdmin {
        if(tokenAddress == address(0)) revert InvalidBuyToken();
        if(buyTokenExchangeRates[tokenAddress] == 0) revert InvalidBuyToken();
        if(tokenAddress == sellToken) revert InvalidBuyToken();

        buyTokenBalances[tokenAddress] += depositAmount;
        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            depositAmount
        );

        emit Deposit(tokenAddress, depositAmount);
    }

    /// @notice sets a new exchange rate for the given token
    /// @param newExchangeRate new exchange rate
    function setExchangeRate(address tokenAddress, uint256 newExchangeRate) public onlyAdmin {
        if(tokenAddress == address(0)) revert InvalidBuyToken();
        if(buyTokenExchangeRates[tokenAddress] == 0) revert InvalidBuyToken();
        if(newExchangeRate == 0) revert InvalidExchangeRate();

        buyTokenExchangeRates[tokenAddress] = newExchangeRate;
        emit ExchangeRateSet(tokenAddress, newExchangeRate);
    }

    /// @notice sets a new merkle tree root
    /// @param newMerkleRoot new merkle tree root
    function setMerkleRoot(bytes32 newMerkleRoot) public onlyAdmin {
        merkleRoot = newMerkleRoot;
        emit MerkleRootSet(newMerkleRoot);
    }

    /// @notice sets a new admin address
    /// @param newAdminAddress new admin address
    function setAdminAddress(address newAdminAddress) public onlyAdmin {
        adminAddress = newAdminAddress;
        emit AdminSet(newAdminAddress);
    }

    /// @notice transfers any sellToken in excess of totalSellTokensSold to the admin address
    function recoverSellToken() public onlyAdmin nonReentrant {
        uint256 tokenBalance = ERC20(sellToken).balanceOf(address(this));

        // treat tokens sold as burnt, this means they are unrecoverable from this contract
        // this imitates burning sell tokens that implement NonBurnable and cannot actually be burnt
        if(totalSellTokensSold >= tokenBalance) revert NoTokensToRecover();

        ERC20(sellToken).transfer(
            adminAddress,
            tokenBalance - totalSellTokensSold
        );
    }

    /// @notice transfers full buyToken balance to the admin address
    /// @dev resets buyTokenBalance for the given token to 0
    function recoverBuyToken(address tokenAddress) public onlyAdmin nonReentrant {
        if(tokenAddress == address(0)) revert InvalidBuyToken();
        if(tokenAddress == sellToken) revert CannotRecoverSellToken();

        uint256 recoverableAmount = ERC20(tokenAddress).balanceOf(address(this));

        if(recoverableAmount == 0) revert NoTokensToRecover();

        buyTokenBalances[tokenAddress] = 0;
        ERC20(tokenAddress).transfer(adminAddress, recoverableAmount);
    }

    /// @notice transfers token balance to admin address if the token is not a buyToken or the sellToken
    /// @param tokenAddress address of erc20 token to recover
    function recoverERC20(address tokenAddress) public onlyAdmin nonReentrant {
        if(tokenAddress == sellToken) revert CannotRecoverSellToken();
        if(buyTokenExchangeRates[tokenAddress] > 0) revert CannotRecoverBuyToken();

        uint256 tokenBalance = ERC20(tokenAddress).balanceOf(address(this));
        if(tokenBalance == 0) revert NoTokensToRecover();

        ERC20(tokenAddress).transfer(adminAddress, tokenBalance);
    }

    /// @notice prevents ETH being sent directly to this contract
    fallback() external {
        // ETH received with no msg.data
        revert FallbackNotPayable();
    }

    /// @notice prevents ETH being sent directly to this contract
    receive() external payable {
        // ETH received with msg.data that does not match any contract function
        revert ReceiveNotPayable();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}