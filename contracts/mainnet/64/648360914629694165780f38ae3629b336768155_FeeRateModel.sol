/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {IFeeRateImpl} from "../interfaces/IFeeRateModel.sol";

contract FeeRateModel is Owned {
    event LogImplementationChanged(address indexed implementation);
    event LogMaintainerChanged(address indexed maintainer);

    error ErrZeroAddress();

    address public maintainer;
    address public implementation;

    constructor(address maintainer_, address owner_) Owned(owner_) {
        if (maintainer_ == address(0)) {
            revert ErrZeroAddress();
        }

        maintainer = maintainer_;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// VIEWS
    //////////////////////////////////////////////////////////////////////////////////////

    function getFeeRate(address trader, uint256 lpFeeRate) external view returns (uint256 adjustedLpFeeRate, uint256 mtFeeRate) {
        if (implementation == address(0)) {
            return (lpFeeRate, 0);
        }

        return IFeeRateImpl(implementation).getFeeRate(msg.sender, trader, lpFeeRate);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// ADMIN
    //////////////////////////////////////////////////////////////////////////////////////

    function setMaintainer(address maintainer_) external onlyOwner {
        if (maintainer_ == address(0)) {
            revert ErrZeroAddress();
        }

        maintainer = maintainer_;
        emit LogMaintainerChanged(maintainer_);
    }

    /// @notice Set the fee rate implementation and default fee rate
    /// @param implementation_ The address of the fee rate implementation, use address(0) to disable
    function setImplementation(address implementation_) public onlyOwner {
        implementation = implementation_;
        emit LogImplementationChanged(implementation_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0;

interface IFeeRateImpl {
    function getFeeRate(
        address pool,
        address trader,
        uint256 lpFeeRate
    ) external view returns (uint256 adjustedLpFeeRate, uint256 mtFeeRate);
}

interface IFeeRateModel {
    function maintainer() external view returns (address);

    function getFeeRate(address trader, uint256 lpFeeRate) external view returns (uint256 adjustedLpFeeRate, uint256 mtFeeRate);
}