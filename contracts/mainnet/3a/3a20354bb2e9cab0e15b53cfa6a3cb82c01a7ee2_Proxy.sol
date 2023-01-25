// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccount {
    function activate() external;
    function deactivate() external;
    function addAsset(address token) external;
    function addBorrow(address token) external;
    function removeAsset(address token) external;
    function sweepTo(address toAddress) external;
    function removeBorrow(address token) external;
    function init(address accountManager) external;
    function hasAsset(address) external returns (bool);
    function assets(uint) external returns (address);
    function hasNoDebt() external view returns (bool);
    function activationBlock() external view returns (uint);
    function accountManager() external view returns (address);
    function getAssets() external view returns (address[] memory);
    function getBorrows() external view returns (address[] memory);
    function exec(
        address target,
        uint amt,
        bytes calldata data
    ) external returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)
        external returns (bool success);
    function approve(address _spender, uint256 _value)
        external returns (bool success);
    function allowance(address _owner, address _spender)
        external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value)
        external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {StorageSlot} from "../utils/Storage.sol";

abstract contract BaseProxy {

    bytes32 private constant _ADMIN_SLOT =
        bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);

    event AdminChanged(address previousAdmin, address newAdmin);

    modifier adminOnly() {
        if (msg.sender != getAdmin()) revert Errors.AdminOnly();
        _;
    }

    function changeAdmin(address newAdmin) external adminOnly {
        _setAdmin(newAdmin);
    }

    function getAdmin() public view returns (address) {
        return StorageSlot.getAddressAt(_ADMIN_SLOT);
    }

    function _setAdmin(address admin) internal {
        if (admin == address(0)) revert Errors.ZeroAddress();
        emit AdminChanged(getAdmin(), admin);
        StorageSlot.setAddressAt(_ADMIN_SLOT, admin);
    }

    function getImplementation() public virtual returns (address);

    function _delegate(address impl) internal virtual {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)

            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    fallback() external payable {
        _delegate(getImplementation());
    }

    receive() external payable {
        _delegate(getImplementation());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseProxy} from "./BaseProxy.sol";
import {Errors} from "../utils/Errors.sol";
import {StorageSlot} from "../utils/Storage.sol";
import {Helpers} from "../utils/Helpers.sol";

contract Proxy is BaseProxy {

    bytes32 private constant _IMPL_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    event Upgraded(address indexed newImplementation);

    constructor(address _logic) {
        _setImplementation(_logic);
        _setAdmin(msg.sender);
    }

    function changeImplementation(address implementation) external adminOnly {
        _setImplementation(implementation);
    }

    function upgradeToAndCall(address implementation, bytes calldata data) external adminOnly {
        _upgradeToAndCall(implementation, data);
    }

    function getImplementation() public override view returns (address) {
        return StorageSlot.getAddressAt(_IMPL_SLOT);
    }

    function _setImplementation(address implementation) internal {
        if (implementation == address(0)) revert Errors.ZeroAddress();
        StorageSlot.setAddressAt(_IMPL_SLOT, implementation);
        emit Upgraded(implementation);
    }

    function _upgradeToAndCall(address implementation, bytes calldata data) internal {
        _setImplementation(implementation);
        if (data.length > 0) Helpers.functionDelegateCall(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    error AdminOnly();
    error MaxSupply();
    error ZeroShares();
    error ZeroAssets();
    error MaxAssetCap();
    error ZeroAddress();
    error MinimumShares();
    error ContractPaused();
    error OutstandingDebt();
    error AccountOwnerOnly();
    error TokenNotContract();
    error AddressNotContract();
    error ContractNotPaused();
    error LTokenUnavailable();
    error LiquidationFailed();
    error EthTransferFailure();
    error AccountManagerOnly();
    error RiskThresholdBreached();
    error FunctionCallRestricted();
    error AccountNotLiquidatable();
    error CollateralTypeRestricted();
    error IncorrectConstructorArgs();
    error ContractAlreadyInitialized();
    error AccountDeactivationFailure();
    error AccountInteractionFailure(address, address, uint, bytes);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";
import {IERC20} from "../interface/tokens/IERC20.sol";
import {IAccount} from "../interface/core/IAccount.sol";

/// @author Modified from Rari-Capital/Solmate
library Helpers {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amt
    ) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amt)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amt
    ) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amt)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeTransferEth(address to, uint256 amt) internal {
        (bool success, ) = to.call{value: amt}(new bytes(0));
        if(!success) revert Errors.EthTransferFailure();
    }

    function balanceOf(address token, address owner) internal view returns (uint) {
        return IERC20(token).balanceOf(owner);
    }

    function withdrawEth(address account, address to, uint amt) internal {
        (bool success, ) = IAccount(account).exec(to, amt, new bytes(0));
        if(!success) revert Errors.EthTransferFailure();
    }

    function withdraw(address account, address to, address token, uint amt) internal {
        if (!isContract(token)) revert Errors.TokenNotContract();
        (bool success, bytes memory data) = IAccount(account).exec(token, 0,
                abi.encodeWithSelector(IERC20.transfer.selector, to, amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(address account, address token, address spender, uint amt) internal {
        (bool success, bytes memory data) = IAccount(account).exec(token, 0,
            abi.encodeWithSelector(IERC20.approve.selector, spender, amt));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function isContract(address token) internal view returns (bool) {
        return token.code.length > 0;
    }

    function functionDelegateCall(
        address target,
        bytes calldata data
    ) internal {
        if (!isContract(target)) revert Errors.AddressNotContract();
        (bool success, ) = target.delegatecall(data);
        require(success, "CALL_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StorageSlot {
    function getAddressAt(bytes32 slot) internal view returns (address a) {
        assembly {
            a := sload(slot)
        }
    }

    function setAddressAt(bytes32 slot, address address_) internal {
        assembly {
            sstore(slot, address_)
        }
    }
}