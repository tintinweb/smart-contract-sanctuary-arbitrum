// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPurchaser, Purchase} from "src/IPurchaser.sol";
import {IPoolCommitter} from "mycelium/IPoolCommitter.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract MyceliumPoolPurchaser is IPurchaser {
  IPoolCommitter private poolCommitter;
  ERC20 private usdcToken;
  address private leveragedPoolAddress;
  constructor (address _poolCommitterAddress, address _usdcAddress, address _leveragedPoolAddress) {
    poolCommitter = IPoolCommitter(_poolCommitterAddress);
    usdcToken = ERC20(_usdcAddress);
    leveragedPoolAddress = _leveragedPoolAddress; 
  }

  function Purchase(uint256 usdcAmount) external returns (Purchase memory) {
    bytes memory commit = abi.encodePacked(usdcAmount);
    usdcToken.approve(leveragedPoolAddress, usdcAmount);
    poolCommitter.commit(bytes32(commit));

    return Purchase({
      usdcAmount: usdcAmount,
      // Token amount is 0 as tokens are not minted straight away
      tokenAmount: 0
    });
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Purchase {
    uint256 usdcAmount;
    uint256 tokenAmount;
}

interface IPurchaser {
  function Purchase(uint256 usdcAmount) external returns (Purchase memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPoolCommitter {
    /// Type of commit
    enum CommitType {
        ShortMint, // Mint short tokens
        ShortBurn, // Burn short tokens
        LongMint, // Mint long tokens
        LongBurn, // Burn long tokens
        LongBurnShortMint, // Burn Long tokens, then instantly mint in same upkeep
        ShortBurnLongMint // Burn Short tokens, then instantly mint in same upkeep
    }

    function isMint(CommitType t) external pure returns (bool);

    function isBurn(CommitType t) external pure returns (bool);

    function isLong(CommitType t) external pure returns (bool);

    function isShort(CommitType t) external pure returns (bool);

    // Pool balances and supplies
    struct BalancesAndSupplies {
        uint256 newShortBalance;
        uint256 newLongBalance;
        uint256 longMintPoolTokens;
        uint256 shortMintPoolTokens;
        uint256 longBurnInstantMintSettlement;
        uint256 shortBurnInstantMintSettlement;
        uint256 totalLongBurnPoolTokens;
        uint256 totalShortBurnPoolTokens;
    }

    // User aggregate balance
    struct Balance {
        uint256 longTokens;
        uint256 shortTokens;
        uint256 settlementTokens;
    }

    // Token Prices
    struct Prices {
        bytes16 longPrice;
        bytes16 shortPrice;
    }

    // Commit information
    struct Commit {
        uint256 amount;
        CommitType commitType;
        uint40 created;
        address owner;
    }

    // Commit information
    struct TotalCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
    }

    // User updated aggregate balance
    struct BalanceUpdate {
        uint256 _updateIntervalId;
        uint256 _newLongTokensSum;
        uint256 _newShortTokensSum;
        uint256 _newSettlementTokensSum;
        uint256 _longSettlementFee;
        uint256 _shortSettlementFee;
        uint8 _maxIterations;
    }

    // Track how much of a user's commitments are being done from their aggregate balance
    struct UserCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
        uint256 updateIntervalId;
    }

    // Track the relevant data when executing a range of update interval's commitments (stack too deep)
    struct CommitmentExecutionTracking {
        uint256 longTotalSupply;
        uint256 shortTotalSupply;
        uint256 longTotalSupplyBefore;
        uint256 shortTotalSupplyBefore;
        uint256 _updateIntervalId;
    }

    /**
     * @notice Creates a notification when a commit is created
     * @param user The user making the commitment
     * @param amount Amount of the commit
     * @param commitType Type of the commit (Short v Long, Mint v Burn)
     * @param appropriateUpdateIntervalId Id of update interval where this commit can be executed as part of upkeep
     * @param fromAggregateBalance whether or not to commit from aggregate (unclaimed) balance
     * @param payForClaim whether or not to request this commit be claimed automatically
     * @param mintingFee Minting fee at time of commit creation
     */
    event CreateCommit(
        address indexed user,
        uint256 indexed amount,
        CommitType indexed commitType,
        uint256 appropriateUpdateIntervalId,
        bool fromAggregateBalance,
        bool payForClaim,
        bytes16 mintingFee
    );

    /**
     * @notice Creates a notification when a user's aggregate balance is updated
     */
    event AggregateBalanceUpdated(address indexed user);

    /**
     * @notice Creates a notification when the PoolCommitter's leveragedPool address has been updated.
     * @param newPool the address of the new leveraged pool
     */
    event PoolChanged(address indexed newPool);

    /**
     * @notice Creates a notification when commits for a given update interval are executed
     * @param updateIntervalId Unique identifier for the relevant update interval
     * @param burningFee Burning fee at the time of commit execution
     */
    event ExecutedCommitsForInterval(uint256 indexed updateIntervalId, bytes16 burningFee);

    /**
     * @notice Creates a notification when a claim is made, depositing pool tokens in user's wallet
     */
    event Claim(address indexed user);

    /*
     * @notice Creates a notification when the burningFee is updated
     */
    event BurningFeeSet(uint256 indexed _burningFee);

    /**
     * @notice Creates a notification when the mintingFee is updated
     */
    event MintingFeeSet(uint256 indexed _mintingFee);

    /**
     * @notice Creates a notification when the changeInterval is updated
     */
    event ChangeIntervalSet(uint256 indexed _changeInterval);

    /**
     * @notice Creates a notification when the feeController is updated
     */
    event FeeControllerSet(address indexed _feeController);

    // #### Functions

    function initialize(
        address _factory,
        address _autoClaim,
        address _factoryOwner,
        address _feeController,
        address _invariantCheck,
        uint256 mintingFee,
        uint256 burningFee,
        uint256 _changeInterval
    ) external;

    function commit(bytes32 args) external payable;

    function updateIntervalId() external view returns (uint128);

    function pendingMintSettlementAmount() external view returns (uint256);

    function pendingShortBurnPoolTokens() external view returns (uint256);

    function pendingLongBurnPoolTokens() external view returns (uint256);

    function claim(address user) external;

    function executeCommitments(
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 longBalance,
        uint256 shortBalance
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function updateAggregateBalance(address user) external;

    function getAggregateBalance(address user) external view returns (Balance memory _balance);

    function getAppropriateUpdateIntervalId() external view returns (uint128);

    function setPool(address _leveragedPool) external;

    function setBurningFee(uint256 _burningFee) external;

    function setMintingFee(uint256 _mintingFee) external;

    function setChangeInterval(uint256 _changeInterval) external;

    function setFeeController(address _feeController) external;
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