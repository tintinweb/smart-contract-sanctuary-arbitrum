// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.13;

// ====================================================================
// ======================= Transfer Approver ======================
// ====================================================================

// Primary Author(s)
// Che Jin: https://github.com/topdev104

import "./Ownable.sol";

/**
 * @title Sweep Transfer Approver
 * @dev Allows accounts to be blacklisted by admin role
 */
contract TransferApprover is Ownable {
    address public admin;
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event AdminChanged(address indexed newAdmin);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _admin_address) {
        admin = _admin_address;
    }

    /**
     * @dev Throws if called by any account other than admin
     */
    modifier onlyAdmin {
        require(
            msg.sender == admin,
            "Caller is not admin"
        );
        _;
    }

    /**
    * @notice Returns token transferability
    * @param _from sender address
    * @param _to beneficiary address
    * @return (bool) true - allowance, false - denial
    */
    function checkTransfer(address _from, address _to) external view returns (bool) {
        if (_from == address(0) || _to == address(0)) return true;

        return (!blacklisted[_from] && !blacklisted[_to]) ? true : false;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) external view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function blacklist(address _account) external onlyAdmin {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function unBlacklist(address _account) external onlyAdmin {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateAdmin(address _newAdmin) external onlyOwner {
        require(
            _newAdmin != address(0),
            "new admin is the zero address"
        );
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }
}