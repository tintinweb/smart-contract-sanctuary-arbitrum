// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IEnneadLpDepositor {
    function tokenForPool(address pool) external view returns (address);
}

interface IEnneadToken {
    function pool() external view returns (address);
}

/**
 * @title Ennead Whitelist for xRAM
 * @author Ramses Exchange
 * @notice Used as a lens contract to get all the Ennead contracts that's whitelisted to transfer xRAM
 */
contract EnneadWhitelist {
    // Ennead Addresses
    IEnneadLpDepositor public constant lpDepositor =
        IEnneadLpDepositor(0x1863736c768f232189F95428b5ed9A51B0eCcAe5);
    address public constant nfpDepositor =
        0xe99ead648Fb2893d1CFA4e8Fe8B67B35572d2581;
    address public constant neadStake =
        0x7D07A61b8c18cb614B99aF7B90cBBc8cD8C72680;
    address public constant feeHandler =
        0xe99ead4c038207A834A903FE6EdcBEf8CaE37B18;

    mapping(address sender => bool) public isWhitelisted;

    constructor() {
        // whitelist Ennead addresses
        isWhitelisted[address(lpDepositor)] = true;
        isWhitelisted[nfpDepositor] = true;
        isWhitelisted[neadStake] = true;
        isWhitelisted[feeHandler] = true;
    }

    /**
     * @notice Returns whether an address is whitelisted to transfer xRAM
     * @dev Writes Ennead pools to storage if not already stored
     * @param sender The address sending xRAM
     */
    function syncAndCheckIsWhitelisted(address sender) external returns (bool) {
        // return true if already stored
        if (isWhitelisted[sender]) {
            return true;
        }

        // Validate if the sender is an Ennead token if not on whitelist

        (bool sucess, bytes memory data) = sender.staticcall(
            abi.encodeWithSelector(IEnneadToken.pool.selector)
        );

        if (!sucess || data.length != 32) {
            return false;
        }

        address pool = abi.decode(data, (address));

        address token = lpDepositor.tokenForPool(pool);

        bool isValidEnneadToken = (sender == token);

        // Update whitelist if sender is a valid Ennead token
        if (isValidEnneadToken) {
            isWhitelisted[token] = true;
        }

        return isValidEnneadToken;
    }
}