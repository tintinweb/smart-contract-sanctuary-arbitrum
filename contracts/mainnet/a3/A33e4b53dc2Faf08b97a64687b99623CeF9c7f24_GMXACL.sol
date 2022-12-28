/**
 *Submitted for verification at Arbiscan on 2022-12-28
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

// GMX All-in-one ACL, for:
// GMX_ROUTER = "0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064"
// GMX_POSITION_ROUTER = "0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868"
// GMX_REWARD_ROUTER = "0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1"
contract GMXACL {
    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole = hex"01";
    uint256 private _checkedValue = 1;

    // ACL

    // Allow trading tokens (both send and receive).
    mapping(address => mapping(address => bool)) public traderWhiteList;
    address public weth;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule != address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
    }

    // modifiers
    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    modifier onlySafe() {
        require(safeAddress == msg.sender, "Caller is not the safe");
        _;
    }

    //events
    event SetTraderToken(address, address, bool);
    event SetWETH(address);

    // Internal functions.

    function _checkInTraderWhiteList(address _trader, address _token)
        private
        view
    {
        require(
            traderWhiteList[_trader][_token] == true,
            "Token not in white list"
        );
    }

    function _callSelf(
        bytes32 _role,
        uint256 _value,
        bytes calldata data
    ) private returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success, ) = address(this).staticcall(data);
        _checkedRole = hex"01"; // gas refund.
        _checkedValue = 1;
        return success;
    }

    // External functions.

    function check(
        bytes32 _role,
        uint256 _value,
        bytes calldata data
    ) external onlyModule returns (bool) {
        bool success = _callSelf(_role, _value, data);
        return success;
    }

    // ACL setting functions.
    // `onlySafe` needed.
    function setTraderAllowedToken(
        address _trader,
        address _token,
        bool _status
    ) external onlySafe {
        traderWhiteList[_trader][_token] = _status;
        emit SetTraderToken(_trader, _token, _status);
    }

    function setWETH(address _weth) external onlySafe {
        weth = _weth;
        emit SetWETH(_weth);
    }

    // ACL restricted functions
    // `onlySelf` needed.

    // GMX_ROUTER = "0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064"

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external view onlySelf {
        address trader = tx.origin;
        address srcToken = _path[0];
        address dstToken = _path[_path.length - 1];
        _minOut;
        _amountIn;
        require(_receiver == safeAddress, "Receiver Not Safe Address");
        _checkInTraderWhiteList(trader, srcToken);
        _checkInTraderWhiteList(trader, dstToken);
    }

    function swapTokensToETH(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address payable _receiver
    ) external view onlySelf {
        _minOut;
        _amountIn;
        address trader = tx.origin;
        address srcToken = _path[0];
        address dstToken = _path[_path.length - 1];
        require(_receiver == safeAddress, "Receiver Not Safe Address");
        _checkInTraderWhiteList(trader, srcToken);
        _checkInTraderWhiteList(trader, dstToken);
    }

    function swapETHToTokens(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) external view onlySelf {
        _minOut;
        address trader = tx.origin;
        address srcToken = _path[0];
        address dstToken = _path[_path.length - 1];
        require(_receiver == safeAddress, "Receiver Not Safe Address");
        _checkInTraderWhiteList(trader, srcToken);
        _checkInTraderWhiteList(trader, dstToken);
    }

    // GMX_POSITION_ROUTER = "0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868"
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external view onlySelf {
        address trader = tx.origin;
        address srcToken = _path[0];
        require(_callbackTarget == address(0), "Not allow callback");
        require(_path.length == 1, "Not allow swap when createPosition");
        _checkInTraderWhiteList(trader, srcToken);
        _checkInTraderWhiteList(trader, _indexToken);
    }

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external view onlySelf {
        address trader = tx.origin;
        require(_path.length == 1, "Not allow swap when createPosition");
        require(_callbackTarget == address(0), "Not allow callback");
        address srcToken = _path[0];
        _checkInTraderWhiteList(trader, srcToken);
        _checkInTraderWhiteList(trader, _indexToken);
    }

    //TODO A callback function must be call to determine how much token is back to gnosis safe
    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external view onlySelf {
        address trader = tx.origin;
        address srcToken = _path[0];
        require(_path.length == 1, "Not allow swap when decreasePosition");
        require(_receiver == safeAddress, "Receiver Not Safe Address");
        require(_callbackTarget == address(0), "Not allow callback");
        _checkInTraderWhiteList(trader, srcToken);
        _checkInTraderWhiteList(trader, _indexToken);
    }

    // GMX_REWARD_ROUTER = "0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1"
    function stakeGmx(uint256 _amount) external view onlySelf {}

    function stakeEsGmx(uint256 _amount) external view onlySelf {}

    function unstakeGmx(uint256 _amount) external view onlySelf {}

    function unstakeEsGmx(uint256 _amount) external view onlySelf {}

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external view onlySelf {}

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external view onlySelf {
        address trader = tx.origin;
        _checkInTraderWhiteList(trader, _token);
    }

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp)
        external
        view
        onlySelf
    {
        _minUsdg;
        _minGlp;
        address trader = tx.origin;
        _checkInTraderWhiteList(trader, weth);
    }

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external view onlySelf {
        _glpAmount;
        _minOut;
        address trader = tx.origin;
        require(_receiver == safeAddress, "Receiver not safeAddress");
        _checkInTraderWhiteList(trader, _tokenOut);
    }

    // TODO A callback function should be call to determine how much ETH is back to gnosis safe
    function unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external view onlySelf {
        _glpAmount;
        _minOut;
        address trader = tx.origin;
        require(_receiver == safeAddress, "Receiver not safeAddress");
        _checkInTraderWhiteList(trader, weth);
    }

    // GMX ORDER BOOK
    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external view onlySelf {
        address trader = tx.origin;
        address srcToken = _path[0];
        address dstToken = _path[_path.length - 1];
        _checkInTraderWhiteList(trader, srcToken);
        _checkInTraderWhiteList(trader, dstToken);
    }

    function updateSwapOrder(
        uint256 _orderIndex,
        uint256 _minOut,
        uint256 _triggerRatio,
        bool _triggerAboveThreshold
    ) external view onlySelf {}

    function cancelSwapOrder(uint256 _orderIndex) external view onlySelf {}

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external view onlySelf {
        address trader = tx.origin;
        address srcToken = _path[0];
        require(_path.length == 1, "Not allow swap when create Increase order");
        _checkInTraderWhiteList(trader, srcToken);
        _checkInTraderWhiteList(trader, _collateralToken);
        _checkInTraderWhiteList(trader, _indexToken);
    }

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external view onlySelf {}

    function cancelIncreaseOrder(uint256 _orderIndex) external view onlySelf {}

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external view onlySelf {
        address trader = tx.origin;
        _checkInTraderWhiteList(trader, _indexToken);
        _checkInTraderWhiteList(trader, _collateralToken);
    }

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external onlySelf {}

    function cancelDecreaseOrder(uint256 _orderIndex) external onlySelf {}

    function approvePlugin(address) external onlySelf {}
}