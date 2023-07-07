/**
 *Submitted for verification at Arbiscan on 2023-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

interface IVault {
    
    function tokenDecimals(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);
}

interface IMiningStrat {
    function accountMultipliers(address _user) external view returns (uint256);
    function parity() external view returns (uint256);
}


contract Fees {
    address vault = 0x8c50528F4624551Aad1e7A265d6242C3b06c9Fca;
    address miningStrat = 0x296235E0067b7761eF4F36dCa4aA6311277745D4;
    uint256 private constant PRECISION = 1e18;
    function computeDollarValue(
		address _token,
		uint256 _amount
	) public view returns (uint256 dollarValue_) {
		uint256 decimals_ = IVault(vault).tokenDecimals(_token); // Get the decimals of the token using the Vault interface
		dollarValue_ = ((_amount * IVault(vault).getMinPrice(_token)) / 10 ** decimals_); // Calculate the dollar value by multiplying the amount by the current dollar value of the token on the vault and dividing by 10^decimals
		dollarValue_ = dollarValue_ / 1e12; // Convert the result to USD by dividing by 1e12
	}

    function calculateFees(uint256 _multiplierBribe, address _token, uint256 _amount) external view returns (uint256 amount_) {
		uint256 value_ = computeDollarValue(_token, _amount);
		amount_ = (value_ * _multiplierBribe) / PRECISION;
	}

    function _calculate(uint256 _amount, uint256 _multiplier) internal view returns (uint256) {
		return ((_amount * _multiplier * PRECISION) / IMiningStrat(miningStrat).parity()) / PRECISION;
	}

    function calculateMint(address _account, uint256 _amountFees, uint256 _mintedByGames, uint256 _currentMultiplier) external view returns (uint256 amount_) {
        uint256 accountMul = IMiningStrat(miningStrat).accountMultipliers(_account);
        uint256 mintAmount_;
        if (accountMul != 0) {
			mintAmount_ = _calculate(_amountFees, accountMul);
		} else {
			// Otherwise, use the current multiplier to calculate the mint amount
			mintAmount_ = _calculate(_amountFees, _currentMultiplier);
		}
        return mintAmount_;
    }
}