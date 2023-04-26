// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ClonesWithImmutableArgs} from "clones/ClonesWithImmutableArgs.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {IBondBatchAuctionFactoryV1} from "./interfaces/IBondBatchAuctionFactoryV1.sol";
import {IGnosisEasyAuction} from "./interfaces/IGnosisEasyAuction.sol";
import {BondFixedExpiryTeller} from "./BondFixedExpiryTeller.sol";
import {BondBatchAuctionV1, IBondBatchAuctionV1} from "./BondBatchAuctionV1.sol";

/// @title Bond Batch Auction V1
/// @notice Bond Batch Auction V1 Contract (Gnosis EasyAuction Wrapper)
/// @dev The Bond Batch Auction V1 system is a clone-based, permissionless wrapper
///      around the Gnosis EasyAuction batch auction system. The purpose is to simplify
///      the creation and sale of Fixed Expiry ERC20 Bond Tokens via a batch auction mechanism.
///
///      The BondBatchAuctionFactoryV1 contract allows users to create a new BondBatchAuctionV1
///      clones which they can use to create their own batch auctions. The factory has view functions
///      which aggregate the batch auctions created by the deployed clones.
/// @author Oighty
contract BondBatchAuctionFactoryV1 is IBondBatchAuctionFactoryV1 {
    using ClonesWithImmutableArgs for address;

    /* ========== ERRORS ========== */
    error BatchAuctionFactory_InvalidParams();
    error BatchAuctionFactory_OnlyClone();

    /* ========== EVENTS ========== */
    event BatchAuctionCloneDeployed(BondBatchAuctionV1 clone, address owner, address creator);
    event BatchAuctionCreated(uint256 auctionId, BondBatchAuctionV1 clone);

    /* ========== STATE VARIABLES ========== */

    // Dependencies
    IGnosisEasyAuction public immutable gnosisAuction;
    BondFixedExpiryTeller public immutable teller;

    // Batch Auction Clones
    BondBatchAuctionV1 public implementation;
    mapping(BondBatchAuctionV1 => address) public cloneOwners;

    // Batch Auctions
    uint256[] public auctions;
    mapping(uint256 => BondBatchAuctionV1) public auctionsToClones;
    mapping(ERC20 => uint256[]) public auctionsForQuote;

    /* ========== CONSTRUCTOR ========== */

    constructor(IGnosisEasyAuction gnosisAuction_, BondFixedExpiryTeller teller_) {
        gnosisAuction = gnosisAuction_;
        teller = teller_;
        implementation = new BondBatchAuctionV1();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyClone() {
        if (cloneOwners[BondBatchAuctionV1(msg.sender)] == address(0))
            revert BatchAuctionFactory_OnlyClone();
        _;
    }

    /* ========== CLONE DEPLOYMENT ========== */

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function deployClone(address owner_) external override returns (BondBatchAuctionV1) {
        // Check that owner is not the zero address
        if (owner_ == address(0)) revert BatchAuctionFactory_InvalidParams();

        // Create clone
        bytes memory data = abi.encodePacked(gnosisAuction, teller, this, owner_);
        BondBatchAuctionV1 clone = BondBatchAuctionV1(address(implementation).clone(data));

        // Store clone owner
        cloneOwners[clone] = owner_;

        // Emit event
        emit BatchAuctionCloneDeployed(clone, owner_, msg.sender);

        // Return clone
        return clone;
    }

    /* ========== AUCTION REGISTRATION ========== */

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function registerAuction(uint256 auctionId_, ERC20 quoteToken_) external onlyClone {
        // Check that auction ID is not already registered
        if (address(auctionsToClones[auctionId_]) != address(0))
            revert BatchAuctionFactory_InvalidParams();

        // Store auction ID and clone mapping
        auctions.push(auctionId_);
        BondBatchAuctionV1 clone = BondBatchAuctionV1(msg.sender);
        auctionsToClones[auctionId_] = clone;
        auctionsForQuote[quoteToken_].push(auctionId_);

        // Emit event
        emit BatchAuctionCreated(auctionId_, clone);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function numAuctions() external view override returns (uint256) {
        return auctions.length;
    }

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function numAuctionsFor(ERC20 quoteToken_) external view override returns (uint256) {
        return auctionsForQuote[quoteToken_].length;
    }

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function auctionData(uint256 auctionId_)
        external
        view
        override
        returns (IBondBatchAuctionV1.AuctionData memory)
    {
        return auctionsToClones[auctionId_].auctionData(auctionId_);
    }

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function isLive(uint256 auctionId_) public view override returns (bool) {
        return auctionsToClones[auctionId_].isLive(auctionId_);
    }

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function liveAuctions(uint256 startIndex_, uint256 endIndex_)
        external
        view
        override
        returns (uint256[] memory)
    {
        // Get length of auction array and ensure endIndex is not greater than the length
        if (auctions.length < endIndex_) revert BatchAuctionFactory_InvalidParams();

        // Iterate through auctions and determine number of live auctions
        uint256 len;
        for (uint256 i = startIndex_; i < endIndex_; ++i) {
            if (isLive(auctions[i])) {
                ++len;
            }
        }

        // Initialize a dynamic array in memory with the correct length
        uint256[] memory live = new uint256[](len);
        uint256 index;
        for (uint256 j = startIndex_; j < endIndex_; ++j) {
            uint256 id = auctions[j];
            if (isLive(id)) {
                live[index] = id;
                ++index;
            }
        }

        // Return array of live auction IDs
        return live;
    }

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function liveAuctionsBy(
        address owner_,
        uint256 startIndex_,
        uint256 endIndex_
    ) external view override returns (uint256[] memory) {
        // Get length of auction array and ensure endIndex is not greater than the length
        if (auctions.length < endIndex_) revert BatchAuctionFactory_InvalidParams();

        // Iterate through auctions and determine number of live auctions for owner
        uint256 len;
        for (uint256 i = startIndex_; i < endIndex_; ++i) {
            uint256 id = auctions[i];
            if (isLive(id) && auctionsToClones[id].owner() == owner_) {
                ++len;
            }
        }

        // Initialize a dynamic array in memory with the correct length
        uint256[] memory live = new uint256[](len);
        uint256 index;
        for (uint256 j = startIndex_; j < endIndex_; ++j) {
            uint256 id = auctions[j];
            if (isLive(id) && auctionsToClones[id].owner() == owner_) {
                live[index] = id;
                ++index;
            }
        }

        // Return array of live auction IDs for owner
        return live;
    }

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function auctionsBy(
        address owner_,
        uint256 startIndex_,
        uint256 endIndex_
    ) external view override returns (uint256[] memory) {
        // Get length of auction array and ensure endIndex is not greater than the length
        if (auctions.length < endIndex_) revert BatchAuctionFactory_InvalidParams();

        // Iterate through auctions and determine number of auctions for owner
        uint256 len;
        for (uint256 i = startIndex_; i < endIndex_; ++i) {
            if (auctionsToClones[auctions[i]].owner() == owner_) {
                ++len;
            }
        }

        // Initialize a dynamic array in memory with the correct length
        uint256[] memory owned = new uint256[](len);
        uint256 index;
        for (uint256 j = startIndex_; j < endIndex_; ++j) {
            uint256 id = auctions[j];
            if (auctionsToClones[id].owner() == owner_) {
                owned[index] = id;
                ++index;
            }
        }

        // Return array of auction IDs for owner
        return owned;
    }

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function liveAuctionsFor(
        ERC20 quoteToken_,
        uint256 startIndex_,
        uint256 endIndex_
    ) external view override returns (uint256[] memory) {
        uint256[] memory qtAuctions = auctionsForQuote[quoteToken_];

        // Get length of auction array and ensure endIndex is not greater than the length
        if (qtAuctions.length < endIndex_) revert BatchAuctionFactory_InvalidParams();

        // Iterate through auctions and determine number of live auctions for quote token
        uint256 len;
        for (uint256 i = startIndex_; i < endIndex_; ++i) {
            uint256 id = qtAuctions[i];
            if (isLive(id)) {
                ++len;
            }
        }

        // Initialize a dynamic array in memory with the correct length
        uint256[] memory live = new uint256[](len);
        uint256 index;
        for (uint256 j = startIndex_; j < endIndex_; ++j) {
            uint256 id = qtAuctions[j];
            if (isLive(id)) {
                live[index] = id;
                ++index;
            }
        }

        // Return array of live auction IDs for quote token
        return live;
    }

    /// @inheritdoc IBondBatchAuctionFactoryV1
    function auctionsFor(
        ERC20 quoteToken_,
        uint256 startIndex_,
        uint256 endIndex_
    ) external view override returns (uint256[] memory) {
        // Get length of auction array and ensure endIndex is not greater than the length
        if (auctionsForQuote[quoteToken_].length < endIndex_)
            revert BatchAuctionFactory_InvalidParams();

        // Use index range to determine length of return array and initialize array in memory
        uint256 len = endIndex_ - startIndex_;
        uint256[] memory qtAuctions = new uint256[](len);

        // Iterate through the
        uint256 index;
        for (uint256 i = startIndex_; i < endIndex_; ++i) {
            qtAuctions[index] = auctionsForQuote[quoteToken_][i];
            ++index;
        }

        // Return array of auction IDs for quote token within the index range
        return qtAuctions;
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x43 + extraLength;
            uint256 runSize = creationSize - 11;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (11 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 61 runtime  | PUSH2 runtime (r)     | r 0                     | –
                mstore(
                    ptr,
                    0x3d61000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x02), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0b
                // 80          | DUP1                  | r r 0                   | –
                // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
                // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
                // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
                // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
                // f3          | RETURN                | 0                       | [0-2d]: runtime code
                mstore(
                    add(ptr, 0x04),
                    0x80600b3d3981f300000000000000000000000000000000000000000000000000
                )

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME
                // -------------------------------------------------------------------------------------------------------------

                // 36          | CALLDATASIZE          | cds                     | –
                // 3d          | RETURNDATASIZE        | 0 cds                   | –
                // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
                // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
                // 61          | PUSH2 extra           | extra                   | [0, cds] = calldata
                mstore(
                    add(ptr, 0x0b),
                    0x363d3d3761000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x10), shl(240, extraLength))

                // 60 0x38     | PUSH1 0x38            | 0x38 extra              | [0, cds] = calldata // 0x38 (56) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x38 extra          | [0, cds] = calldata
                // 39          | CODECOPY              | _                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
                // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0         | [0, cds] = calldata
                mstore(
                    add(ptr, 0x12),
                    0x603836393d3d3d36610000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
                // f4          | DELEGATECALL          | success 0               | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
                // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
                // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
                // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
                // 90          | SWAP1                 | 0 success               | [0, rds] = return data
                // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
                // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
                // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
                // fd          | REVERT                | –                       | [0, rds] = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
                // f3          | RETURN                | –                       | [0, rds] = return data

                mstore(
                    add(ptr, 0x34),
                    0x5af43d82803e903d91603657fd5bf30000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x43;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {BondBatchAuctionV1, IBondBatchAuctionV1} from "src/BondBatchAuctionV1.sol";

interface IBondBatchAuctionFactoryV1 {
    /* ========== CLONE DEPLOYMENT ========== */

    /// @notice Deploys a new BondBatchAuctionV1 clone that can be used to create Batch Auctions to sell Fixed Expiry Bond Tokens.
    /// @param owner_ The owner of the BondBatchAuctionV1 clone. This is the only address that will be able to create auctions and claim proceeds.
    function deployClone(address owner_) external returns (BondBatchAuctionV1);

    /* ========== AUCTION REGISTRATION ========== */

    /// @notice Registers a new auction with the factory.
    /// @notice Access controlled - only callable by BondBatchAuctionV1 clones created by this contract.
    /// @param auctionId_ The auction ID of the auction to register.
    /// @param quoteToken_ The quote token (auction creator is acquiring) for the auction.
    function registerAuction(uint256 auctionId_, ERC20 quoteToken_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Returns the number of auctions created by clones of the factory.
    /// @dev This is useful for getting the length of auctions array for pagination with liveAuctions, auctionsBy, and liveAuctionsBy.
    function numAuctions() external view returns (uint256);

    /// @notice Returns the number of auctions created by clones of the factory for a given quote token.
    /// @dev This is useful for getting the length of auctions array for a quote tokens for pagination with auctionsFor and liveAuctionsFor.
    /// @param quoteToken_ The quote token to get the number of auctions for.
    function numAuctionsFor(ERC20 quoteToken_) external view returns (uint256);

    /// @notice Returns the stored auction data for a given auction ID.
    /// @param auctionId_ The auction ID to get the data for.
    /// @dev This data can also be retrieved from a specific clone. This functions routes a request for data to the correct clone.
    function auctionData(uint256 auctionId_)
        external
        view
        returns (IBondBatchAuctionV1.AuctionData memory);

    /// @notice Whether or not an auction is live.
    /// @param auctionId_ The auction ID to check status for.
    /// @dev This data can also be retrieved from a specific clone. This functions routes a request for data to the correct clone.
    function isLive(uint256 auctionId_) external view returns (bool);

    /// @notice Returns the auction IDs of all live auctions in the provided index range.
    /// @dev This function uses a start and end index to allow for pagination of the auctions array in order to iterate through an increasingly large array without hitting the gas limit.
    /// @param startIndex_ The start index of the auctions array to start iterating from (inclusive).
    /// @param endIndex_ The end index of the auctions array to stop iterating at (non-inclusive).
    /// @dev The indexes are over the array of all auctions, are 0-indexed, and the endIndex_ is non-inclusive, i.e. [startIndex, endIndex).
    function liveAuctions(uint256 startIndex_, uint256 endIndex_)
        external
        view
        returns (uint256[] memory);

    /// @notice Returns the auction IDs of all live auctions by the provided owner in the provided index range.
    /// @dev This function uses a start and end index to allow for pagination of the auctions array in order to iterate through an increasingly large array without hitting the gas limit.
    /// @param startIndex_ The start index of the auctions array to start iterating from (inclusive).
    /// @param endIndex_ The end index of the auctions array to stop iterating at (non-inclusive).
    /// @dev The indexes are over the array of all auctions, are 0-indexed, and the endIndex_ is non-inclusive, i.e. [startIndex, endIndex).
    function liveAuctionsBy(
        address owner_,
        uint256 startIndex_,
        uint256 endIndex_
    ) external view returns (uint256[] memory);

    /// @notice Returns the auction IDs of all auctions by the provided owner in the provided index range.
    /// @dev This function uses a start and end index to allow for pagination of the auctions array in order to iterate through an increasingly large array without hitting the gas limit.
    /// @param startIndex_ The start index of the auctions array to start iterating from (inclusive).
    /// @param endIndex_ The end index of the auctions array to stop iterating at (non-inclusive).
    /// @dev The indexes are over the array of all auctions, are 0-indexed, and the endIndex_ is non-inclusive, i.e. [startIndex, endIndex).
    function auctionsBy(
        address owner_,
        uint256 startIndex_,
        uint256 endIndex_
    ) external view returns (uint256[] memory);

    /// @notice Returns the auction IDs of all live auctions for the provided quote token in the provided index range.
    /// @dev This function uses a start and end index to allow for pagination of the quote token auctions array in order to iterate through an increasingly large array without hitting the gas limit.
    /// @param quoteToken_ The quote token (address) to get the live auctions for.
    /// @param startIndex_ The start index of the quote token auctions array to start iterating from (inclusive).
    /// @param endIndex_ The end index of the quote token auctions array to stop iterating at (non-inclusive).
    /// @dev The indexes are over the array of auctions for the specific quote token, are 0-indexed, and the endIndex_ is non-inclusive, i.e. [startIndex, endIndex).
    function liveAuctionsFor(
        ERC20 quoteToken_,
        uint256 startIndex_,
        uint256 endIndex_
    ) external view returns (uint256[] memory);

    /// @notice Returns the auction IDs of all auctions for the provided quote token in the provided index range.
    /// @dev This function uses a start and end index to allow for pagination of the quote token auctions array in order to iterate through an increasingly large array without hitting the gas limit.
    /// @param quoteToken_ The quote token (address) to get the live auctions for.
    /// @param startIndex_ The start index of the quote token auctions array to start iterating from (inclusive).
    /// @param endIndex_ The end index of the quote token auctions array to stop iterating at (non-inclusive).
    /// @dev The indexes are over the array of auctions for the specific quote token, are 0-indexed, and the endIndex_ is non-inclusive, i.e. [startIndex, endIndex).
    function auctionsFor(
        ERC20 quoteToken_,
        uint256 startIndex_,
        uint256 endIndex_
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IGnosisEasyAuction {
    /// @notice                         Initiates an auction through Gnosis Auctions
    /// @param tokenToSell              The token being sold
    /// @param biddingToken             The token used to bid on the sale token and set its price
    /// @param lastCancellation         The last timestamp a user can cancel their bid at
    /// @param auctionEnd               The timestamp the auction ends at
    /// @param auctionAmount            The number of sale tokens to sell
    /// @param minBuyAmount             The minimum number of bidding tokens to be bought for the auctionAmount (sets minimum price as minimumTotalProceeds/auctionAmount)
    /// @param minBuyAmountPerOrder     The minimum purchase size in bidding tokens for an order
    /// @param minFundingThreshold      The minimal funding thresholding for finalizing settlement. If not reached, bids will be returned
    /// @param isAtomicClosureAllowed   Can users call settleAuctionAtomically when end date has been reached
    /// @param accessManager            The contract to manage an allowlist
    /// @param accessManagerData        The data for managing an allowlist
    function initiateAuction(
        ERC20 tokenToSell,
        ERC20 biddingToken,
        uint256 lastCancellation,
        uint256 auctionEnd,
        uint96 auctionAmount,
        uint96 minBuyAmount,
        uint256 minBuyAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManager,
        bytes calldata accessManagerData
    ) external returns (uint256);

    /// @notice                         Settles the auction and determines the clearing orders
    /// @param auctionId                The auction to settle
    function settleAuction(uint256 auctionId) external returns (bytes32);

    function placeSellOrders(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData
    ) external returns (uint64 userId);

    function claimFromParticipantOrder(uint256 auctionId, bytes32[] memory orders)
        external
        returns (uint256 sumAuctioningTokenAmount, uint256 sumBiddingTokenAmount);

    function setFeeParameters(uint256 newFeeNumerator, address newfeeReceiverAddress) external;

    struct AuctionData {
        ERC20 auctioningToken;
        ERC20 biddingToken;
        uint256 orderCancellationEndDate;
        uint256 auctionEndDate;
        bytes32 initialAuctionOrder;
        uint256 minimumBiddingAmountPerOrder;
        uint256 interimSumBidAmount;
        bytes32 interimOrder;
        bytes32 clearingPriceOrder;
        uint96 volumeClearingPriceOrder;
        bool minFundingThresholdNotReached;
        bool isAtomicClosureAllowed;
        uint256 feeNumerator;
        uint256 minFundingThreshold;
    }

    function auctionData(uint256 auctionId) external view returns (AuctionData memory);

    function auctionAccessManager(uint256 auctionId) external view returns (address);

    function auctionAccessData(uint256 auctionId) external view returns (bytes memory);

    function auctionCounter() external view returns (uint256);

    function feeNumerator() external view returns (uint256);

    function FEE_DENOMINATOR() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ClonesWithImmutableArgs} from "clones/ClonesWithImmutableArgs.sol";

import {BondBaseTeller, IBondAggregator, Authority} from "./bases/BondBaseTeller.sol";
import {IBondFixedExpiryTeller} from "./interfaces/IBondFixedExpiryTeller.sol";
import {ERC20BondToken} from "./ERC20BondToken.sol";

import {TransferHelper} from "./lib/TransferHelper.sol";
import {FullMath} from "./lib/FullMath.sol";

/// @title Bond Fixed Expiry Teller
/// @notice Bond Fixed Expiry Teller Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
/// @dev The Bond Fixed Expiry Teller is an implementation of the
///      Bond Base Teller contract specific to handling user bond transactions
///      and tokenizing bond markets where all purchases vest at the same timestamp
///      as ERC20 tokens. Vesting timestamps are rounded to the nearest day to avoid
///      duplicate tokens with the same name/symbol.
///
/// @author Oighty, Zeus, Potted Meat, indigo
contract BondFixedExpiryTeller is BondBaseTeller, IBondFixedExpiryTeller {
    using TransferHelper for ERC20;
    using FullMath for uint256;
    using ClonesWithImmutableArgs for address;

    /* ========== EVENTS ========== */
    event ERC20BondTokenCreated(
        ERC20BondToken bondToken,
        ERC20 indexed underlying,
        uint48 indexed expiry
    );

    /* ========== STATE VARIABLES ========== */
    /// @notice ERC20 bond tokens (unique to a underlying and expiry)
    mapping(ERC20 => mapping(uint48 => ERC20BondToken)) public bondTokens;

    /// @notice ERC20BondToken reference implementation (deployed on creation to clone from)
    ERC20BondToken public immutable bondTokenImplementation;

    /* ========== CONSTRUCTOR ========== */
    constructor(
        address protocol_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) BondBaseTeller(protocol_, aggregator_, guardian_, authority_) {
        bondTokenImplementation = new ERC20BondToken();
    }

    /* ========== PURCHASE ========== */

    /// @notice             Handle payout to recipient
    /// @param recipient_   Address to receive payout
    /// @param payout_      Amount of payoutToken to be paid
    /// @param underlying_   Token to be paid out
    /// @param vesting_     Timestamp when the payout will vest
    /// @return expiry      Timestamp when the payout will vest
    function _handlePayout(
        address recipient_,
        uint256 payout_,
        ERC20 underlying_,
        uint48 vesting_
    ) internal override returns (uint48 expiry) {
        // If there is no vesting time, the deposit is treated as an instant swap.
        // otherwise, deposit info is stored and payout is available at a future timestamp.
        // instant swap is denoted by expiry == 0.
        //
        // bonds mature with a cliff at a set timestamp
        // prior to the expiry timestamp, no payout tokens are accessible to the user
        // after the expiry timestamp, the entire payout can be redeemed
        //
        // fixed-expiry bonds mature at a set timestamp
        // i.e. expiry = day 10. when alice deposits on day 1, her term
        // is 9 days. when bob deposits on day 2, his term is 8 days.
        if (vesting_ > uint48(block.timestamp)) {
            expiry = vesting_;
            // Fixed-expiry bonds mint ERC-20 tokens
            bondTokens[underlying_][expiry].mint(recipient_, payout_);
        } else {
            // If no expiry, then transfer payout directly to user
            underlying_.safeTransfer(recipient_, payout_);
        }
    }

    /* ========== DEPOSIT/MINT ========== */

    /// @inheritdoc IBondFixedExpiryTeller
    function create(
        ERC20 underlying_,
        uint48 expiry_,
        uint256 amount_
    ) external override nonReentrant returns (ERC20BondToken, uint256) {
        // Expiry is rounded to the nearest day at 0000 UTC (in seconds) since bond tokens
        // are only unique to a day, not a specific timestamp.
        uint48 expiry = uint48(expiry_ / 1 days) * 1 days;

        // Revert if expiry is in the past
        if (uint256(expiry) < block.timestamp) revert Teller_InvalidParams();

        ERC20BondToken bondToken = bondTokens[underlying_][expiry];

        // Revert if no token exists, must call deploy first
        if (bondToken == ERC20BondToken(address(0x00)))
            revert Teller_TokenDoesNotExist(underlying_, expiry);

        // Transfer in underlying
        // Check that amount received is not less than amount expected
        // Handles edge cases like fee-on-transfer tokens (which are not supported)
        uint256 oldBalance = underlying_.balanceOf(address(this));
        underlying_.safeTransferFrom(msg.sender, address(this), amount_);
        if (underlying_.balanceOf(address(this)) < oldBalance + amount_)
            revert Teller_UnsupportedToken();

        // If fee is greater than the create discount, then calculate the fee and store it
        // Otherwise, fee is zero.
        if (protocolFee > createFeeDiscount) {
            // Calculate fee amount
            uint256 feeAmount = amount_.mulDiv(protocolFee - createFeeDiscount, FEE_DECIMALS);
            rewards[_protocol][underlying_] += feeAmount;

            // Mint new bond tokens
            bondToken.mint(msg.sender, amount_ - feeAmount);

            return (bondToken, amount_ - feeAmount);
        } else {
            // Mint new bond tokens
            bondToken.mint(msg.sender, amount_);

            return (bondToken, amount_);
        }
    }

    /* ========== REDEEM ========== */

    /// @inheritdoc IBondFixedExpiryTeller
    function redeem(ERC20BondToken token_, uint256 amount_) external override nonReentrant {
        // Validate token is issued by this teller
        ERC20 underlying = token_.underlying();
        uint48 expiry = token_.expiry();

        if (token_ != bondTokens[underlying][expiry]) revert Teller_UnsupportedToken();

        // Validate token expiry has passed
        if (uint48(block.timestamp) < expiry) revert Teller_TokenNotMatured(expiry);

        // Burn bond token and transfer underlying
        token_.burn(msg.sender, amount_);
        underlying.safeTransfer(msg.sender, amount_);
    }

    /* ========== TOKENIZATION ========== */

    /// @inheritdoc IBondFixedExpiryTeller
    function deploy(ERC20 underlying_, uint48 expiry_)
        external
        override
        nonReentrant
        returns (ERC20BondToken)
    {
        // Expiry is rounded to the nearest day at 0000 UTC (in seconds) since bond tokens
        // are only unique to a day, not a specific timestamp.
        uint48 expiry = uint48(expiry_ / 1 days) * 1 days;

        // Revert if expiry is in the past
        if (uint256(expiry) < block.timestamp) revert Teller_InvalidParams();

        // Create bond token if one doesn't already exist
        ERC20BondToken bondToken = bondTokens[underlying_][expiry];
        if (bondToken == ERC20BondToken(address(0))) {
            (string memory name, string memory symbol) = _getNameAndSymbol(underlying_, expiry);
            bytes memory tokenData = abi.encodePacked(
                bytes32(bytes(name)),
                bytes32(bytes(symbol)),
                uint8(underlying_.decimals()),
                underlying_,
                uint256(expiry),
                address(this)
            );
            bondToken = ERC20BondToken(address(bondTokenImplementation).clone(tokenData));
            bondTokens[underlying_][expiry] = bondToken;
            emit ERC20BondTokenCreated(bondToken, underlying_, expiry);
        }
        return bondToken;
    }

    /// @inheritdoc IBondFixedExpiryTeller
    function getBondTokenForMarket(uint256 id_) external view override returns (ERC20BondToken) {
        // Check that the id is for a market served by this teller
        if (address(_aggregator.getTeller(id_)) != address(this)) revert Teller_InvalidParams();

        // Get the underlying and expiry for the market
        (, , ERC20 underlying, , uint48 expiry, ) = _aggregator
            .getAuctioneer(id_)
            .getMarketInfoForPurchase(id_);

        return bondTokens[underlying][expiry];
    }

    /// @inheritdoc IBondFixedExpiryTeller
    function getBondToken(ERC20 underlying_, uint48 expiry_)
        external
        view
        override
        returns (ERC20BondToken)
    {
        // Expiry is rounded to the nearest day at 0000 UTC (in seconds) since bond tokens
        // are only unique to a day, not a specific timestamp.
        uint48 expiry = uint48(expiry_ / 1 days) * 1 days;

        ERC20BondToken bondToken = bondTokens[underlying_][expiry];

        // Revert if token does not exist
        if (address(bondToken) == address(0)) revert Teller_TokenDoesNotExist(underlying_, expiry);

        return bondToken;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Clone} from "clones/Clone.sol";

import {IBondBatchAuctionV1} from "./interfaces/IBondBatchAuctionV1.sol";
import {IGnosisEasyAuction} from "./interfaces/IGnosisEasyAuction.sol";
import {BondFixedExpiryTeller} from "./BondFixedExpiryTeller.sol";
import {IBondBatchAuctionFactoryV1} from "./interfaces/IBondBatchAuctionFactoryV1.sol";

import {TransferHelper} from "./lib/TransferHelper.sol";
import {FullMath} from "./lib/FullMath.sol";

/// @title Bond Batch Auction V1
/// @notice Bond Batch Auction V1 Contract (Gnosis EasyAuction Wrapper)
/// @dev The Bond Batch Auction V1 system is a clone-based, permissionless wrapper
///      around the Gnosis EasyAuction batch auction system. The purpose is to simplify
///      the creation and sale of Fixed Expiry ERC20 Bond Tokens via a batch auction mechanism.
///
///      The BondBatchAuctionV1 contract is a single-user contract that is deployed as a clone
///      from the factory to keep each user's auctions and token balances separate.
/// @author Oighty
contract BondBatchAuctionV1 is IBondBatchAuctionV1, ReentrancyGuard, Clone {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== ERRORS ========== */
    error BatchAuction_InvalidParams();
    error BatchAuction_OnlyOwner();
    error BatchAuction_AlreadySettled();
    error BatchAuction_TokenNotSupported();
    error BatchAuction_AuctionHasNotEnded();
    error BatchAuction_AlreadySettledExternally();
    error BatchAuction_NotSettledExternally();

    /* ========== EVENTS ========== */
    event BatchAuctionCreated(
        uint256 indexed auctionId_,
        address indexed owner_,
        ERC20 quoteToken_,
        ERC20 payoutToken_,
        uint256 auctionEnd
    );
    event BatchAuctionSettled(
        uint256 indexed auctionId_,
        bytes32 clearingOrder,
        uint256 quoteTokenProceeds,
        uint256 payoutTokensSold
    );

    /* ========== STATE VARIABLES ========== */

    uint256[] public auctions;
    mapping(uint256 => AuctionData) internal _auctionData;

    /* ========== CONSTRUCTOR ========== */

    constructor() {}

    /* ========== IMMUTABLE CLONE ARGS ========== */

    /// @inheritdoc IBondBatchAuctionV1
    function gnosisAuction() public pure override returns (IGnosisEasyAuction) {
        return IGnosisEasyAuction(_getArgAddress(0));
    }

    /// @inheritdoc IBondBatchAuctionV1
    function teller() public pure override returns (BondFixedExpiryTeller) {
        return BondFixedExpiryTeller(_getArgAddress(20));
    }

    /// @inheritdoc IBondBatchAuctionV1
    function factory() public pure override returns (IBondBatchAuctionFactoryV1) {
        return IBondBatchAuctionFactoryV1(_getArgAddress(40));
    }

    /// @inheritdoc IBondBatchAuctionV1
    function owner() public pure override returns (address) {
        return _getArgAddress(60);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        if (msg.sender != owner()) revert BatchAuction_OnlyOwner();
        _;
    }

    /* ========== AUCTION MANAGEMENT ========== */

    /// @inheritdoc IBondBatchAuctionV1
    function initiateBatchAuction(BatchAuctionParams memory batchAuctionParams_)
        external
        onlyOwner
        returns (uint256)
    {
        // Validate bond token params

        // Validate underlying token address is a contract
        // Not sufficient to ensure it's a token
        if (address(batchAuctionParams_.payoutTokenParams.underlying).code.length == 0)
            revert BatchAuction_InvalidParams();

        // Normalize bond token expiry by rounding down to the nearest day.
        // The Bond Teller does this anyways so better to validate with the rounded value.
        // Check that Bond Token Expiry >= Auction End
        if (
            (uint256(batchAuctionParams_.payoutTokenParams.expiry) / 1 days) * 1 days <
            batchAuctionParams_.auctionEnd
        ) revert BatchAuction_InvalidParams();

        // Batch auction params are validated by the EasyAuction contract
        // https://github.com/gnosis/ido-contracts/blob/bc0a4eff40b065e46cc3f21615416528efe6e8e7/contracts/EasyAuction.sol#L173

        // Deploy Bond Token (checks exist on the teller to see if it already exists)
        ERC20 payoutToken = ERC20(
            address(
                teller().deploy(
                    batchAuctionParams_.payoutTokenParams.underlying,
                    batchAuctionParams_.payoutTokenParams.expiry
                )
            )
        );

        {
            // Calculate fee for minting bond tokens
            uint256 amount = amountWithFee(uint256(batchAuctionParams_.auctionAmount)) +
                amountWithTellerFee(uint256(batchAuctionParams_.liquidityAmount));

            // Transfer tokens in from sender
            /// @dev sender needs to have approved this contract to manage the underlying token to create bond tokens with
            /// @dev this amount can be determined before calling by using the `amountWithFee` function using the auctionAmount and `amountWithTellerFee` using the liquidityAmount
            // The contract does not support underlying tokens that are fee-on-transfer tokens
            // Check balance before and after to ensure the correct amount was transferred
            uint256 balanceBefore = batchAuctionParams_.payoutTokenParams.underlying.balanceOf(
                address(this)
            );
            batchAuctionParams_.payoutTokenParams.underlying.safeTransferFrom(
                owner(),
                address(this),
                amount
            );
            if (
                batchAuctionParams_.payoutTokenParams.underlying.balanceOf(address(this)) <
                balanceBefore + amount
            ) revert BatchAuction_TokenNotSupported();

            // Approve the teller for the amount with fee and create Bond Tokens
            batchAuctionParams_.payoutTokenParams.underlying.approve(address(teller()), amount);
            teller().create(
                batchAuctionParams_.payoutTokenParams.underlying,
                batchAuctionParams_.payoutTokenParams.expiry,
                amount
            );

            // Send the bond tokens reserved to provide liquidity to the sender (if there are any)
            if (batchAuctionParams_.liquidityAmount > 0)
                payoutToken.safeTransfer(owner(), uint256(batchAuctionParams_.liquidityAmount));
        }

        {
            // Approve auction contract for bond tokens (transferred immediately after so no approval override issues)
            // We include the gnosis fee amount in the approval since initiateAuction will transfer this amount
            uint256 feeDecimals = gnosisAuction().FEE_DENOMINATOR();
            payoutToken.approve(
                address(gnosisAuction()),
                (uint256(batchAuctionParams_.auctionAmount) *
                    (gnosisAuction().feeNumerator() + feeDecimals)) / feeDecimals
            );
        }

        // Initiate Batch Auction
        uint256 auctionId = gnosisAuction().initiateAuction(
            payoutToken,
            batchAuctionParams_.quoteToken,
            batchAuctionParams_.cancelUntil,
            batchAuctionParams_.auctionEnd,
            batchAuctionParams_.auctionAmount,
            batchAuctionParams_.minBuyAmount,
            batchAuctionParams_.minBuyAmountPerOrder,
            batchAuctionParams_.minFundingThreshold,
            false, // no atomic closures
            batchAuctionParams_.accessManager,
            batchAuctionParams_.accessManagerData
        );

        // Store auction information
        auctions.push(auctionId);
        _auctionData[auctionId] = AuctionData({
            quoteToken: batchAuctionParams_.quoteToken,
            payoutToken: payoutToken,
            created: true,
            settled: false,
            auctionEnd: uint48(batchAuctionParams_.auctionEnd),
            payoutAmount: batchAuctionParams_.auctionAmount
        });

        // Register auction with factory
        factory().registerAuction(auctionId, batchAuctionParams_.quoteToken);

        // Return auction ID
        return auctionId;
    }

    /// @inheritdoc IBondBatchAuctionV1
    function settleBatchAuction(uint256 auctionId_) external onlyOwner returns (bytes32) {
        // Validate auction was created with this contract and hasn't been settled on this contract yet
        if (!_auctionData[auctionId_].created) revert BatchAuction_InvalidParams();
        if (_auctionData[auctionId_].settled) revert BatchAuction_AlreadySettled();

        // Validate timestamp is past auction end
        if (block.timestamp < _auctionData[auctionId_].auctionEnd)
            revert BatchAuction_AuctionHasNotEnded();

        // Validate that the auction hasn't been settled on the auction contract
        bytes32 clearingOrder = gnosisAuction().auctionData(auctionId_).clearingPriceOrder;
        if (clearingOrder != bytes32(0)) revert BatchAuction_AlreadySettledExternally();

        // Get tokens and starting balances
        AuctionData memory auction = _auctionData[auctionId_];
        uint256 qtStartBal = auction.quoteToken.balanceOf(address(this));
        uint256 ptStartBal = auction.payoutToken.balanceOf(address(this));

        // Settle auction
        clearingOrder = gnosisAuction().settleAuction(auctionId_);
        _auctionData[auctionId_].settled = true;

        // Get ending balances
        uint256 qtEndBal = auction.quoteToken.balanceOf(address(this));
        uint256 ptEndBal = auction.payoutToken.balanceOf(address(this));

        // Transfer any auction proceeds to owner
        // If the auction did not sell the minimum amount, then it will have returned the payout tokens instead and the balance change will be 0
        if (qtEndBal > qtStartBal) auction.quoteToken.safeTransfer(owner(), qtEndBal - qtStartBal);

        // Check if any payout tokens were returned, if so, transfer them to the owner
        // Owners will need to redeem these for the underlying on the fixed expiry teller.
        // We could check for this here, but it's unlikely that many vested tokens
        // will want to be redeem immediately after an auction ends.
        if (ptEndBal > ptStartBal) auction.payoutToken.safeTransfer(owner(), ptEndBal - ptStartBal);

        // Return clearing order bytes32 from EasyAuction
        return clearingOrder;
    }

    /// @inheritdoc IBondBatchAuctionV1
    function withdrawExternallySettledFunds(uint256 auctionId_) external override onlyOwner {
        AuctionData storage auction = _auctionData[auctionId_];

        // Validate auction was created with this contract and hasn't been settled yet on this contract
        if (!auction.created) revert BatchAuction_InvalidParams();
        if (auction.settled) revert BatchAuction_AlreadySettled();

        // Validate timestamp is past auction end
        if (block.timestamp < _auctionData[auctionId_].auctionEnd)
            revert BatchAuction_AuctionHasNotEnded();

        // Validate that the auction has been settled on the auction contract
        bytes32 clearingOrder = gnosisAuction().auctionData(auctionId_).clearingPriceOrder;
        if (clearingOrder == bytes32(0)) revert BatchAuction_NotSettledExternally();

        // Assume auction has already been settled externally via the public EasyAuction function
        auction.settled = true;

        // Therefore, we can just transfer the funds to the owner
        /// @dev since we don't know how many tokens were received from the auction,
        /// we just transfer all of the quote token and payout token balances.
        /// This could inadvertently transfer tokens that were sent to the contract
        /// by another auction as well, but they are all owned by the owner
        // so it doesn't matter if they are co-mingled.
        uint256 qtBal = auction.quoteToken.balanceOf(address(this));
        if (qtBal > 0) auction.quoteToken.safeTransfer(owner(), qtBal);
        uint256 ptBal = auction.payoutToken.balanceOf(address(this));
        if (ptBal > 0) auction.payoutToken.safeTransfer(owner(), ptBal);
    }

    /// @inheritdoc IBondBatchAuctionV1
    function emergencyWithdraw(ERC20 token_) external override onlyOwner {
        // Confirm that the token is a contract
        if (address(token_).code.length == 0 && address(token_) != address(0))
            revert BatchAuction_InvalidParams();

        // If token address is zero, withdraw ETH
        if (address(token_) == address(0)) {
            payable(owner()).call{value: address(this).balance}("");
        } else {
            token_.safeTransfer(owner(), token_.balanceOf(address(this)));
        }
    }

    /* ========== VIEW FUNCTIONS ==========*/

    /// @inheritdoc IBondBatchAuctionV1
    function numAuctions() external view override returns (uint256) {
        return auctions.length;
    }

    /// @inheritdoc IBondBatchAuctionV1
    function auctionData(uint256 auctionId_) external view override returns (AuctionData memory) {
        return _auctionData[auctionId_];
    }

    /// @inheritdoc IBondBatchAuctionV1
    function amountWithFee(uint256 auctionAmount_) public view override returns (uint256) {
        BondFixedExpiryTeller _teller = teller();
        IGnosisEasyAuction _gnosisAuction = gnosisAuction();
        uint256 tellerFeeDecimals = _teller.FEE_DECIMALS();
        uint256 easyAuctionFeeDecimals = _gnosisAuction.FEE_DENOMINATOR();
        uint256 tellerFee = _teller.protocolFee();
        uint256 tellerCreateFeeDiscount = _teller.createFeeDiscount();

        uint256 amount = auctionAmount_.mulDiv(
            easyAuctionFeeDecimals + _gnosisAuction.feeNumerator(),
            easyAuctionFeeDecimals
        );

        if (tellerFee > tellerCreateFeeDiscount) {
            amount = amount.mulDivUp(
                tellerFeeDecimals,
                tellerFeeDecimals - (tellerFee - tellerCreateFeeDiscount)
            );
        }

        return amount;
    }

    /// @inheritdoc IBondBatchAuctionV1
    function amountWithTellerFee(uint256 liquidityAmount_) public view override returns (uint256) {
        BondFixedExpiryTeller _teller = teller();
        uint256 tellerFeeDecimals = _teller.FEE_DECIMALS();
        uint256 tellerFee = _teller.protocolFee();
        uint256 tellerCreateFeeDiscount = _teller.createFeeDiscount();

        if (tellerFee > tellerCreateFeeDiscount) {
            return
                liquidityAmount_.mulDivUp(
                    tellerFeeDecimals,
                    tellerFeeDecimals - (tellerFee - tellerCreateFeeDiscount)
                );
        } else {
            return liquidityAmount_;
        }
    }

    /// @inheritdoc IBondBatchAuctionV1
    function isLive(uint256 auctionId_) public view override returns (bool) {
        return _auctionData[auctionId_].auctionEnd > uint48(block.timestamp);
    }

    /// @inheritdoc IBondBatchAuctionV1
    function liveAuctions(uint256 startIndex_, uint256 endIndex_)
        external
        view
        override
        returns (uint256[] memory)
    {
        // Get length of auction array and ensure endIndex is not greater than the length
        if (auctions.length < endIndex_) revert BatchAuction_InvalidParams();

        // Iterate through auctions and determine number of live auctions
        uint256 len;
        for (uint256 i = startIndex_; i < endIndex_; ++i) {
            if (isLive(auctions[i])) {
                ++len;
            }
        }

        // Initialize a dynamic array in memory with the correct length
        uint256[] memory live = new uint256[](len);
        uint256 index;
        for (uint256 j = startIndex_; j < endIndex_; ++j) {
            uint256 id = auctions[j];
            if (isLive(id)) {
                live[index] = id;
                ++index;
            }
        }

        // Return array of live auction IDs
        return live;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondCallback} from "../interfaces/IBondCallback.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";
import {IBondAuctioneer} from "../interfaces/IBondAuctioneer.sol";

import {TransferHelper} from "../lib/TransferHelper.sol";
import {FullMath} from "../lib/FullMath.sol";

/// @title Bond Teller
/// @notice Bond Teller Base Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The Teller contract handles all interactions with end users and manages tokens
///      issued to represent bond positions. Users purchase bonds by depositing Quote Tokens
///      and receive a Bond Token (token type is implementation-specific) that represents
///      their payout and the designated expiry. Once a bond vests, Investors can redeem their
///      Bond Tokens for the underlying Payout Token. A Teller requires one or more Auctioneer
///      contracts to be deployed to provide markets for users to purchase bonds from.
///
/// @author Oighty, Zeus, Potted Meat, indigo
abstract contract BondBaseTeller is IBondTeller, Auth, ReentrancyGuard {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== ERRORS ========== */

    error Teller_InvalidCallback();
    error Teller_TokenNotMatured(uint48 maturesOn);
    error Teller_NotAuthorized();
    error Teller_TokenDoesNotExist(ERC20 underlying, uint48 expiry);
    error Teller_UnsupportedToken();
    error Teller_InvalidParams();

    /* ========== EVENTS ========== */
    event Bonded(uint256 indexed id, address indexed referrer, uint256 amount, uint256 payout);

    /* ========== STATE VARIABLES ========== */

    /// @notice Fee paid to a front end operator in basis points (3 decimals). Set by the referrer, must be less than or equal to 5% (5e3).
    /// @dev There are some situations where the fees may round down to zero if quantity of baseToken
    ///      is < 1e5 wei (can happen with big price differences on small decimal tokens). This is purely
    ///      a theoretical edge case, as the bond amount would not be practical.
    mapping(address => uint48) public referrerFees;

    /// @notice Fee paid to protocol in basis points (3 decimal places).
    uint48 public protocolFee;

    /// @notice 'Create' function fee discount in basis points (3 decimal places). Amount standard fee is reduced by for partners who just want to use the 'create' function to issue bond tokens.
    uint48 public createFeeDiscount;

    uint48 public constant FEE_DECIMALS = 1e5; // one percent equals 1000.

    /// @notice Fees earned by an address, by token
    mapping(address => mapping(ERC20 => uint256)) public rewards;

    // Address the protocol receives fees at
    address internal immutable _protocol;

    // BondAggregator contract with utility functions
    IBondAggregator internal immutable _aggregator;

    constructor(
        address protocol_,
        IBondAggregator aggregator_,
        address guardian_,
        Authority authority_
    ) Auth(guardian_, authority_) {
        _protocol = protocol_;
        _aggregator = aggregator_;

        // Explicitly setting these values to zero to document
        protocolFee = 0;
        createFeeDiscount = 0;
    }

    /// @inheritdoc IBondTeller
    function setReferrerFee(uint48 fee_) external override nonReentrant {
        if (fee_ > 5e3) revert Teller_InvalidParams();
        referrerFees[msg.sender] = fee_;
    }

    /// @inheritdoc IBondTeller
    function setProtocolFee(uint48 fee_) external override requiresAuth {
        if (fee_ > 5e3) revert Teller_InvalidParams();
        protocolFee = fee_;
    }

    /// @inheritdoc IBondTeller
    function setCreateFeeDiscount(uint48 discount_) external override requiresAuth {
        if (discount_ > protocolFee) revert Teller_InvalidParams();
        createFeeDiscount = discount_;
    }

    /// @inheritdoc IBondTeller
    function claimFees(ERC20[] memory tokens_, address to_) external override nonReentrant {
        uint256 len = tokens_.length;
        for (uint256 i; i < len; ++i) {
            ERC20 token = tokens_[i];
            uint256 send = rewards[msg.sender][token];

            if (send != 0) {
                rewards[msg.sender][token] = 0;
                token.safeTransfer(to_, send);
            }
        }
    }

    /// @inheritdoc IBondTeller
    function getFee(address referrer_) external view returns (uint48) {
        return protocolFee + referrerFees[referrer_];
    }

    /* ========== USER FUNCTIONS ========== */

    /// @inheritdoc IBondTeller
    function purchase(
        address recipient_,
        address referrer_,
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external virtual nonReentrant returns (uint256, uint48) {
        ERC20 payoutToken;
        ERC20 quoteToken;
        uint48 vesting;
        uint256 payout;

        // Calculate fees for purchase
        // 1. Calculate referrer fee
        // 2. Calculate protocol fee as the total expected fee amount minus the referrer fee
        //    to avoid issues with rounding from separate fee calculations
        uint256 toReferrer = amount_.mulDiv(referrerFees[referrer_], FEE_DECIMALS);
        uint256 toProtocol = amount_.mulDiv(protocolFee + referrerFees[referrer_], FEE_DECIMALS) -
            toReferrer;

        {
            IBondAuctioneer auctioneer = _aggregator.getAuctioneer(id_);
            address owner;
            (owner, , payoutToken, quoteToken, vesting, ) = auctioneer.getMarketInfoForPurchase(
                id_
            );

            // Auctioneer handles bond pricing, capacity, and duration
            uint256 amountLessFee = amount_ - toReferrer - toProtocol;
            payout = auctioneer.purchaseBond(id_, amountLessFee, minAmountOut_);
        }

        // Allocate fees to protocol and referrer
        rewards[referrer_][quoteToken] += toReferrer;
        rewards[_protocol][quoteToken] += toProtocol;

        // Transfer quote tokens from sender and ensure enough payout tokens are available
        _handleTransfers(id_, amount_, payout, toReferrer + toProtocol);

        // Handle payout to user (either transfer tokens if instant swap or issue bond token)
        uint48 expiry = _handlePayout(recipient_, payout, payoutToken, vesting);

        emit Bonded(id_, referrer_, amount_, payout);

        return (payout, expiry);
    }

    /// @notice     Handles transfer of funds from user and market owner/callback
    function _handleTransfers(
        uint256 id_,
        uint256 amount_,
        uint256 payout_,
        uint256 feePaid_
    ) internal {
        // Get info from auctioneer
        (address owner, address callbackAddr, ERC20 payoutToken, ERC20 quoteToken, , ) = _aggregator
            .getAuctioneer(id_)
            .getMarketInfoForPurchase(id_);

        // Calculate amount net of fees
        uint256 amountLessFee = amount_ - feePaid_;

        // Have to transfer to teller first since fee is in quote token
        // Check balance before and after to ensure full amount received, revert if not
        // Handles edge cases like fee-on-transfer tokens (which are not supported)
        uint256 quoteBalance = quoteToken.balanceOf(address(this));
        quoteToken.safeTransferFrom(msg.sender, address(this), amount_);
        if (quoteToken.balanceOf(address(this)) < quoteBalance + amount_)
            revert Teller_UnsupportedToken();

        // If callback address supplied, transfer tokens from teller to callback, then execute callback function,
        // and ensure proper amount of tokens transferred in.
        if (callbackAddr != address(0)) {
            // Send quote token to callback (transferred in first to allow use during callback)
            quoteToken.safeTransfer(callbackAddr, amountLessFee);

            // Call the callback function to receive payout tokens for payout
            uint256 payoutBalance = payoutToken.balanceOf(address(this));
            IBondCallback(callbackAddr).callback(id_, amountLessFee, payout_);

            // Check to ensure that the callback sent the requested amount of payout tokens back to the teller
            if (payoutToken.balanceOf(address(this)) < (payoutBalance + payout_))
                revert Teller_InvalidCallback();
        } else {
            // If no callback is provided, transfer tokens from market owner to this contract
            // for payout.
            // Check balance before and after to ensure full amount received, revert if not
            // Handles edge cases like fee-on-transfer tokens (which are not supported)
            uint256 payoutBalance = payoutToken.balanceOf(address(this));
            payoutToken.safeTransferFrom(owner, address(this), payout_);
            if (payoutToken.balanceOf(address(this)) < (payoutBalance + payout_))
                revert Teller_UnsupportedToken();

            quoteToken.safeTransfer(owner, amountLessFee);
        }
    }

    /// @notice             Handle payout to recipient
    /// @dev                Implementation-agnostic. Must be implemented in contracts that
    ///                     extend this base since it is called by purchase.
    /// @param recipient_   Address to receive payout
    /// @param payout_      Amount of payoutToken to be paid
    /// @param underlying_   Token to be paid out
    /// @param vesting_     Time parameter for when the payout is available, could be a
    ///                     timestamp or duration depending on the implementation
    /// @return expiry      Timestamp when the payout will vest
    function _handlePayout(
        address recipient_,
        uint256 payout_,
        ERC20 underlying_,
        uint48 vesting_
    ) internal virtual returns (uint48 expiry);

    /// @notice             Derive name and symbol of token for market
    /// @param underlying_   Underlying token to be paid out when the Bond Token vests
    /// @param expiry_      Timestamp that the Bond Token vests at
    /// @return name        Bond token name, format is "Token YYYY-MM-DD"
    /// @return symbol      Bond token symbol, format is "TKN-YYYYMMDD"
    function _getNameAndSymbol(ERC20 underlying_, uint256 expiry_)
        internal
        view
        returns (string memory name, string memory symbol)
    {
        // Convert a number of days into a human-readable date, courtesy of BokkyPooBah.
        // Source: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol

        uint256 year;
        uint256 month;
        uint256 day;
        {
            int256 __days = int256(expiry_ / 1 days);

            int256 num1 = __days + 68569 + 2440588; // 2440588 = OFFSET19700101
            int256 num2 = (4 * num1) / 146097;
            num1 = num1 - (146097 * num2 + 3) / 4;
            int256 _year = (4000 * (num1 + 1)) / 1461001;
            num1 = num1 - (1461 * _year) / 4 + 31;
            int256 _month = (80 * num1) / 2447;
            int256 _day = num1 - (2447 * _month) / 80;
            num1 = _month / 11;
            _month = _month + 2 - 12 * num1;
            _year = 100 * (num2 - 49) + _year + num1;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }

        string memory yearStr = _uint2str(year % 10000);
        string memory monthStr = month < 10
            ? string(abi.encodePacked("0", _uint2str(month)))
            : _uint2str(month);
        string memory dayStr = day < 10
            ? string(abi.encodePacked("0", _uint2str(day)))
            : _uint2str(day);

        // Construct name/symbol strings.
        name = string(
            abi.encodePacked(underlying_.name(), " ", yearStr, "-", monthStr, "-", dayStr)
        );
        symbol = string(abi.encodePacked(underlying_.symbol(), "-", yearStr, monthStr, dayStr));
    }

    // Some fancy math to convert a uint into a string, courtesy of Provable Things.
    // Updated to work with solc 0.8.0.
    // https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20BondToken} from "../ERC20BondToken.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondFixedExpiryTeller {
    /// @notice          Redeem a fixed-expiry bond token for the underlying token (bond token must have matured)
    /// @param token_    Token to redeem
    /// @param amount_   Amount to redeem
    function redeem(ERC20BondToken token_, uint256 amount_) external;

    /// @notice              Deposit an ERC20 token and mint a future-dated ERC20 bond token
    /// @param underlying_   ERC20 token redeemable when the bond token vests
    /// @param expiry_       Timestamp at which the bond token can be redeemed for the underlying token
    /// @param amount_       Amount of underlying tokens to deposit
    /// @return              Address of the ERC20 bond token received
    /// @return              Amount of the ERC20 bond token received
    function create(
        ERC20 underlying_,
        uint48 expiry_,
        uint256 amount_
    ) external returns (ERC20BondToken, uint256);

    /// @notice             Deploy a new ERC20 bond token for an (underlying, expiry) pair and return its address
    /// @dev                ERC20 used for fixed-expiry
    /// @dev                If a bond token exists for the (underlying, expiry) pair, it returns that address
    /// @param underlying_  ERC20 token redeemable when the bond token vests
    /// @param expiry_      Timestamp at which the bond token can be redeemed for the underlying token
    /// @return             Address of the ERC20 bond token being created
    function deploy(ERC20 underlying_, uint48 expiry_) external returns (ERC20BondToken);

    /// @notice         Get the ERC20BondToken contract corresponding to a market
    /// @param id_      ID of the market
    /// @return         ERC20BondToken contract address
    function getBondTokenForMarket(uint256 id_) external view returns (ERC20BondToken);

    /// @notice             Get the ERC20BondToken contract corresponding to an (underlying, expiry) pair, reverts if no token exists
    /// @param underlying_  ERC20 token redeemable when the bond token vests
    /// @param expiry_      Timestamp at which the bond token can be redeemed for the underlying token (this is rounded to the nearest day)
    /// @return             ERC20BondToken contract address
    function getBondToken(ERC20 underlying_, uint48 expiry_) external view returns (ERC20BondToken);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {CloneERC20} from "./lib/CloneERC20.sol";

/// @title ERC20 Bond Token
/// @notice ERC20 Bond Token Contract
/// @dev Bond Protocol is a permissionless system to create Olympus-style bond markets
///      for any token pair. The markets do not require maintenance and will manage
///      bond prices based on activity. Bond issuers create BondMarkets that pay out
///      a Payout Token in exchange for deposited Quote Tokens. Users can purchase
///      future-dated Payout Tokens with Quote Tokens at the current market price and
///      receive Bond Tokens to represent their position while their bond vests.
///      Once the Bond Tokens vest, they can redeem it for the Quote Tokens.
///
/// @dev The ERC20 Bond Token contract is issued by a Fixed Expiry Teller to
///      represent bond positions until they vest. Bond tokens can be redeemed for
//       the underlying token 1:1 at or after expiry.
///
/// @dev This contract uses Clones (https://github.com/wighawag/clones-with-immutable-args)
///      to save gas on deployment and is based on VestedERC20 (https://github.com/ZeframLou/vested-erc20)
///
/// @author Oighty, Zeus, Potted Meat, indigo
contract ERC20BondToken is CloneERC20 {
    /* ========== ERRORS ========== */
    error BondToken_OnlyTeller();

    /* ========== IMMUTABLE PARAMETERS ========== */

    /// @notice The token to be redeemed when the bond vests
    /// @return _underlying The address of the underlying token
    function underlying() external pure returns (ERC20 _underlying) {
        return ERC20(_getArgAddress(0x41));
    }

    /// @notice Timestamp at which the BondToken can be redeemed for the underlying
    /// @return _expiry The vest start timestamp
    function expiry() external pure returns (uint48 _expiry) {
        return uint48(_getArgUint256(0x55));
    }

    /// @notice Address of the Teller that created the token
    function teller() public pure returns (address _teller) {
        return _getArgAddress(0x75);
    }

    /* ========== MINT/BURN ========== */

    function mint(address to, uint256 amount) external {
        if (msg.sender != teller()) revert BondToken_OnlyTeller();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != teller()) revert BondToken_OnlyTeller();
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// @author Taken from Solmate.
library TransferHelper {
    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transferFrom.selector, from, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(
            success &&
                (data.length == 0 || abi.decode(data, (bool))) &&
                address(token).code.length > 0,
            "TRANSFER_FAILED"
        );
    }

    // function safeApprove(
    //     ERC20 token,
    //     address to,
    //     uint256 amount
    // ) internal {
    //     (bool success, bytes memory data) = address(token).call(
    //         abi.encodeWithSelector(ERC20.approve.selector, to, amount)
    //     );

    //     require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    // }

    // function safeTransferETH(address to, uint256 amount) internal {
    //     (bool success, ) = to.call{value: amount}(new bytes(0));

    //     require(success, "ETH_TRANSFER_FAILED");
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IGnosisEasyAuction} from "src/interfaces/IGnosisEasyAuction.sol";
import {BondFixedExpiryTeller} from "src/BondFixedExpiryTeller.sol";
import {IBondBatchAuctionFactoryV1} from "src/interfaces/IBondBatchAuctionFactoryV1.sol";

interface IBondBatchAuctionV1 {
    /* ========== STRUCTS ========== */

    struct AuctionData {
        ERC20 quoteToken; // The token that the auction owner is acquiring
        ERC20 payoutToken; // The token that the auction owner is selling (an ERC20BondToken which wraps a token provided by the owner)
        bool created; // Whether the auction has been created. Used to gate "settling" functions which don't exist.
        bool settled; // Whether the auction has been settled. Accurate if settleBatchAuction or withdrawExternallySettledFunds is called after an auction ends, but may contain dirty state when emergency measures are used or if not action is taken. Rely on isLive to know if an auction has ended.
        uint48 auctionEnd; // The timestamp that the batch auction ends on.
        uint256 payoutAmount; // The amount of payout tokens being auctioned off.
    }

    struct BondTokenParams {
        ERC20 underlying; // The underlying ERC20 token to create payout bond tokens from.
        uint48 expiry; // The timestamp that the payout bond tokens will vest at.
    }

    struct BatchAuctionParams {
        BondTokenParams payoutTokenParams; // The parameters for the payout bond token to be created and sold in the auction.
        ERC20 quoteToken; // The token that the auction owner is acquiring.
        uint256 cancelUntil; // The timestamp that users can cancel their orders until.
        uint256 auctionEnd; // The timestamp that the batch auction ends on.
        uint96 auctionAmount; // The amount of payout tokens being auctioned off.
        uint96 minBuyAmount; // The minimum number of quote tokens to be bought for the auctionAmount (sets minimum price as minBuyAmount/auctionAmount)
        uint256 minBuyAmountPerOrder; // The minimum purchase size in quote tokens for an order (prevents running out of gas settling the auction with a bunch of small orders)
        uint256 minFundingThreshold; // Minimum amount of quote tokens that must be raised for the auction to be considered successful.
        uint96 liquidityAmount; // amount of payoutToken to be returned to sender to provide external liquidity with
        address accessManager; // Optional: a contract that can provide whitelist functionality for the auction
        bytes accessManagerData; // Optional: data to be passed to the accessManager contract
    }

    /* ========== IMMUTABLE CLONE ARGS ========== */

    /// @notice The Gnosis Easy Auction contract that the contract will create batch auctions on.
    function gnosisAuction() external pure returns (IGnosisEasyAuction);

    /// @notice The Bond Protocol Fixed Expiry Teller contract that the contract will create bond tokens on.
    function teller() external pure returns (BondFixedExpiryTeller);

    /// @notice The Bond Protocol Batch Auction Factory contract that created this contract.
    function factory() external pure returns (IBondBatchAuctionFactoryV1);

    /// @notice The address of the owner of the contract.
    function owner() external pure returns (address);

    /* ========== AUCTION MANAGEMENT ========== */

    /// @notice Creates a new batch auction to sell bond tokens for a quote token using Gnosis EasyAuction.
    /// @notice Access controlled - only the owner of this contract can call
    /// @param batchAuctionParams_ Parameters for the batch auction. See struct definition in IBondBatchAuctionV1.sol.
    /// @dev Warning: In case the auction is expected to raise more than
    /// 2^96 units of the quoteToken, don't start the auction, as
    /// it will not be settlable. This corresponds to about 79
    /// billion DAI.
    ///
    /// Prices between quoteToken and payoutToken are expressed by a
    /// fraction whose components are stored as uint96.
    function initiateBatchAuction(BatchAuctionParams memory batchAuctionParams_)
        external
        returns (uint256);

    /// @notice Settle a batch auction that has concluded on the Gnosis Easy Auction contract
    /// @notice Access controlled - only the owner of this contract can call
    /// @param  auctionId_ The ID of the auction to settle
    /// @return The clearing order from the Easy Auction contract
    /// @dev We assume the auction is at the correct stage on the Easy Auction contract, if not, it will revert
    function settleBatchAuction(uint256 auctionId_) external returns (bytes32);

    /// @notice Withdraw quote and/or payout tokens received from a batch auction settled outside of this contract.
    /// @notice Access controlled - only the owner of this contract can call
    /// @dev Gnosis EasyAuction allows anyone to settle a batch auction that has ended.
    ///      This function allows the owner to withdraw the tokens received when the auction is settled externally.
    ///      Additionally, this function "settles" the auction on this contract to avoid dirty state remaining.
    /// @param auctionId_ The ID of the auction to withdraw tokens from.
    function withdrawExternallySettledFunds(uint256 auctionId_) external;

    /// @notice Withdraw tokens or ETH that are stuck in the contract
    /// @notice Access controlled - only the owner of this contract can call
    /// @dev This function is an emergency failsafe to prevent tokens or ETH from being stuck in the contract.
    ///      In general, withdrawExternallySettledFunds should be preferred over this for auctions settled externally.
    /// @param token_ The token to withdraw. If address(0), withdraws ETH.
    function emergencyWithdraw(ERC20 token_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Returns the number of auctions created by this contract.
    /// @dev This is useful for getting the length of auctions array for pagination with liveAuctions.
    function numAuctions() external view returns (uint256);

    /// @notice Returns the auction data for a given auction ID.
    /// @param auctionId_ The ID of the auction to get data for.
    function auctionData(uint256 auctionId_) external view returns (AuctionData memory);

    /// @notice Returns the amount of payout tokens that is required, inclusive of any fees charged by the Gnosis Auction and Teller contracts.
    /// @dev This method should be used to determine the amount of payout tokens required to approve for the given amount of tokens to auction.
    /// @dev Both contracts currently charge zero fees, but this function is provided in case they do in the future.
    /// @param auctionAmount_ The amount of payout tokens to auction.
    function amountWithFee(uint256 auctionAmount_) external view returns (uint256);

    /// @notice Returns the amount of payout tokens that is required for the desired liquidity amount, inclusive of any fee charged by the Teller contract.
    /// @dev This method should be used to determine the amount of payout tokens required to approve for the given amount of additional tokens to mint for liquidity.
    /// @dev The Teller contract currently charges zero fees, but this function is provided in case it does in the future.
    /// @param liquidityAmount_ The amount of payout tokens to mint for liquidity.
    function amountWithTellerFee(uint256 liquidityAmount_) external view returns (uint256);

    /// @notice Whether or not an auction is live.
    /// @param auctionId_ The auction ID to check status for.
    /// @dev This data can also be retrieved from a specific clone. This functions routes a request for data to the correct clone.
    function isLive(uint256 auctionId_) external view returns (bool);

    /// @notice Returns the auction IDs of live auctions created by this contract in the provided index range.
    /// @dev This function uses a start and end index to allow for pagination of the auctions array in order to iterate through an increasingly large array without hitting the gas limit.
    /// @param startIndex_ The start index of the auctions array to start iterating from (inclusive).
    /// @param endIndex_ The end index of the auctions array to stop iterating at (non-inclusive).
    /// @dev The indexes are over the array of all auctions, are 0-indexed, and the endIndex_ is non-inclusive, i.e. [startIndex, endIndex).
    function liveAuctions(uint256 startIndex_, uint256 endIndex_)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondTeller {
    /// @notice                 Exchange quote tokens for a bond in a specified market
    /// @param recipient_       Address of recipient of bond. Allows deposits for other addresses
    /// @param referrer_        Address of referrer who will receive referral fee. For frontends to fill.
    ///                         Direct calls can use the zero address for no referrer fee.
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return                 Amount of payout token to be received from the bond
    /// @return                 Timestamp at which the bond token can be redeemed for the underlying token
    function purchase(
        address recipient_,
        address referrer_,
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256, uint48);

    /// @notice          Get current fee charged by the teller based on the combined protocol and referrer fee
    /// @param referrer_ Address of the referrer
    /// @return          Fee in basis points (3 decimal places)
    function getFee(address referrer_) external view returns (uint48);

    /// @notice         Set protocol fee
    /// @notice         Must be guardian
    /// @param fee_     Protocol fee in basis points (3 decimal places)
    function setProtocolFee(uint48 fee_) external;

    /// @notice          Set the discount for creating bond tokens from the base protocol fee
    /// @dev             The discount is subtracted from the protocol fee to determine the fee
    ///                  when using create() to mint bond tokens without using an Auctioneer
    /// @param discount_ Create Fee Discount in basis points (3 decimal places)
    function setCreateFeeDiscount(uint48 discount_) external;

    /// @notice         Set your fee as a referrer to the protocol
    /// @notice         Fee is set for sending address
    /// @param fee_     Referrer fee in basis points (3 decimal places)
    function setReferrerFee(uint48 fee_) external;

    /// @notice         Claim fees accrued by sender in the input tokens and sends them to the provided address
    /// @param tokens_  Array of tokens to claim fees for
    /// @param to_      Address to send fees to
    function claimFees(ERC20[] memory tokens_, address to_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IBondCallback {
    /// @notice                 Send payout tokens to Teller while allowing market owners to perform custom logic on received or paid out tokens
    /// @notice                 Market ID on Teller must be whitelisted
    /// @param id_              ID of the market
    /// @param inputAmount_     Amount of quote tokens bonded to the market
    /// @param outputAmount_    Amount of payout tokens to be paid out to the market
    /// @dev Must transfer the output amount of payout tokens back to the Teller
    /// @dev Should check that the quote tokens have been transferred to the contract in the _callback function
    function callback(
        uint256 id_,
        uint256 inputAmount_,
        uint256 outputAmount_
    ) external;

    /// @notice         Returns the number of quote tokens received and payout tokens paid out for a market
    /// @param id_      ID of the market
    /// @return in_     Amount of quote tokens bonded to the market
    /// @return out_    Amount of payout tokens paid out to the market
    function amountsForMarket(uint256 id_) external view returns (uint256 in_, uint256 out_);

    /// @notice         Whitelist a teller and market ID combination
    /// @notice         Must be callback owner
    /// @param teller_  Address of the Teller contract which serves the market
    /// @param id_      ID of the market
    function whitelist(address teller_, uint256 id_) external;

    /// @notice Remove a market ID on a teller from the whitelist
    /// @dev    Shutdown function in case there's an issue with the teller
    /// @param  teller_ Address of the Teller contract which serves the market
    /// @param  id_     ID of the market to remove from whitelist
    function blacklist(address teller_, uint256 id_) external;

    /// @notice         Withdraw tokens from the callback and update balances
    /// @notice         Only callback owner
    /// @param to_      Address of the recipient
    /// @param token_   Address of the token to withdraw
    /// @param amount_  Amount of tokens to withdraw
    function withdraw(
        address to_,
        ERC20 token_,
        uint256 amount_
    ) external;

    /// @notice         Deposit tokens to the callback and update balances
    /// @notice         Only callback owner
    /// @param token_   Address of the token to deposit
    /// @param amount_  Amount of tokens to deposit
    function deposit(ERC20 token_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondAuctioneer} from "../interfaces/IBondAuctioneer.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";

interface IBondAggregator {
    /// @notice             Register a auctioneer with the aggregator
    /// @notice             Only Guardian
    /// @param auctioneer_  Address of the Auctioneer to register
    /// @dev                A auctioneer must be registered with an aggregator to create markets
    function registerAuctioneer(IBondAuctioneer auctioneer_) external;

    /// @notice             Register a new market with the aggregator
    /// @notice             Only registered depositories
    /// @param payoutToken_ Token to be paid out by the market
    /// @param quoteToken_  Token to be accepted by the market
    /// @param marketId     ID of the market being created
    function registerMarket(ERC20 payoutToken_, ERC20 quoteToken_)
        external
        returns (uint256 marketId);

    /// @notice     Get the auctioneer for the provided market ID
    /// @param id_  ID of Market
    function getAuctioneer(uint256 id_) external view returns (IBondAuctioneer);

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @dev                Accounts for debt and control variable decay since last deposit (vs _marketPrice())
    /// @param id_          ID of market
    /// @return             Price for market (see the specific auctioneer for units)
    //
    // if price is below minimum price, minimum price is returned
    // this is enforced on deposits by manipulating total debt (see _decay())
    function marketPrice(uint256 id_) external view returns (uint256);

    /// @notice             Scale value to use when converting between quote token and payout token amounts with marketPrice()
    /// @param id_          ID of market
    /// @return             Scaling factor for market in configured decimals
    function marketScale(uint256 id_) external view returns (uint256);

    /// @notice             Payout due for amount of quote tokens
    /// @dev                Accounts for debt and control variable decay so it is up to date
    /// @param amount_      Amount of quote tokens to spend
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    /// @return             amount of payout tokens to be paid
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) external view returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256);

    /// @notice             Does market send payout immediately
    /// @param id_          Market ID to search for
    function isInstantSwap(uint256 id_) external view returns (bool);

    /// @notice             Is a given market accepting deposits
    /// @param id_          ID of market
    function isLive(uint256 id_) external view returns (bool);

    /// @notice             Returns array of active market IDs within a range
    /// @dev                Should be used if length exceeds max to query entire array
    function liveMarketsBetween(uint256 firstIndex_, uint256 lastIndex_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given quote token
    /// @param token_       Address of token to query by
    /// @param isPayout_    If true, search by payout token, else search for quote token
    function liveMarketsFor(address token_, bool isPayout_)
        external
        view
        returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given owner
    /// @param owner_       Address of owner to query by
    /// @param firstIndex_  Market ID to start at
    /// @param lastIndex_   Market ID to end at (non-inclusive)
    function liveMarketsBy(
        address owner_,
        uint256 firstIndex_,
        uint256 lastIndex_
    ) external view returns (uint256[] memory);

    /// @notice             Returns an array of all active market IDs for a given payout and quote token
    /// @param payout_      Address of payout token
    /// @param quote_       Address of quote token
    function marketsFor(address payout_, address quote_) external view returns (uint256[] memory);

    /// @notice                 Returns the market ID with the highest current payoutToken payout for depositing quoteToken
    /// @param payout_          Address of payout token
    /// @param quote_           Address of quote token
    /// @param amountIn_        Amount of quote tokens to deposit
    /// @param minAmountOut_    Minimum amount of payout tokens to receive as payout
    /// @param maxExpiry_       Latest acceptable vesting timestamp for bond
    ///                         Inputting the zero address will take into account just the protocol fee.
    function findMarketFor(
        address payout_,
        address quote_,
        uint256 amountIn_,
        uint256 minAmountOut_,
        uint256 maxExpiry_
    ) external view returns (uint256 id);

    /// @notice             Returns the Teller that services the market ID
    function getTeller(uint256 id_) external view returns (IBondTeller);

    /// @notice             Returns current capacity of a market
    function currentCapacity(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IBondAggregator} from "../interfaces/IBondAggregator.sol";

interface IBondAuctioneer {
    /// @notice                 Creates a new bond market
    /// @param params_          Configuration data needed for market creation, encoded in a bytes array
    /// @dev                    See specific auctioneer implementations for details on encoding the parameters.
    /// @return id              ID of new bond market
    function createMarket(bytes memory params_) external returns (uint256);

    /// @notice                 Disable existing bond market
    /// @notice                 Must be market owner
    /// @param id_              ID of market to close
    function closeMarket(uint256 id_) external;

    /// @notice                 Exchange quote tokens for a bond in a specified market
    /// @notice                 Must be teller
    /// @param id_              ID of the Market the bond is being purchased from
    /// @param amount_          Amount to deposit in exchange for bond (after fee has been deducted)
    /// @param minAmountOut_    Minimum acceptable amount of bond to receive. Prevents frontrunning
    /// @return payout          Amount of payout token to be received from the bond
    function purchaseBond(
        uint256 id_,
        uint256 amount_,
        uint256 minAmountOut_
    ) external returns (uint256 payout);

    /// @notice                         Set market intervals to different values than the defaults
    /// @notice                         Must be market owner
    /// @dev                            Changing the intervals could cause markets to behave in unexpected way
    ///                                 tuneInterval should be greater than tuneAdjustmentDelay
    /// @param id_                      Market ID
    /// @param intervals_               Array of intervals (3)
    ///                                 1. Tune interval - Frequency of tuning
    ///                                 2. Tune adjustment delay - Time to implement downward tuning adjustments
    ///                                 3. Debt decay interval - Interval over which debt should decay completely
    function setIntervals(uint256 id_, uint32[3] calldata intervals_) external;

    /// @notice                      Designate a new owner of a market
    /// @notice                      Must be market owner
    /// @dev                         Doesn't change permissions until newOwner calls pullOwnership
    /// @param id_                   Market ID
    /// @param newOwner_             New address to give ownership to
    function pushOwnership(uint256 id_, address newOwner_) external;

    /// @notice                      Accept ownership of a market
    /// @notice                      Must be market newOwner
    /// @dev                         The existing owner must call pushOwnership prior to the newOwner calling this function
    /// @param id_                   Market ID
    function pullOwnership(uint256 id_) external;

    /// @notice             Set the auctioneer defaults
    /// @notice             Must be policy
    /// @param defaults_    Array of default values
    ///                     1. Tune interval - amount of time between tuning adjustments
    ///                     2. Tune adjustment delay - amount of time to apply downward tuning adjustments
    ///                     3. Minimum debt decay interval - minimum amount of time to let debt decay to zero
    ///                     4. Minimum deposit interval - minimum amount of time to wait between deposits
    ///                     5. Minimum market duration - minimum amount of time a market can be created for
    ///                     6. Minimum debt buffer - the minimum amount of debt over the initial debt to trigger a market shutdown
    /// @dev                The defaults set here are important to avoid edge cases in market behavior, e.g. a very short market reacts doesn't tune well
    /// @dev                Only applies to new markets that are created after the change
    function setDefaults(uint32[6] memory defaults_) external;

    /// @notice             Change the status of the auctioneer to allow creation of new markets
    /// @dev                Setting to false and allowing active markets to end will sunset the auctioneer
    /// @param status_      Allow market creation (true) : Disallow market creation (false)
    function setAllowNewMarkets(bool status_) external;

    /// @notice             Change whether a market creator is allowed to use a callback address in their markets or not
    /// @notice             Must be guardian
    /// @dev                Callback is believed to be safe, but a whitelist is implemented to prevent abuse
    /// @param creator_     Address of market creator
    /// @param status_      Allow callback (true) : Disallow callback (false)
    function setCallbackAuthStatus(address creator_, bool status_) external;

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice                 Provides information for the Teller to execute purchases on a Market
    /// @param id_              Market ID
    /// @return owner           Address of the market owner (tokens transferred from this address if no callback)
    /// @return callbackAddr    Address of the callback contract to get tokens for payouts
    /// @return payoutToken     Payout Token (token paid out) for the Market
    /// @return quoteToken      Quote Token (token received) for the Market
    /// @return vesting         Timestamp or duration for vesting, implementation-dependent
    /// @return maxPayout       Maximum amount of payout tokens you can purchase in one transaction
    function getMarketInfoForPurchase(uint256 id_)
        external
        view
        returns (
            address owner,
            address callbackAddr,
            ERC20 payoutToken,
            ERC20 quoteToken,
            uint48 vesting,
            uint256 maxPayout
        );

    /// @notice             Calculate current market price of payout token in quote tokens
    /// @param id_          ID of market
    /// @return             Price for market in configured decimals
    //
    // if price is below minimum price, minimum price is returned
    function marketPrice(uint256 id_) external view returns (uint256);

    /// @notice             Scale value to use when converting between quote token and payout token amounts with marketPrice()
    /// @param id_          ID of market
    /// @return             Scaling factor for market in configured decimals
    function marketScale(uint256 id_) external view returns (uint256);

    /// @notice             Payout due for amount of quote tokens
    /// @dev                Accounts for debt and control variable decay so it is up to date
    /// @param amount_      Amount of quote tokens to spend
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    /// @return             amount of payout tokens to be paid
    function payoutFor(
        uint256 amount_,
        uint256 id_,
        address referrer_
    ) external view returns (uint256);

    /// @notice             Returns maximum amount of quote token accepted by the market
    /// @param id_          ID of market
    /// @param referrer_    Address of referrer, used to get fees to calculate accurate payout amount.
    ///                     Inputting the zero address will take into account just the protocol fee.
    function maxAmountAccepted(uint256 id_, address referrer_) external view returns (uint256);

    /// @notice             Does market send payout immediately
    /// @param id_          Market ID to search for
    function isInstantSwap(uint256 id_) external view returns (bool);

    /// @notice             Is a given market accepting deposits
    /// @param id_          ID of market
    function isLive(uint256 id_) external view returns (bool);

    /// @notice             Returns the address of the market owner
    /// @param id_          ID of market
    function ownerOf(uint256 id_) external view returns (address);

    /// @notice             Returns the Teller that services the Auctioneer
    function getTeller() external view returns (IBondTeller);

    /// @notice             Returns the Aggregator that services the Auctioneer
    function getAggregator() external view returns (IBondAggregator);

    /// @notice             Returns current capacity of a market
    function currentCapacity(uint256 id_) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Clone} from "clones/Clone.sol";

/// @notice Modern and gas efficient ERC20 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract CloneERC20 is Clone {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0)));
    }

    function symbol() external pure returns (string memory) {
        return string(abi.encodePacked(_getArgUint256(0x20)));
    }

    function decimals() external pure returns (uint8) {
        return _getArgUint8(0x40);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] += amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] -= amount;

        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);

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

    /*///////////////////////////////////////////////////////////////
                       INTERNAL LOGIC
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

    function _getImmutableVariablesOffset() internal pure returns (uint256 offset) {
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }
}