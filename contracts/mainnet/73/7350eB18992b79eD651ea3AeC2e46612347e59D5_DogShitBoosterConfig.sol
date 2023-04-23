/**
 *Submitted for verification at Arbiscan on 2023-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC165Upgradeable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Upgradeable is IERC165Upgradeable {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma experimental ABIEncoderV2;

interface IDogShitBoosterConfig {
  // getter

  function energyInfo(address nftAddress, uint256 nftTokenId)
    external
    view
    returns (
      uint256 maxEnergy,
      uint256 currentEnergy,
      uint256 boostBps
    );

  function dogshitboosterNftAllowance(
    address stakingToken,
    address nftAddress,
    uint256 nftTokenId
  ) external view returns (bool);

  function stakeTokenAllowance(address stakingToken) external view returns (bool);

  function callerAllowance(address caller) external view returns (bool);

  // external

  function consumeEnergy(
    address nftAddress,
    uint256 nftTokenId,
    uint256 energyToBeConsumed
  ) external;
}

interface IDogeShitNFT is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
  // getter

  function dogshitNames(uint256 tokenId) external view returns (string calldata);

  function categoryInfo(uint256 tokenId)
    external
    view
    returns (
      string calldata,
      string calldata,
      uint256
    );

  function dogeshitNFTToCategory(uint256 tokenId) external view returns (uint256);

  function categoryToDogeShitNFTList(uint256 categoryId) external view returns (uint256[] memory);

  function currentTokenId() external view returns (uint256);

  function currentCategoryId() external view returns (uint256);

  function categoryURI(uint256 categoryId) external view returns (string memory);

  function getDogShitNameOfTokenId(uint256 tokenId) external view returns (string memory);

  // setter
  function mint(address _to, uint256 _categoryId) external returns (uint256);

  function mintBatch(
    address _to,
    uint256 _categoryId,
    uint256 _size
  ) external returns (uint256[] memory);
}

contract DogShitBoosterConfig is IDogShitBoosterConfig, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  struct DogShitBoosterNFTInfo {
    address nftAddress;
    uint256 tokenId;
  }

  struct DogShitBoosterEnergyInfo {
    uint256 maxEnergy;
    uint256 currentEnergy;
    uint256 boostBps;
    uint256 updatedAt;
  }

  struct CategoryEnergyInfo {
    uint256 maxEnergy;
    uint256 boostBps;
    uint256 updatedAt;
  }

  struct DogShitBoosterNFTParams {
    address nftAddress;
    uint256 nftTokenId;
    uint256 maxEnergy;
    uint256 boostBps;
  }

  struct CategoryNFTParams {
    address nftAddress;
    uint256 nftCategoryId;
    uint256 maxEnergy;
    uint256 boostBps;
  }

  struct DogShitBoosterAllowance {
    address nftAddress;
    uint256 nftTokenId;
    bool allowance;
  }

  struct DogShitBoosterAllowanceParams {
    address stakingToken;
    DogShitBoosterAllowance[] allowance;
  }

  struct CategoryAllowance {
    address nftAddress;
    uint256 nftCategoryId;
    bool allowance;
  }

  struct CategoryAllowanceParams {
    address stakingToken;
    CategoryAllowance[] allowance;
  }

  mapping(address => mapping(uint256 => DogShitBoosterEnergyInfo)) public dogshitboosterEnergyInfo;
  mapping(address => CategoryEnergyInfo) public externalboosterEnergyInfo;
  mapping(address => mapping(uint256 => CategoryEnergyInfo)) public categoryEnergyInfo;

  mapping(address => mapping(address => mapping(uint256 => bool))) public dogshitboosterNftAllowanceConfig;
  mapping(address => mapping(address => mapping(uint256 => bool))) public categoryNftAllowanceConfig;

  mapping(address => bool) public override stakeTokenAllowance;

  mapping(address => bool) public override callerAllowance;

  event UpdateCurrentEnergy(
    address indexed nftAddress,
    uint256 indexed nftTokenId,
    uint256 indexed updatedCurrentEnergy
  );
  event SetStakeTokenAllowance(address indexed stakingToken, bool isAllowed);
  event SetDogShitBoosterNFTEnergyInfo(
    address indexed nftAddress,
    uint256 indexed nftTokenId,
    uint256 maxEnergy,
    uint256 currentEnergy,
    uint256 boostBps
  );
  event SetExternalBoosterNFTEnergyInfo(address indexed nftAddress, uint256 maxEnergy, uint256 boostBps);
  event SetCallerAllowance(address indexed caller, bool isAllowed);
  event SetDogShitBoosterNFTAllowance(
    address indexed stakeToken,
    address indexed nftAddress,
    uint256 indexed nftTokenId,
    bool isAllowed
  );
  event SetCategoryNFTEnergyInfo(
    address indexed nftAddress,
    uint256 indexed nftCategoryId,
    uint256 maxEnergy,
    uint256 boostBps
  );
  event SetCategoryNFTAllowance(
    address indexed stakeToken,
    address indexed nftAddress,
    uint256 indexed nftCategoryId,
    bool isAllowed
  );

  /// @notice only eligible caller can continue the execution
  modifier onlyCaller() {
    require(callerAllowance[msg.sender], "DogShitBoosterConfig::onlyCaller::only eligible caller");
    _;
  }

  /// @notice getter function for energy info
  /// @dev check if the dogshitbooster energy existed,
  /// if not, it should be non-preminted version, so use categoryEnergyInfo to get a current, maxEnergy instead
  function energyInfo(address _nftAddress, uint256 _nftTokenId)
    public
    view
    override
    returns (
      uint256 maxEnergy,
      uint256 currentEnergy,
      uint256 boostBps
    )
  {
    CategoryEnergyInfo memory externalboosterInfo = externalboosterEnergyInfo[_nftAddress];

    // if there is no preset dogshitbooster energy info, use preset in category info
    // presume that it's not a preminted nft
    if (externalboosterInfo.updatedAt != 0) {
      return (externalboosterInfo.maxEnergy, externalboosterInfo.maxEnergy, externalboosterInfo.boostBps);
    }
    DogShitBoosterEnergyInfo memory dogshitboosterInfo = dogshitboosterEnergyInfo[_nftAddress][_nftTokenId];
    // if there is no preset dogshitbooster energy info, use preset in category info
    // presume that it's not a preminted nft
    if (dogshitboosterInfo.updatedAt == 0) {
      uint256 categoryId = IDogeShitNFT(_nftAddress).dogeshitNFTToCategory(_nftTokenId);
      CategoryEnergyInfo memory categoryInfo = categoryEnergyInfo[_nftAddress][categoryId];
      return (categoryInfo.maxEnergy, categoryInfo.maxEnergy, categoryInfo.boostBps);
    }
    // if there is an updatedAt, it's a preminted nft
    return (dogshitboosterInfo.maxEnergy, dogshitboosterInfo.currentEnergy, dogshitboosterInfo.boostBps);
  }

  /// @notice function for updating a curreny energy of the specified nft
  /// @dev Only eligible caller can freely update an energy
  /// @param _nftAddress a composite key for nft
  /// @param _nftTokenId a composite key for nft
  /// @param _energyToBeConsumed an energy to be consumed
  function consumeEnergy(
    address _nftAddress,
    uint256 _nftTokenId,
    uint256 _energyToBeConsumed
  ) external override onlyCaller {
    require(_nftAddress != address(0), "DogShitBoosterConfig::consumeEnergy::_nftAddress must not be address(0)");
    DogShitBoosterEnergyInfo storage energy = dogshitboosterEnergyInfo[_nftAddress][_nftTokenId];

    if (energy.updatedAt == 0) {
      uint256 categoryId = IDogeShitNFT(_nftAddress).dogeshitNFTToCategory(_nftTokenId);
      CategoryEnergyInfo memory categoryEnergy = categoryEnergyInfo[_nftAddress][categoryId];
      require(categoryEnergy.updatedAt != 0, "DogShitBoosterConfig::consumeEnergy:: invalid nft to be updated");
      energy.maxEnergy = categoryEnergy.maxEnergy;
      energy.boostBps = categoryEnergy.boostBps;
      energy.currentEnergy = categoryEnergy.maxEnergy;
    }

    energy.currentEnergy = energy.currentEnergy.sub(_energyToBeConsumed);
    energy.updatedAt = block.timestamp;

    emit UpdateCurrentEnergy(_nftAddress, _nftTokenId, energy.currentEnergy);
  }

  /// @notice set external nft energy info
  /// @dev only owner can call this function
  /// @param _param a DogShitBoosterNFTParams {nftAddress, nftTokenId, maxEnergy, boostBps}

  function setExternalTokenEnergyInfo(address _externalNft, CategoryEnergyInfo calldata _param) external onlyOwner {
    require(_externalNft != address(0), "DogShitBoosterConfig::externalNft::_externalNft must not be address(0)");
    externalboosterEnergyInfo[_externalNft] = CategoryEnergyInfo({
      maxEnergy: _param.maxEnergy,
      boostBps: _param.boostBps,
      updatedAt: block.timestamp
    });

    emit SetExternalBoosterNFTEnergyInfo(_externalNft, _param.maxEnergy, _param.boostBps);
  }

  /// @notice set stake token allowance
  /// @dev only owner can call this function
  /// @param _stakeToken a specified token
  /// @param _isAllowed a flag indicating the allowance of a specified token
  function setStakeTokenAllowance(address _stakeToken, bool _isAllowed) external onlyOwner {
    require(_stakeToken != address(0), "DogShitBoosterConfig::setStakeTokenAllowance::_stakeToken must not be address(0)");
    stakeTokenAllowance[_stakeToken] = _isAllowed;

    emit SetStakeTokenAllowance(_stakeToken, _isAllowed);
  }

  /// @notice set caller allowance - only eligible caller can call a function
  /// @dev only eligible callers can call this function
  /// @param _caller a specified caller
  /// @param _isAllowed a flag indicating the allowance of a specified token
  function setCallerAllowance(address _caller, bool _isAllowed) external onlyOwner {
    require(_caller != address(0), "DogShitBoosterConfig::setCallerAllowance::_caller must not be address(0)");
    callerAllowance[_caller] = _isAllowed;

    emit SetCallerAllowance(_caller, _isAllowed);
  }

  /// @notice A function for setting dogshitbooster NFT energy info as a batch
  /// @param _params a list of DogShitBoosterNFTParams [{nftAddress, nftTokenId, maxEnergy, boostBps}]
  function setBatchDogShitBoosterNFTEnergyInfo(DogShitBoosterNFTParams[] calldata _params) external onlyOwner {
    for (uint256 i = 0; i < _params.length; ++i) {
      _setDogShitBoosterNFTEnergyInfo(_params[i]);
    }
  }

  /// @notice A function for setting dogshitbooster NFT energy info
  /// @param _param a DogShitBoosterNFTParams {nftAddress, nftTokenId, maxEnergy, boostBps}
  function setDogShitBoosterNFTEnergyInfo(DogShitBoosterNFTParams calldata _param) external onlyOwner {
    _setDogShitBoosterNFTEnergyInfo(_param);
  }

  /// @dev An internal function for setting dogshitbooster NFT energy info
  /// @param _param a DogShitBoosterNFTParams {nftAddress, nftTokenId, maxEnergy, boostBps}
  function _setDogShitBoosterNFTEnergyInfo(DogShitBoosterNFTParams calldata _param) internal {
    dogshitboosterEnergyInfo[_param.nftAddress][_param.nftTokenId] = DogShitBoosterEnergyInfo({
      maxEnergy: _param.maxEnergy,
      currentEnergy: _param.maxEnergy,
      boostBps: _param.boostBps,
      updatedAt: block.timestamp
    });

    emit SetDogShitBoosterNFTEnergyInfo(
      _param.nftAddress,
      _param.nftTokenId,
      _param.maxEnergy,
      _param.maxEnergy,
      _param.boostBps
    );
  }

  /// @notice A function for setting category NFT energy info as a batch, used for nft with non-preminted
  /// @param _params a list of CategoryNFTParams [{nftAddress, nftTokenId, maxEnergy, boostBps}]
  function setBatchCategoryNFTEnergyInfo(CategoryNFTParams[] calldata _params) external onlyOwner {
    for (uint256 i = 0; i < _params.length; ++i) {
      _setCategoryNFTEnergyInfo(_params[i]);
    }
  }

  /// @notice A function for setting category NFT energy info, used for nft with non-preminted
  /// @param _param a CategoryNFTParams {nftAddress, nftTokenId, maxEnergy, boostBps}
  function setCategoryNFTEnergyInfo(CategoryNFTParams calldata _param) external onlyOwner {
    _setCategoryNFTEnergyInfo(_param);
  }

  /// @dev An internal function for setting category NFT energy info, used for nft with non-preminted
  /// @param _param a CategoryNFTParams {nftAddress, nftCategoryId, maxEnergy, boostBps}
  function _setCategoryNFTEnergyInfo(CategoryNFTParams calldata _param) internal {
    categoryEnergyInfo[_param.nftAddress][_param.nftCategoryId] = CategoryEnergyInfo({
      maxEnergy: _param.maxEnergy,
      boostBps: _param.boostBps,
      updatedAt: block.timestamp
    });

    emit SetCategoryNFTEnergyInfo(_param.nftAddress, _param.nftCategoryId, _param.maxEnergy, _param.boostBps);
  }

  /// @dev A function setting if a particular stake token should allow a specified nft category to be boosted (used with non-preminted nft)
  /// @param _param a CategoryAllowanceParams {stakingToken, [{nftAddress, nftCategoryId, allowance;}]}
  function setStakingTokenCategoryAllowance(CategoryAllowanceParams calldata _param) external onlyOwner {
    for (uint256 i = 0; i < _param.allowance.length; ++i) {
      require(
        stakeTokenAllowance[_param.stakingToken],
        "DogShitBoosterConfig::setStakingTokenCategoryAllowance:: bad staking token"
      );
      categoryNftAllowanceConfig[_param.stakingToken][_param.allowance[i].nftAddress][
        _param.allowance[i].nftCategoryId
      ] = _param.allowance[i].allowance;

      emit SetCategoryNFTAllowance(
        _param.stakingToken,
        _param.allowance[i].nftAddress,
        _param.allowance[i].nftCategoryId,
        _param.allowance[i].allowance
      );
    }
  }

  /// @dev A function setting if a particular stake token should allow a specified nft to be boosted
  /// @param _param a DogShitBoosterAllowanceParams {stakingToken, [{nftAddress, nftTokenId,allowance;}]}
  function setStakingTokenDogShitBoosterAllowance(DogShitBoosterAllowanceParams calldata _param) external onlyOwner {
    for (uint256 i = 0; i < _param.allowance.length; ++i) {
      require(
        stakeTokenAllowance[_param.stakingToken],
        "DogShitBoosterConfig::setStakingTokenDogShitBoosterAllowance:: bad staking token"
      );
      dogshitboosterNftAllowanceConfig[_param.stakingToken][_param.allowance[i].nftAddress][
        _param.allowance[i].nftTokenId
      ] = _param.allowance[i].allowance;

      emit SetDogShitBoosterNFTAllowance(
        _param.stakingToken,
        _param.allowance[i].nftAddress,
        _param.allowance[i].nftTokenId,
        _param.allowance[i].allowance
      );
    }
  }

  /// @notice use for checking whether or not this nft supports an input stakeToken
  /// @dev if not support when checking with token, need to try checking with category level (categoryNftAllowanceConfig) as well since there should not be dogshitboosterNftAllowanceConfig in non-preminted nft
  function dogshitboosterNftAllowance(
    address _stakeToken,
    address _nftAddress,
    uint256 _nftTokenId
  ) external view override returns (bool) {
    if (!dogshitboosterNftAllowanceConfig[_stakeToken][_nftAddress][_nftTokenId]) {
      CategoryEnergyInfo memory externalboosterInfo = externalboosterEnergyInfo[_nftAddress];

      if (externalboosterInfo.updatedAt != 0) {
        return categoryNftAllowanceConfig[_stakeToken][_nftAddress][0];
      }

      uint256 categoryId = IDogeShitNFT(_nftAddress).dogeshitNFTToCategory(_nftTokenId);
      return categoryNftAllowanceConfig[_stakeToken][_nftAddress][categoryId];
    }
    return true;
  }
}