pragma solidity ^0.8.16;

interface ISocketEthContract {
    function depositToAppChain(address receiver_, uint256 amount_, uint256 msgGasLimit_, address connector_)
        external
        payable;
}

interface IWETH {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;
    function approve(address guy, uint256 wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint256);
}

/// @title A thin helper to auto-wrap eth for depositing into the Hook Deposit Helper
/// @author Jake Nyquist - [email protected]
/// @notice This contract wraps eth and deposits it into the Hook appchain via Socket.
/// @dev Contract has after-deposit validation to ensure that no eth is lost.
contract HookDepositHelper {
    address public immutable weth;
    address public immutable socketEthContract;

    constructor(address _weth, address _socketEthContract) {
        weth = _weth;
        socketEthContract = _socketEthContract;
    }

    /// @notice Deposit eth to the Hook appchain via the SocketEthContract
    /// @param receiver The address to receive the deposit on the appchain
    /// @param amount The amount of eth to deposit
    /// @param msgGasLimit_ The gas limit for the message call on the receiving chain
    /// @param connector_ The address of the socket connector to process the deposit
    function depositEthToAppChain(address receiver, uint256 amount, uint256 msgGasLimit_, address connector_)
        external
        payable
    {
        require(msg.value > amount, "HookDepositHelper: INSUFFICIENT_MSGVALUE");
        uint256 depositFee = msg.value - amount;

        // Wrap eth and approve the exact amount to be deposited
        IWETH(weth).deposit{value: amount}();
        IWETH(weth).approve(socketEthContract, amount);

        ISocketEthContract(socketEthContract).depositToAppChain{value: depositFee}(
            receiver, amount, msgGasLimit_, connector_
        );

        require(IWETH(weth).balanceOf(address(this)) == 0, "HookDepositHelper: WETH_BALANCE_NOT_ZERO");
        require(address(this).balance == 0, "HookDepositHelper: ETH_BALANCE_NOT_ZERO");
    }
}