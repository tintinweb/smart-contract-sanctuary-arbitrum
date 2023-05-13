/**
 *Submitted for verification at Arbiscan on 2023-05-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;


contract DummyComet {
    address constant public WETH_GOERLI = 0x7F5bc2250ea57d8ca932898297b1FF9aE1a04999;
    address constant public testUser1 = 0x5c200abb1add04712A18654e94b44A2a246242A2;
    address constant public testUser2 = 0x4Bf49872A87328e4a8edEe4E88B88784dFffCde0;
    string[] public reasons = ["meow"];
    bytes[] public byteArr = [bytes("meowmeow")];
    address public owner;
    constructor () {
        owner = msg.sender;

    }

    function emitAbsorbCollateral() external onlyOwner {
        emit AbsorbCollateral(testUser1, testUser2, WETH_GOERLI, 100, 110);
    }
    function emitAbsorbDebt() external onlyOwner {
        emit AbsorbDebt(testUser1, testUser2, 120, 150);
    }
    function emitSupply() external onlyOwner {
        emit Supply(testUser1, testUser2, 230);
    }
    function emitSupplyCollateral() external onlyOwner {
        emit SupplyCollateral(testUser1, testUser2, WETH_GOERLI, 20);
    }
    function emitBuyCollateral() external onlyOwner {
        emit BuyCollateral(testUser1, WETH_GOERLI, 20, 50);
    }
    function emitTransfer() external onlyOwner {
        emit Transfer(testUser1, testUser2, 75);
    }
    function emitTransferCollateral() external onlyOwner {
        emit TransferCollateral(testUser1, testUser2, WETH_GOERLI, 2500);
    }
    function emitWithdraw() external onlyOwner {
        emit Withdraw(testUser2, testUser1, 300);
    }
    function emitWithdrawCollateral() external onlyOwner {
        emit WithdrawCollateral(testUser2, testUser1, WETH_GOERLI, 500);
    }
    function emitWithdrawReserves() external onlyOwner {
        emit WithdrawReserves(testUser1, 1000);
    }


    // function emitCustomAbsorbCollateral(address absorber, address borrower, address asset, uint collateralAbsorbed, uint usdValue) external onlyOwner {
    //     emit AbsorbCollateral();
    // }
    // function emitCustomAbsorbDebt(address absorber, address borrower, uint basePaidOut, uint usdValue) external onlyOwner {
    //     emit AbsorbDebt();
    // }
    // function emitCustomSupply(address from, address dst, uint amount) external onlyOwner {
    //     emit Supply();
    // }
    // function emitCustomSupplyCollateral(address from, address dst, address asset, uint amount) external onlyOwner {
    //     emit SupplyCollateral();
    // }
    // function emitCustomBuyCollateral(address buyer, address asset, uint baseAmount, uint collateralAmount) external onlyOwner {
    //     emit BuyCollateral();
    // }
    // function emitCustomTransfer(address from, address to, uint amount) external onlyOwner {
    //     emit Transfer();
    // }
    // function emitCustomTransferCollateral(address from, address to, address asset, uint amount) external onlyOwner {
    //     emit TransferCollateral();
    // }
    // function emitCustomWithdraw(address src, address to, uint amount) external onlyOwner {
    //     emit Withdraw();
    // }
    // function emitCustomWithdrawCollateral(address src, address to, address asset, uint amount) external onlyOwner {
    //     emit WithdrawCollateral();
    // }
    // function emitCustomWithdrawReserves(address to, uint amount) external onlyOwner {
    //     emit WithdrawReserves();
    // }


    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

   


    /// @notice Event emitted when a user's collateral is absorbed by the protocol
    event AbsorbCollateral(address indexed absorber, address indexed borrower, address indexed asset, uint collateralAbsorbed, uint usdValue);
    /// @notice Event emitted when a borrow position is absorbed by the protocol
    event AbsorbDebt(address indexed absorber, address indexed borrower, uint basePaidOut, uint usdValue);
    event Supply(address indexed from, address indexed dst, uint amount);
    event SupplyCollateral(address indexed from, address indexed dst, address indexed asset, uint amount);
    /// @notice Event emitted when a collateral asset is purchased from the protocol
    event BuyCollateral(address indexed buyer, address indexed asset, uint baseAmount, uint collateralAmount);
    event Transfer(address indexed from, address indexed to, uint amount);
    event TransferCollateral(address indexed from, address indexed to, address indexed asset, uint amount);
    event Withdraw(address indexed src, address indexed to, uint amount);
    event WithdrawCollateral(address indexed src, address indexed to, address indexed asset, uint amount);
    /// @notice Event emitted when reserves are withdrawn by the governor
    event WithdrawReserves(address indexed to, uint amount);
 
    error OnlyOwner();


}