// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.20;

interface ICurve {
  function curveMath(uint256 base, uint256 add) external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.20;

interface IFoundry {
  struct App {
    string name;
    address owner;
    address operator;
    address publicNFT;
    address mortgageNFT;
    address market;
  }

  event CreateApp(
    uint256 appId,
    string name,
    address owner,
    address operator,
    address curve,
    uint256 buySellFee,
    address publicNFT,
    address mortgageNFT,
    address market,
    address sender
  );

  event CreateToken(
    uint256 appId,
    string tid,
    bytes tData,
    uint256[] nftTokenIds,
    uint256[] nftPercents,
    address[] nftOwners,
    bytes[] nftData,
    address sender
  );

  event SetAppOwner(uint256 appId, address newOwner, address sender);

  event SetAppOperator(uint256 appId, address newOperator, address sender);

  event SetMortgageFee(uint256 appId, uint256 newMortgageFee, address sender);

  event SetMortgageFeeRecipient(uint256 appId, address newMortgageFeeOwner, address sender);

  function FEE_DENOMINATOR() external view returns (uint256);

  function TOTAL_PERCENT() external view returns (uint256);

  function publicNFTFactory() external view returns (address);

  function mortgageNFTFactory() external view returns (address);

  function marketFactory() external view returns (address);

  function nextAppId() external view returns (uint256);

  function defaultMortgageFee() external view returns (uint256);

  function defaultMortgageFeeRecipient() external view returns (address);

  function mortgageFee(uint256 appId) external view returns (uint256);

  function mortgageFeeRecipient(uint256 appId) external view returns (address);

  function apps(uint256 appId) external view returns (App memory app);

  function tokenExist(uint256 appId, string memory tid) external view returns (bool);

  function tokenData(uint256 appId, string memory tid) external view returns (bytes memory);

  function createApp(string memory name, address owner, address operator, address curve, uint256 buySellFee) external;

  function createToken(
    uint256 appId,
    string memory tid,
    bytes memory tData,
    uint256[] memory nftPercents,
    address[] memory nftOwners,
    bytes[] memory nftData
  ) external returns (uint256[] memory tokenIds);

  function setAppOwner(uint256 appId, address newOwner) external;

  function setAppOperator(uint256 appId, address newOperator) external;

  function setMortgageFee(uint256 appId, uint256 newMortgageFee) external;

  function setMortgageFeeRecipient(uint256 appId, address newMortgageFeeRecipient) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.20;

interface IMarket {
  event Initialize(address publicNFT, address mortgageNFT);

  event Buy(
    string tid,
    uint256 tokenAmount,
    uint256 ethAmount,
    address buyer,
    uint256[] feeTokenIds,
    address[] feeOwners,
    uint256[] feeAmounts
  );

  event Sell(
    string tid,
    uint256 tokenAmount,
    uint256 ethAmount,
    address seller,
    uint256[] feeTokenIds,
    address[] feeOwners,
    uint256[] feeAmounts
  );

  event Mortgage(
    uint256 tokenId,
    string tid,
    uint256 tokenAmount,
    uint256 ethAmount,
    uint256 feeAmount,
    address sender
  );

  event Redeem(uint256 tokenId, string tid, uint256 tokenAmount, uint256 ethAmount, address sender);

  event Multiply(
    uint256 tokenId,
    string tid,
    uint256 multiplyAmount,
    uint256 ethAmount,
    uint256 feeAmount,
    address sender,
    uint256[] feeTokenIds,
    address[] feeOwners,
    uint256[] feeAmounts
  );

  event Cash(
    uint256 tokenId,
    string tid,
    uint256 tokenAmount,
    uint256 ethAmount,
    address sender,
    uint256[] feeTokenIds,
    address[] feeOwners,
    uint256[] feeAmounts
  );

  event Merge(uint256 tokenId, string tid, uint256 otherTokenId, uint256 ethAmount, uint256 feeAmount, address sender);

  event Split(uint256 tokenId, uint256 newTokenId, string tid, uint256 splitAmount, uint256 ethAmount, address sender);

  function feeDenominator() external view returns (uint256);

  function totalPercent() external view returns (uint256);

  function foundry() external view returns (address);

  function appId() external view returns (uint256);

  function curve() external view returns (address);

  function buySellFee() external view returns (uint256);

  function publicNFT() external view returns (address);

  function mortgageNFT() external view returns (address);

  function initialize(address publicNFT, address mortgageNFT) external;

  function totalSupply(string memory tid) external view returns (uint256);

  function balanceOf(string memory tid, address account) external view returns (uint256);

  function getBuyETHAmount(string memory tid, uint256 tokenAmount) external view returns (uint256 ethAmount);

  function getSellETHAmount(string memory tid, uint256 tokenAmount) external view returns (uint256 ethAmount);

  function getETHAmount(uint256 base, uint256 add) external view returns (uint256 ethAmount);

  function buy(string memory tid, uint256 tokenAmount) external payable returns (uint256 ethAmount);

  function sell(string memory tid, uint256 tokenAmount) external returns (uint256 ethAmount);

  function mortgage(string memory tid, uint256 tokenAmount) external returns (uint256 nftTokenId, uint256 ethAmount);

  function mortgageAdd(uint256 nftTokenId, uint256 tokenAmount) external returns (uint256 ethAmount);

  function redeem(uint256 nftTokenId, uint256 tokenAmount) external payable returns (uint256 ethAmount);

  function multiply(
    string memory tid,
    uint256 multiplyAmount
  ) external payable returns (uint256 nftTokenId, uint256 ethAmount);

  function multiplyAdd(uint256 nftTokenId, uint256 multiplyAmount) external payable returns (uint256 ethAmount);

  function cash(uint256 nftTokenId, uint256 tokenAmount) external returns (uint256 ethAmount);

  function merge(uint256 nftTokenId, uint256 otherNFTTokenId) external returns (uint256 ethAmount);

  function split(
    uint256 nftTokenId,
    uint256 splitAmount
  ) external payable returns (uint256 ethAmount, uint256 newNFTTokenId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.20;

interface IMortgageNFT {
  struct Info {
    string tid;
    uint256 amount;
  }

  event Initialize(address market);

  event Mint(address to, string tid, uint256 amount);

  event Burn(uint256 tokenId);

  event Add(uint256 tokenId, uint256 amount);

  event Remove(uint256 tokenId, uint256 amount);

  event SetMortgageNFTView(address newMortgageNFTView, address sender);

  function foundry() external view returns (address);

  function appId() external view returns (uint256);

  function market() external view returns (address);

  function mortgageNFTView() external view returns (address);

  function info(uint256 tokenId) external view returns (string memory tid, uint256 amount);

  function initialize(address market) external;

  function isApprovedOrOwner(address addr, uint256 tokenId) external view returns (bool);

  function mint(address to, string memory tid, uint256 amount) external returns (uint256 tokenId);

  function burn(uint256 tokenId) external;

  function add(uint256 tokenId, uint256 amount) external;

  function remove(uint256 tokenId, uint256 amount) external;

  function setMortgageNFTView(address newMortgageNFTView) external;

  function tokenInfosOfOwner(address owner) external view returns (IMortgageNFT.Info[] memory infos);

  function tokenInfosOfOwnerByTid(
    address owner,
    string memory tid
  ) external view returns (IMortgageNFT.Info[] memory infos);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.20;

interface IPublicNFT {
  struct Info {
    string tid;
    uint256 percent;
    bytes data;
  }

  event Mint(string tid, uint256[] tokenIds, uint256[] percents, address[] owners, bytes[] data);

  event SetPublicNFTView(address newPublicNFTView, address sender);

  function foundry() external view returns (address);

  function appId() external view returns (uint256);

  function publicNFTView() external view returns (address);

  function tokenIdToInfo(
    uint256 tokenId
  ) external view returns (string memory tid, uint256 percent, bytes memory data, address owner);

  function tidToTokenIds(string memory tid) external view returns (uint256[] memory);

  function tidToInfos(
    string memory tid
  )
    external
    view
    returns (uint256[] memory tokenIds, uint256[] memory percents, bytes[] memory data, address[] memory owners);

  function mint(
    string memory tid,
    uint256[] memory percents,
    address[] memory owners,
    bytes[] memory data
  ) external returns (uint256[] memory tokenIds);

  function setPublicNFTView(address newPublicNFTView) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import "./interfaces/IPublicNFT.sol";
import "./interfaces/IMortgageNFT.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IFoundry.sol";
import "./interfaces/ICurve.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Market is IMarket, ReentrancyGuard {
  uint256 public immutable override feeDenominator;
  uint256 public immutable override totalPercent;

  address public immutable override foundry;
  uint256 public immutable override appId;

  address public immutable override curve;
  uint256 public immutable override buySellFee;

  address public override publicNFT;
  address public override mortgageNFT;

  // tid => totalSupply
  mapping(string => uint256) private _totalSupply;

  // tid => account => amount
  mapping(string => mapping(address => uint256)) private _balanceOf;

  constructor(
    address _foundry,
    uint256 _appId,
    uint256 _feeDenominator,
    uint256 _totalPercent,
    address _curve,
    uint256 _buySellFee
  ) {
    foundry = _foundry;
    appId = _appId;

    feeDenominator = _feeDenominator;
    totalPercent = _totalPercent;

    curve = _curve;
    buySellFee = _buySellFee;
  }

  function initialize(address _publicNFT, address _mortgageNFT) external override {
    require(msg.sender == foundry, "onlyFoundry");

    publicNFT = _publicNFT;
    mortgageNFT = _mortgageNFT;

    emit Initialize(_publicNFT, _mortgageNFT);
  }

  function totalSupply(string memory tid) external view override returns (uint256) {
    return _totalSupply[tid];
  }

  function balanceOf(string memory tid, address account) external view override returns (uint256) {
    return _balanceOf[tid][account];
  }

  function getBuyETHAmount(string memory tid, uint256 tokenAmount) public view override returns (uint256 ethAmount) {
    uint256 ts = _totalSupply[tid];
    return getETHAmount(ts, tokenAmount);
  }

  function getSellETHAmount(string memory tid, uint256 tokenAmount) public view override returns (uint256 ethAmount) {
    uint256 ts = _totalSupply[tid];
    return getETHAmount(ts - tokenAmount, tokenAmount);
  }

  function getETHAmount(uint256 base, uint256 add) public view override returns (uint256 ethAmount) {
    return ICurve(curve).curveMath(base, add);
  }

  function buy(
    string memory tid,
    uint256 tokenAmount
  ) external payable override nonReentrant returns (uint256 ethAmount) {
    require(IFoundry(foundry).tokenExist(appId, tid), "TE");

    require(tokenAmount > 0, "TAE");

    uint256[] memory feeTokenIds;
    address[] memory feeTos;
    uint256[] memory feeAmounts;

    (ethAmount, feeTokenIds, feeTos, feeAmounts) = _buyWithoutTransferEth(msg.sender, tid, tokenAmount);

    require(msg.value >= ethAmount, "VE");
    _batchTransferEthToNFTOwners(feeTokenIds, feeTos, feeAmounts);
    _refundETH(ethAmount);

    emit Buy(tid, tokenAmount, ethAmount, msg.sender, feeTokenIds, feeTos, feeAmounts);
  }

  function sell(string memory tid, uint256 tokenAmount) external override nonReentrant returns (uint256 ethAmount) {
    require(IFoundry(foundry).tokenExist(appId, tid), "TE");

    require(tokenAmount > 0, "TAE");
    require(tokenAmount <= _balanceOf[tid][msg.sender], "TAE");

    uint256[] memory feeTokenIds;
    address[] memory feeTos;
    uint256[] memory feeAmounts;

    (ethAmount, feeTokenIds, feeTos, feeAmounts) = _sellWithoutTransferEth(msg.sender, tid, tokenAmount);

    _transferEth(msg.sender, ethAmount);
    _batchTransferEthToNFTOwners(feeTokenIds, feeTos, feeAmounts);

    emit Sell(tid, tokenAmount, ethAmount, msg.sender, feeTokenIds, feeTos, feeAmounts);
  }

  function mortgage(
    string memory tid,
    uint256 tokenAmount
  ) external override nonReentrant returns (uint256 nftTokenId, uint256 ethAmount) {
    require(IFoundry(foundry).tokenExist(appId, tid), "TE");
    require(tokenAmount > 0, "TAE");
    require(tokenAmount <= _balanceOf[tid][msg.sender], "TAE");

    nftTokenId = IMortgageNFT(mortgageNFT).mint(msg.sender, tid, tokenAmount);

    ethAmount = _mortgageAdd(nftTokenId, tid, 0, tokenAmount);
  }

  function mortgageAdd(
    uint256 nftTokenId,
    uint256 tokenAmount
  ) external override nonReentrant returns (uint256 ethAmount) {
    require(IMortgageNFT(mortgageNFT).isApprovedOrOwner(msg.sender, nftTokenId), "AOE");

    (string memory tid, uint256 oldAmount) = IMortgageNFT(mortgageNFT).info(nftTokenId);
    require(tokenAmount > 0, "TAE");
    require(tokenAmount <= _balanceOf[tid][msg.sender], "TAE");

    IMortgageNFT(mortgageNFT).add(nftTokenId, tokenAmount);

    ethAmount = _mortgageAdd(nftTokenId, tid, oldAmount, tokenAmount);
  }

  function redeem(
    uint256 nftTokenId,
    uint256 tokenAmount
  ) external payable override nonReentrant returns (uint256 ethAmount) {
    require(IMortgageNFT(mortgageNFT).isApprovedOrOwner(msg.sender, nftTokenId), "AOE");

    (string memory tid, uint256 oldAmount) = IMortgageNFT(mortgageNFT).info(nftTokenId);
    require(tokenAmount > 0, "TAE");
    require(tokenAmount <= oldAmount, "TAE");

    IMortgageNFT(mortgageNFT).remove(nftTokenId, tokenAmount);

    ethAmount = getETHAmount(oldAmount - tokenAmount, tokenAmount);
    require(msg.value >= ethAmount, "VE");

    _balanceOf[tid][address(this)] -= tokenAmount;
    _balanceOf[tid][msg.sender] += tokenAmount;

    _refundETH(ethAmount);

    emit Redeem(nftTokenId, tid, tokenAmount, ethAmount, msg.sender);
  }

  function multiply(
    string memory tid,
    uint256 multiplyAmount
  ) external payable override nonReentrant returns (uint256 nftTokenId, uint256 ethAmount) {
    require(IFoundry(foundry).tokenExist(appId, tid), "TE");
    require(multiplyAmount > 0, "TAE");

    nftTokenId = IMortgageNFT(mortgageNFT).mint(msg.sender, tid, multiplyAmount);

    ethAmount = _multiplyAdd(nftTokenId, tid, 0, multiplyAmount);
  }

  function multiplyAdd(
    uint256 nftTokenId,
    uint256 multiplyAmount
  ) external payable override nonReentrant returns (uint256 ethAmount) {
    require(IMortgageNFT(mortgageNFT).isApprovedOrOwner(msg.sender, nftTokenId), "AOE");
    require(multiplyAmount > 0, "TAE");

    (string memory tid, uint256 oldAmount) = IMortgageNFT(mortgageNFT).info(nftTokenId);
    IMortgageNFT(mortgageNFT).add(nftTokenId, multiplyAmount);

    ethAmount = _multiplyAdd(nftTokenId, tid, oldAmount, multiplyAmount);
  }

  function cash(uint256 nftTokenId, uint256 tokenAmount) external override nonReentrant returns (uint256 ethAmount) {
    require(IMortgageNFT(mortgageNFT).isApprovedOrOwner(msg.sender, nftTokenId), "AOE");

    (string memory tid, uint256 oldAmount) = IMortgageNFT(mortgageNFT).info(nftTokenId);
    require(tokenAmount > 0, "TAE");
    require(tokenAmount <= oldAmount, "TAE");

    IMortgageNFT(mortgageNFT).remove(nftTokenId, tokenAmount);

    (
      uint256 sellAmount,
      uint256[] memory feeTokenIds,
      address[] memory feeTos,
      uint256[] memory feeAmounts
    ) = _sellWithoutTransferEth(address(this), tid, tokenAmount);

    uint256 redeemEth = getETHAmount(oldAmount - tokenAmount, tokenAmount);

    require(sellAmount >= redeemEth, "CE");
    ethAmount = sellAmount - redeemEth;

    if (ethAmount > 0) {
      _transferEth(msg.sender, ethAmount);
    }

    _batchTransferEthToNFTOwners(feeTokenIds, feeTos, feeAmounts);

    emit Cash(nftTokenId, tid, tokenAmount, ethAmount, msg.sender, feeTokenIds, feeTos, feeAmounts);
  }

  function merge(
    uint256 nftTokenId,
    uint256 otherNFTTokenId
  ) external override nonReentrant returns (uint256 ethAmount) {
    require(IMortgageNFT(mortgageNFT).isApprovedOrOwner(msg.sender, nftTokenId), "AOE1");
    require(IMortgageNFT(mortgageNFT).isApprovedOrOwner(msg.sender, otherNFTTokenId), "AOE2");

    (string memory tid, uint256 oldAmount) = IMortgageNFT(mortgageNFT).info(nftTokenId);
    (string memory otherTid, uint256 otherOldAmount) = IMortgageNFT(mortgageNFT).info(otherNFTTokenId);

    require(keccak256(abi.encodePacked(tid)) == keccak256(abi.encodePacked(otherTid)), "TE");

    IMortgageNFT(mortgageNFT).burn(otherNFTTokenId);
    IMortgageNFT(mortgageNFT).add(nftTokenId, otherOldAmount);

    uint256 eth = getETHAmount(oldAmount, otherOldAmount) - getETHAmount(0, otherOldAmount);
    uint256 feeAmount = _mortgageFee(eth);
    ethAmount = eth - feeAmount;

    _transferEth(msg.sender, ethAmount);
    _transferEthToMortgageFeeRecipient(feeAmount);

    emit Merge(nftTokenId, tid, otherNFTTokenId, ethAmount, feeAmount, msg.sender);
  }

  function split(
    uint256 nftTokenId,
    uint256 splitAmount
  ) external payable override nonReentrant returns (uint256 ethAmount, uint256 newNFTTokenId) {
    require(IMortgageNFT(mortgageNFT).isApprovedOrOwner(msg.sender, nftTokenId), "AOE");

    (string memory tid, uint256 oldAmount) = IMortgageNFT(mortgageNFT).info(nftTokenId);
    require(splitAmount > 0, "SAE");
    require(splitAmount < oldAmount, "SAE");

    IMortgageNFT(mortgageNFT).remove(nftTokenId, splitAmount);
    newNFTTokenId = IMortgageNFT(mortgageNFT).mint(msg.sender, tid, splitAmount);

    ethAmount = getETHAmount(oldAmount - splitAmount, splitAmount) - getETHAmount(0, splitAmount);

    require(msg.value >= ethAmount, "VE");

    _refundETH(ethAmount);

    emit Split(nftTokenId, newNFTTokenId, tid, splitAmount, ethAmount, msg.sender);
  }

  function _buyWithoutTransferEth(
    address to,
    string memory tid,
    uint256 tokenAmount
  )
    private
    returns (uint256 ethAmount, uint256[] memory feeTokenIds, address[] memory feeTos, uint256[] memory feeAmounts)
  {
    uint256 eth = getBuyETHAmount(tid, tokenAmount);

    uint256 totalFee;
    (totalFee, feeTokenIds, feeTos, feeAmounts) = _getFee(tid, eth);
    ethAmount = eth + totalFee;

    _totalSupply[tid] += tokenAmount;
    _balanceOf[tid][to] += tokenAmount;
  }

  function _sellWithoutTransferEth(
    address from,
    string memory tid,
    uint256 tokenAmount
  )
    private
    returns (uint256 ethAmount, uint256[] memory feeTokenIds, address[] memory feeTos, uint256[] memory feeAmounts)
  {
    uint256 eth = getSellETHAmount(tid, tokenAmount);

    uint256 totalFee;
    (totalFee, feeTokenIds, feeTos, feeAmounts) = _getFee(tid, eth);
    ethAmount = eth - totalFee;

    _totalSupply[tid] -= tokenAmount;
    _balanceOf[tid][from] -= tokenAmount;
  }

  function _mortgageAdd(
    uint256 tokenId,
    string memory tid,
    uint256 oldAmount,
    uint256 addAmount
  ) private returns (uint256 ethAmount) {
    uint256 eth = getETHAmount(oldAmount, addAmount);
    uint256 feeAmount = _mortgageFee(eth);

    _balanceOf[tid][msg.sender] -= addAmount;
    _balanceOf[tid][address(this)] += addAmount;

    ethAmount = eth - feeAmount;
    _transferEth(msg.sender, ethAmount);
    _transferEthToMortgageFeeRecipient(feeAmount);

    emit Mortgage(tokenId, tid, addAmount, ethAmount, feeAmount, msg.sender);
  }

  function _multiplyAdd(
    uint256 nftTokenId,
    string memory tid,
    uint256 oldAmount,
    uint256 multiplyAmount
  ) private returns (uint256 ethAmount) {
    (
      uint256 ethMultiplyAmount,
      uint256[] memory feeTokenIds,
      address[] memory feeTos,
      uint256[] memory feeAmounts
    ) = _buyWithoutTransferEth(address(this), tid, multiplyAmount);

    uint256 eth = getETHAmount(oldAmount, multiplyAmount);
    uint256 feeAmount = _mortgageFee(eth);
    uint256 ethMortAmount = eth - feeAmount;
    ethAmount = ethMultiplyAmount - ethMortAmount;

    require(msg.value >= ethAmount, "VE");

    _transferEthToMortgageFeeRecipient(feeAmount);
    _batchTransferEthToNFTOwners(feeTokenIds, feeTos, feeAmounts);
    _refundETH(ethAmount);

    emit Multiply(nftTokenId, tid, multiplyAmount, ethAmount, feeAmount, msg.sender, feeTokenIds, feeTos, feeAmounts);
  }

  function _getFee(
    string memory tid,
    uint256 eth
  )
    private
    view
    returns (uint256 totalFee, uint256[] memory tokenIds, address[] memory owners, uint256[] memory percentEths)
  {
    uint256[] memory percents;
    (tokenIds, percents, , owners) = IPublicNFT(publicNFT).tidToInfos(tid);

    percentEths = new uint256[](percents.length);

    for (uint256 i = 0; i < percents.length; i++) {
      uint256 feeAmount = (eth * buySellFee * percents[i]) / totalPercent / feeDenominator;
      percentEths[i] = feeAmount;
      totalFee += feeAmount;
    }
  }

  function _batchTransferEthToNFTOwners(
    uint256[] memory tokenIds,
    address[] memory tos,
    uint256[] memory amounts
  ) private {
    for (uint256 i = 0; i < amounts.length; i++) {
      if (tos[i].code.length > 0) {
        _transferEthWithData(tokenIds[i], tos[i], amounts[i]);
      } else {
        _transferEth(tos[i], amounts[i]);
      }
    }
  }

  function _transferEthToMortgageFeeRecipient(uint256 feeAmount) private {
    _transferEth(IFoundry(foundry).mortgageFeeRecipient(appId), feeAmount);
  }

  function _refundETH(uint256 needPay) private {
    uint256 refund = msg.value - needPay;
    if (refund > 0) {
      _transferEth(msg.sender, refund);
    }
  }

  function _transferEth(address to, uint256 value) private {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "TEE");
  }

  function _transferEthWithData(uint256 tokenId, address to, uint256 value) private {
    (bool success, ) = to.call{value: value}(abi.encode("buySellFee", tokenId));
    require(success, "TEE");
  }

  function _mortgageFee(uint256 _eth) private view returns (uint256) {
    return (IFoundry(foundry).mortgageFee(appId) * _eth) / feeDenominator;
  }
}