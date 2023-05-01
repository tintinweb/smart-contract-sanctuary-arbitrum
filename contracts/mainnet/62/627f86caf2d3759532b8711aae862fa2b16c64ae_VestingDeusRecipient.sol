/**
 *Submitted for verification at Arbiscan on 2023-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************************
 *                    Ownable
 **************************************************/
contract OwnableExecutor {
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

/**************************************************
 *                    Interfaces
 **************************************************/
interface IVestingDeus {
    function claim() external;
}

interface IERC20 {
    function transfer(address, uint256) external;

    function balanceOf(address) external view returns (uint256);
}

/**************************************************
 *               Vesting Deus Recipient
 **************************************************/
contract VestingDeusRecipient is OwnableExecutor {
    IVestingDeus vestingDeus;
    IERC20 deus = IERC20(0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44);
    address public recipient0;
    address public recipient1;

    constructor(
        address _vestingDeus,
        address _recipient0,
        address _recipient1
    ) {
        vestingDeus = IVestingDeus(_vestingDeus);
        recipient0 = _recipient0;
        recipient1 = _recipient1;
    }

    function setRecipient0(address recipient) external {
        require(msg.sender == recipient0, "Only recipient 0");
        recipient0 = recipient;
    }

    function setRecipient1(address recipient) external {
        require(msg.sender == recipient1, "Only recipient 1");
        recipient1 = recipient;
    }

    function claim() external {
        vestingDeus.claim();
        uint256 balance = deus.balanceOf(address(this));
        require(
            msg.sender == recipient0 || msg.sender == recipient1,
            "Only recipient"
        );
        deus.transfer(recipient0, balance / 2);
        deus.transfer(recipient1, balance / 2);
    }
}