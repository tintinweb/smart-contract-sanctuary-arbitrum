// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/IIntellSetting.sol";
import "./lib/Context.sol";
import "./lib/Ownable.sol";

pragma experimental ABIEncoderV2;

contract IntellSetting is Ownable, IIntellSetting {
    address private _admin = 0xFfA83cc91eE78c4D46A50eaa5267040A827A7682;
    address private _truthHolder = 0xF8AbE936Ff2bCc9774Db7912554c4f38368e05A2;
    address private _intellTokenAddr;
    address private _factoryContractAddr;
    address private _creatorNFTContractAddr;
    uint256 private _creatorNFTMintPrice;
    uint256 private _shareNFTLaunchPrice;
    uint256 private _commissionForCreator;
    uint256 private _commissionForCreatorAndInvestor;

    constructor() {
        _creatorNFTMintPrice = 10000 * 10 ** 18;
        _shareNFTLaunchPrice = 10000 * 10 ** 18;
    }
    

    function commissionForCreatorAndInvestor() external view override returns(uint256) {
        return _commissionForCreatorAndInvestor;
    }

    function setCommissionForCreatorAndInvestor(uint256 _newCommission) external onlyOwner {
        _commissionForCreatorAndInvestor = _newCommission;
    }

    function commissionForCreator() external view override returns(uint256) {
        return _commissionForCreator;
    }

    function setCommissionForCreator(uint256 _newCommission) external onlyOwner {
        _commissionForCreator = _newCommission;
    }

    function truthHolder() external view override returns(address) {
        return _truthHolder;
    }

    function setTruthHolder(address _newTruthHolder) external onlyOwner {
        _truthHolder = _newTruthHolder;
    }

    function creatorNFTMintPrice() external view override returns(uint256) {
        return _creatorNFTMintPrice;
    }

    function setCreatorNFTMintPrice(uint256 _newMintPrice) external onlyOwner {
        _creatorNFTMintPrice = _newMintPrice;
    }

    function shareNFTLaunchPrice() external view override returns(uint256) {
        return _shareNFTLaunchPrice;
    }

    function setShareNFTLaunchPrice(uint256 _newLaunchPrice) external onlyOwner {
        _shareNFTLaunchPrice = _newLaunchPrice;
    }

    function admin() external view override returns(address) {
        return _admin;
    }

    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
    }

    function intellTokenAddr() external view override returns(address) {
        return _intellTokenAddr;
    }

    function setIntellTokenAddr(address newIntellTokenAddr) external onlyOwner {
        _intellTokenAddr = newIntellTokenAddr;
    }

    function factoryContractAddr() external view override returns(address) {
        return _factoryContractAddr;
    }

    function setFactoryContractAddr(address newFactoryContractAddr) external onlyOwner {
        _factoryContractAddr = newFactoryContractAddr;
    }

    function creatorNFTContractAddr() external view override returns(address) {
        return _creatorNFTContractAddr;
    }

    function setCreatorNFTContractAddr(address newCreatorContractAddr) external onlyOwner {
        _creatorNFTContractAddr = newCreatorContractAddr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAuthorized() {
        require(owner() == msg.sender);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIntellSetting {
    function admin() external view returns(address);
    function truthHolder() external view returns(address);
    function creatorNFTMintPrice() external view returns(uint256);
    function shareNFTLaunchPrice() external view returns(uint256);
    function intellTokenAddr() external view returns(address);
    function factoryContractAddr() external view returns(address);
    function creatorNFTContractAddr() external view returns(address);
    function commissionForCreator() external view returns(uint256);
    function commissionForCreatorAndInvestor() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}