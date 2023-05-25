/**
 *Submitted for verification at Arbiscan on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************************
 *                    Ownable
 **************************************************/
contract Ownable {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    constructor() {
        owner = msg.sender;
    }
}

/**************************************************
 *                    Interfaces
 **************************************************/
interface IOracle {
    function deusPriceUsdc() external view returns (uint256);
}

interface IERC20 {
    function transfer(address, uint256) external;
}

/**************************************************
 *                 Vesting Deus
 **************************************************/
contract VestingDeus is Ownable {
    /**************************************************
     *                 Storage slots
     **************************************************/
    uint256 public amountPaidUsdc; // Accounting
    IOracle public oracle; // Oracle

    /**************************************************
     *             Constants and immutables
     **************************************************/
    uint256 public constant totalAmountOwedUsdc = 1_000_000 * 10 ** 6; // Amount owed
    uint256 public constant floorPriceUsdc = 40 * 10 ** 6; // $40 floor
    uint256 internal constant vestingDurationSeconds = 2 * 365 days; // 2 year vest duration

    // Start and end date
    uint256 public constant startDate = 1672494599; // https://etherscan.io/tx/0xd6dea0eb965790773941ff1805d0236e18e3844f1aeb17ed806ff7f7a5ad1f70
    uint256 public constant endDate = startDate + vestingDurationSeconds;

    // Cliff
    uint256 internal constant cliffDurationSeconds = 30 days * 3; // Three months
    uint256 internal constant cliffEndDate = startDate + cliffDurationSeconds;

    // Important addresses
    address public recipient;
    IERC20 public constant deus =
        IERC20(0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44);

    /**************************************************
     *                   Modifiers
     **************************************************/
    modifier onlyRecipient() {
        require(msg.sender == recipient, "Caller is not the recipient");
        _;
    }

    /**************************************************
     *                   Constructor
     **************************************************/
    constructor(address _oracle) {
        oracle = IOracle(_oracle);
        recipient = msg.sender;
    }

    /**************************************************
     *                    Claiming
     **************************************************/
    function claim() external onlyRecipient {
        // Calculate amount of claimable DEUS and USDC equivalent
        (uint256 claimableDeus, uint256 claimableUsdc) = amountsClaimable();

        // Transfer DEUS
        deus.transfer(recipient, claimableDeus);

        // Increment amount paid
        amountPaidUsdc += claimableUsdc;
    }

    /**************************************************
     *                    Management
     **************************************************/

    /**
     * @notice Set oracle
     * @dev Only owner can set oracle
     */
    function setOracle(address _oracle) external onlyOwner {
        oracle = IOracle(_oracle);
    }

    /**
     * @notice Set recipient
     * @dev Only recipient can set recipient
     */
    function setRecipient(address _recipient) external onlyRecipient {
        recipient = _recipient;
    }

    /**************************************************
     *                   View methods
     **************************************************/
    /**
     * @notice Amount of USDC claimable at a given moment based on amount paid
     */
    function amountClaimableUsdc() public view returns (uint256) {
        return totalAmountOwedUsdcToDate() - amountPaidUsdc;
    }

    /**
     * @notice Total amount of USDC owed to date (not including amounts paid out)
     */
    function totalAmountOwedUsdcToDate() public view returns (uint256) {
        return totalAmountOwedUsdcAtTime(block.timestamp);
    }

    /**
     * @notice Calculate amount of claimable DEUS at current moment
     * @dev Considers amount paid to date and amount owed to date in USDC
     * @dev Utilize current TWAP price
     */
    function amountsClaimable()
        public
        view
        returns (uint256 claimableDeus, uint256 claimableUsdc)
    {
        // Get amount claimable as per oracle TWAP assuming infinite liquidity
        claimableUsdc = amountClaimableUsdc();
        uint256 deusPriceUsdc = oracle.deusPriceUsdc();
        uint256 price = deusPriceUsdc;
        if (price >= floorPriceUsdc) {
            price = floorPriceUsdc;
        }
        claimableDeus = (claimableUsdc * 10 ** 18) / price; // Small loss of precision, DEUS amount is truncated and rounded down
    }

    /**
     * @notice Total amount of USDC owed at a specific time (not including amounts paid out)
     */
    function totalAmountOwedUsdcAtTime(
        uint256 timestamp
    ) public pure returns (uint256) {
        if (timestamp < cliffEndDate) {
            return 0;
        }
        if (timestamp > endDate) {
            return totalAmountOwedUsdc;
        }
        uint256 timeElapsed = (timestamp - startDate);
        return ((totalAmountOwedUsdc * timeElapsed) / vestingDurationSeconds);
    }

    /**************************************************
     *                    Execution
     **************************************************/
    enum Operation {
        Call,
        DelegateCall
    }

    /**
     * @notice Allow owner to have complete control over vesting contract
     * @param to The target address
     * @param value The amount of gas token to send with the transaction
     * @param data Raw input data
     * @param operation CALL or DELEGATECALL
     */
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external onlyOwner returns (bool success) {
        if (operation == Operation.Call) success = executeCall(to, value, data);
        else if (operation == Operation.DelegateCall)
            success = executeDelegateCall(to, data);
        require(success == true, "Transaction failed");
    }

    /**
     * @notice Execute an arbitrary call from the context of this contract
     * @param to The target address
     * @param value The amount of gas token to send with the transaction
     * @param data Raw input data
     */
    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    /**
     * @notice Execute a delegateCall from the context of this contract
     * @param to The target address
     * @param data Raw input data
     */
    function executeDelegateCall(
        address to,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := delegatecall(
                gas(),
                to,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}