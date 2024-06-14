// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

library Address {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0, "Address: low-level call failed");
  }

  function functionCall(
      address target,
      bytes memory data,
      string memory errorMessage
  ) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
      address target,
      bytes memory data,
      uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    if (returndata.length > 0) {
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

interface IERC20Permit {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  function nonces(address owner) external view returns (uint256);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor () {
    _status = _NOT_ENTERED;
  }
  
  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}

interface ISportsAMM {
  enum Position {
    Home,
    Away,
    Draw
  }

  function sUSD() external view returns (address);

  function buyFromAMM(
    address market,
    Position position,
    uint amount,
    uint expectedPayout,
    uint additionalSlippage
  ) external;

  function buyFromAMMWithEthAndReferrer(
    address market,
    Position position,
    uint amount,
    uint expectedPayout,
    uint additionalSlippage,
    address collateral,
    address _referrer
  ) external payable;

  function buyFromAMMWithDifferentCollateral(
    address market,
    Position position,
    uint amount,
    uint expectedPayout,
    uint additionalSlippage,
    address collateral
  ) external;

}

interface IParlayMarketsAMM {
  function sUSD() external view returns (address);

  function buyFromParlay(
    address[] calldata _sportMarkets,
    uint[] calldata _positions,
    uint _sUSDPaid,
    uint _additionalSlippage,
    uint _expectedPayout,
    address _differentRecipient
  ) external;

  function buyFromParlayWithDifferentCollateralAndReferrer(
    address[] calldata _sportMarkets,
    uint[] calldata _positions,
    uint _sUSDPaid,
    uint _additionalSlippage,
    uint _expectedPayout,
    address collateral,
    address _referrer
  ) external;

  function buyFromParlayWithEth(
    address[] calldata _sportMarkets,
    uint[] calldata _positions,
    uint _sUSDPaid,
    uint _additionalSlippage,
    uint _expectedPayout,
    address collateral,
    address _referrer
  ) external payable;

  function exerciseParlay(address _parlayMarket) external;
}

interface ISportPositionalMarketMaster {
  function exerciseOptions() external;
  function result() external view returns (uint256);
}

interface IParlayMarketMaster {
  struct SportMarkets {
    address sportAddress;
    uint position;
    uint odd;
    uint result;
    bool resolved;
    bool exercised;
    bool hasWon;
    bool isCancelled;
  }
  
  function numOfSportMarkets() external returns (uint256);
  function sportMarket(uint256) external returns (SportMarkets memory);
}

contract PaalBet is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  address public SportsAMM;
  address public ParlayMarketsAMM;
  address public sUsd;

  uint256 public treasuryFee = 10_0000_0000_0000_0000_00;
  uint256 public coreDecimal = 100_0000_0000_0000_0000_00;
  address public treasury;

  struct MarketInfo {
    mapping(bytes => uint256) tvl;
    uint256 reward;
    bool claimed;
  }
  struct UserInfo {
    mapping(bytes => uint256) tvl;
    bool claimed;
  }
  mapping (bytes => MarketInfo) public marketInfo;
  mapping (address => mapping(bytes => UserInfo)) public userMarketInfo;

  event PlaceBet(address account, bytes key, uint256 amount, uint256 marketTvl, uint256 userTvl);
  event TreasuryFee(address token, uint256 fee, address treasury);
  event Claim(address account, bytes key, address token, uint256 amount);

  constructor (address _SportsAMM, address _ParlayMarketsAMM, address _treasury) {
    SportsAMM = _SportsAMM;
    ParlayMarketsAMM = _ParlayMarketsAMM;
    treasury = _treasury;
    require(ISportsAMM(SportsAMM).sUSD() == IParlayMarketsAMM(ParlayMarketsAMM).sUSD(), "Wrong AMM");
    sUsd = ISportsAMM(SportsAMM).sUSD();
  }

  function _registerBetInfo (address[] memory markets, uint256[] memory positions, uint256 amount) internal {
    bytes memory key = _addressArrayToBytes(markets);
    bytes memory pos = _uint256ArrayToBytes(positions);
    marketInfo[key].tvl[pos] += amount;
    userMarketInfo[msg.sender][key].tvl[pos] += amount;
    emit PlaceBet(msg.sender, key, amount, marketInfo[key].tvl[pos], userMarketInfo[msg.sender][key].tvl[pos]);
  }

  function buyFromAMM (
    address market,
    ISportsAMM.Position position,
    uint amount,
    uint expectedPayout,
    uint additionalSlippage
  ) public nonReentrant {
    IERC20(sUsd).safeTransferFrom(msg.sender, address(this), expectedPayout);
    _approveTokenIfNeeded(sUsd, SportsAMM, expectedPayout);
    ISportsAMM(SportsAMM).buyFromAMM(
      market,
      position,
      amount,
      expectedPayout,
      additionalSlippage
    );

    address[] memory tmp = new address[](1);
    uint256[] memory posArr = new uint256[](1);
    tmp[0] = market;
    posArr[0] = uint256(position) + 1;
    _registerBetInfo(tmp, posArr, amount);
  }

  function buyFromParlay(
    address[] calldata _sportMarkets,
    uint[] calldata _positions,
    uint _sUSDPaid,
    uint _additionalSlippage,
    uint _expectedPayout,
    address _differentRecipient
  ) public nonReentrant {
    IERC20(sUsd).safeTransferFrom(msg.sender, address(this), _sUSDPaid);
    _approveTokenIfNeeded(sUsd, SportsAMM, _sUSDPaid);
    IParlayMarketsAMM(ParlayMarketsAMM).buyFromParlay(
      _sportMarkets,
      _positions,
      _sUSDPaid,
      _additionalSlippage,
      _expectedPayout,
      _differentRecipient
    );

    uint256 len = _sportMarkets.length;
    address[] memory tmp = new address[](len);
    uint256[] memory posArr = new uint256[](len);
    for (uint256 x=0; x<len; x++) {
      tmp[x] = _sportMarkets[x];
      posArr[x] = _positions[x] + 1;
    }
    _registerBetInfo(tmp, posArr, _expectedPayout);
  }

  function _exercise(address _market, bool isParlay) internal {
    bytes memory key = "0x";
    bytes memory pos = "0x";
    if (isParlay) {
      uint256 len = IParlayMarketMaster(_market).numOfSportMarkets();
      address[] memory tmp = new address[](len);
      uint256[] memory posArr = new uint256[](len);
      for (uint256 x=0; x<len; x++) {
        IParlayMarketMaster.SportMarkets memory tmpMarket = IParlayMarketMaster(_market).sportMarket(x);
        tmp[x] = tmpMarket.sportAddress;
        posArr[x] = ISportPositionalMarketMaster(tmpMarket.sportAddress).result();
      }
      key = _addressArrayToBytes(tmp);
      pos = _uint256ArrayToBytes(posArr);
    }
    else {
      address[] memory tmp = new address[](1);
      uint256[] memory posArr = new uint256[](1);
      tmp[0] = _market;
      key = _addressArrayToBytes(tmp);
      posArr[0] = ISportPositionalMarketMaster(_market).result();
      pos = _uint256ArrayToBytes(posArr);
    }
    if (marketInfo[key].claimed == false) {
      uint256 amount = IERC20(sUsd).balanceOf(address(this));
      if (isParlay) {
        IParlayMarketsAMM(ParlayMarketsAMM).exerciseParlay(_market);
      }
      else {
        ISportPositionalMarketMaster(_market).exerciseOptions();
      }
      amount = IERC20(sUsd).balanceOf(address(this)) - amount;
      amount = _cutFee(sUsd, amount);
      marketInfo[key].reward = amount;
      marketInfo[key].claimed = true;
    }
    if (marketInfo[key].reward > 0 && userMarketInfo[msg.sender][key].claimed == false && marketInfo[key].tvl[pos] > 0) {
      uint256 amount = marketInfo[key].reward * userMarketInfo[msg.sender][key].tvl[pos] / marketInfo[key].tvl[pos];
      if (amount > 0) {
        IERC20(sUsd).safeTransfer(msg.sender, amount);
      }
      userMarketInfo[msg.sender][key].claimed = true;
      emit Claim(msg.sender, key, sUsd, amount);
    }
  }

  function exerciseOptions(address _market) public nonReentrant {
    _exercise(_market, false);
  }

  function exerciseParlay(address _market) public nonReentrant {
    _exercise(_market, true);
  }

  function _approveTokenIfNeeded(address token, address spender, uint256 amount) private {
    if (token != address(0)) {
      uint256 oldAllowance = IERC20(token).allowance(address(this), spender);
      if (oldAllowance < amount) {
        if (oldAllowance > 0) {
          IERC20(token).safeApprove(spender, 0);
        }
        IERC20(token).safeApprove(spender, amount);
      }
    }
  }

  function _addressArrayToBytes(address[] memory addresses) public pure returns (bytes memory) {
    bytes memory byteArray = new bytes(addresses.length * 20);
    uint256 byteIndex = 0;

    for (uint256 i = 0; i < addresses.length; i++) {
      address addr = addresses[i];
      for (uint256 j = 0; j < 20; j++) {
        byteArray[byteIndex] = bytes1(uint8(uint160(addr) >> (8 * (19 - j))));
        byteIndex++;
      }
    }

    return byteArray;
  }

  function _uint256ArrayToBytes(uint256[] memory uintArray) public pure returns (bytes memory) {
    bytes memory byteArray = new bytes(uintArray.length * 32);
    uint256 byteIndex = 0;

    for (uint256 i = 0; i < uintArray.length; i++) {
      uint256 value = uintArray[i];
      for (uint256 j = 0; j < 32; j++) {
        byteArray[byteIndex] = bytes1(uint8(value >> (8 * (31 - j))));
        byteIndex++;
      }
    }

    return byteArray;
  }

  function _cutFee(address _token, uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * treasuryFee / coreDecimal;
      if (fee > 0) {
        if (_token == address(0)) {
          (bool success, ) = payable(treasury).call{value: fee}("");
          require(success, "Failed cut fee");
        }
        else {
          IERC20(_token).safeTransfer(treasury, fee);
        }
        emit TreasuryFee(_token, fee, treasury);
      }
      return _amount - fee;
    }
    return 0;
  }
}