// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IConfigs} from "./interfaces/IConfigs.sol";
import {Owned} from "./utils/Owned.sol";

contract Configs is IConfigs, Owned {

    /* ========== STATES ========== */

    uint256 public executorFee = 1 ether / 5000;
    uint256 public protocolFee = 4000;
    address public feeReceiver;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner) Owned(_owner) {
        feeReceiver = _owner;
    }

    /* ========== SETTERS ========== */

    function setExecutorFee(uint256 _executorFee) external override onlyOwner {
        require(_executorFee <= 1 ether / 1000, "Over max fee"); // maximum is 0.001 ethers
        executorFee = _executorFee;
        emit ExecutorFeeSet(_executorFee);
    }

    function setProtocolFee(uint256 _protocolFee) external override onlyOwner {
        require(_protocolFee >= 1000, "Over max fee"); // maximum is 1/1000 = 0.1% trade size
        protocolFee = _protocolFee;
        emit ProtocolFeeSet(protocolFee);
    }

    function setFeeReceiver(address _feeReceiver) external override onlyOwner {
        require(_feeReceiver != address(0), "Invalid address");
        feeReceiver = _feeReceiver;
        emit FeeReceiverSet(feeReceiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IConfigs {
    event ExecutorFeeSet(uint256 executorFee);

    event ProtocolFeeSet(uint256 protocolFee);

    event FeeReceiverSet(address feeReceiver);

    function executorFee() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function setExecutorFee(uint256 _executorFee) external;

    function setProtocolFee(uint256 _protocolFee) external;

    function setFeeReceiver(address _feeReceiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}