/**
 *Submitted for verification at Arbiscan on 2023-07-11
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
	function allWhitelistedTokens(uint256 _number) external view returns (address);
	function allWhitelistedTokensLength() external view returns (uint256);
}

interface IMiningStrat {
    function accountMultipliers(address _user) external view returns (uint256);
    function parity() external view returns (uint256);
	function currentMultiplier() external view returns (uint256);
}

interface IReferrer {
	function isPlayerReferred(address _user) external view returns (bool);
}

interface IFeeStrat {
	function getPeriodIndex() external view returns (uint256);
	function lastCalculatedIndex() external view returns (uint256);
	function currentMultiplier() external view returns (uint256);
	function lastDayReserves(address token) external view returns (uint256, uint256);
	function config() external view returns (uint256 minMultiplier, uint256 maxMultiplier);
}


contract Fees {
    address vault = 0x8c50528F4624551Aad1e7A265d6242C3b06c9Fca;
    address miningStrat = 0x296235E0067b7761eF4F36dCa4aA6311277745D4;
	address referrerSC = 0x3b12dabABCDf51Ae095A10256e67E9ef33BaDe5f;
	address feeStrat = 0x60317eBc9BE3CcBA8DE7730abCF9a8DBC7cDc29F;
	address USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;


	struct LastDayReserves {
		uint256 profit;
		uint256 loss;
	}
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


	function autoCalculate(address _account, uint256 _amount) external view returns (uint256 amount_) {
		uint256 parity = IMiningStrat(miningStrat).parity();
		bool _refered = IReferrer(referrerSC).isPlayerReferred(_account);
		uint256 value_ = computeDollarValue(USDC, _amount);
		uint256 multiplierBribe = IFeeStrat(miningStrat).currentMultiplier();
		uint256 multiplierDaily = IMiningStrat(miningStrat).currentMultiplier();
		uint256 _amountFees = (value_ * multiplierBribe) / PRECISION;
		uint256 accountMul = IMiningStrat(miningStrat).accountMultipliers(_account);
        uint256 mintAmount_;
        if (accountMul != 0) {
			mintAmount_ = ((_amountFees * accountMul * PRECISION) / parity) / PRECISION;
		} else {
			// Otherwise, use the current multiplier to calculate the mint amount
			mintAmount_ = ((_amountFees * multiplierDaily * PRECISION) / parity) / PRECISION;
		}
		if(_refered){
			mintAmount_ = mintAmount_*105 / 100;
		}
        return mintAmount_;
	}

    function calculateMint(address _account, address _token, uint256 _amount, uint256 _multiplierBribe, uint256 _currentMultiplier, uint256 _parity) external view returns (uint256 amount_) {
        bool _refered = IReferrer(referrerSC).isPlayerReferred(_account);
		uint256 value_ = computeDollarValue(_token, _amount);
		uint256 _amountFees = (value_ * _multiplierBribe) / PRECISION;
		uint256 accountMul = IMiningStrat(miningStrat).accountMultipliers(_account);
        uint256 mintAmount_;
        if (accountMul != 0) {
			mintAmount_ = ((_amountFees * accountMul * PRECISION) / _parity) / PRECISION;
		} else {
			// Otherwise, use the current multiplier to calculate the mint amount
			mintAmount_ = ((_amountFees * _currentMultiplier * PRECISION) / _parity) / PRECISION;
		}
		if(_refered){
			mintAmount_ = mintAmount_*105 / 100;
		}
        return mintAmount_;
    }

}