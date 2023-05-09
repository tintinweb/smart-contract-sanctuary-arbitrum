// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { FlashLoanReceiverBase } from "FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "Interfaces.sol";
import { SafeMath } from "Libraries.sol";
import "./Ownable.sol";

interface ISwapper {
    function swap(
        address collateral,
        bytes calldata swapData
    ) external;
}

/*
* A contract that liquidates an aave loan using a flash loan:
*
*   call executeFlashLoans() to begin the liquidation
*
*/
contract LiquidateLoan is FlashLoanReceiverBase, Ownable {

    ILendingPoolAddressesProvider provider;
    using SafeMath for uint256;

    address immutable public lendingPoolAddr;
    address immutable public USDC;


    event ErrorHandled(string stringFailure);

    // intantiate lending pool addresses provider and get lending pool address
    constructor(ILendingPoolAddressesProvider _addressProvider, address USDC_ ) FlashLoanReceiverBase(_addressProvider) public {
        provider = _addressProvider;
        lendingPoolAddr = provider.getLendingPool();
        USDC = USDC_;
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {

        //collateral  the address of the token that we will be compensated in
        //userToLiquidate - id of the user to liquidate
        //amountOutMin - minimum amount of asset paid when swapping collateral

        {

        (address collateral, address userToLiquidate, ISwapper swapper, bytes memory swapData) = abi.decode(params, (address, address, ISwapper, bytes));

        //liquidate unhealthy loan
        liquidateLoan(collateral, assets[0], userToLiquidate, amounts[0], false);

        //swap collateral from liquidate back to asset from flashloan to pay it off
        if (assets[0] == USDC) {
            swapper.swap(collateral, swapData);
        } else {
            (ISwapper swapper2, bytes memory swapData1, bytes memory swapData2) = abi.decode(swapData, (ISwapper, bytes, bytes));
            swapper.swap(collateral, swapData1);
            swapper2.swap(USDC, swapData2);
        }

        }

        {
        //Pay to owner the balance after fees
        uint256 profit = calcProfits(IERC20(assets[0]).balanceOf(address(this)),amounts[0],premiums[0]);

        require(profit > 0 , "No profit");
        IERC20(assets[0]).transfer(owner(), profit);
        }


        // Approve the LendingPool contract allowance to *pull* the owed amount
        // i.e. AAVE V2's way of repaying the flash loan
            uint amountOwing = amounts[0].add(premiums[0]);
            IERC20(assets[0]).approve(address(_lendingPool), amountOwing);

        return true;
    }

    //calculate profits after paying back loan & fees
    function calcProfits(uint256 _balance, uint256 _loanAmount, uint256 _loanFee)
        pure
        private
        returns(uint256)
    {
        return _balance.sub(_loanAmount.add(_loanFee),"no profits to return");
    }

    function liquidateLoan(address _collateral, address _liquidate_asset, address _userToLiquidate, uint256 _amount, bool _receiveaToken) public {

        require(IERC20(_liquidate_asset).approve(address(_lendingPool), _amount), "Approval error");

        _lendingPool.liquidationCall(_collateral,_liquidate_asset, _userToLiquidate, _amount, _receiveaToken);
    }


    /*
    * This function is manually called to commence the flash loans sequence
    * to make executing a liquidation  flexible calculations are done outside of the contract and sent via parameters here
    * _assetToLiquidate - the token address of the asset that will be liquidated
    * _flashAmt - flash loan amount (number of tokens) which is exactly the amount that will be liquidated
    * _collateral - the token address of the collateral. This is the token that will be received after liquidating loans
    * _userToLiquidate - user ID of the loan that will be liquidated
    * _amountOutMin - when using uniswap this is used to make sure the swap returns a minimum number of tokens, or will revert
    * _swapPath - the path that uniswap will use to swap tokens back to original tokens

    */
    function executeFlashLoans(address _assetToLiquidate, uint256 _flashAmt, address _collateral, address _userToLiquidate, bytes calldata _swapData) public {
        address receiverAddress = address(this);

        // the various assets to be flashed
        address[] memory assets = new address[](1);
        assets[0] = _assetToLiquidate;

        // the amount to be flashed for each asset
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashAmt;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        //only for testing. must remove

        // passing these params to executeOperation so that they can be used to liquidate the loan and perform the swap
        bytes memory params = abi.encode(_collateral, _userToLiquidate, _swapData);
        uint16 referralCode = 0;

        _lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

}